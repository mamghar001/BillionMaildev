#!/bin/bash
# One-Command Install for BillionMail MoeScale V5.0.0 (with Noez GRE Tunnel Support)
# Usage: bash <(curl -sSL https://raw.githubusercontent.com/mamghar001/MoeScale-BillionMail/v4.9.0/one-command-install.sh)
# Or: sudo bash one-command-install.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BILLIONMAIL_DIR="/opt/billionmail"
REPO_URL="https://github.com/mamghar001/MoeScale-BillionMail.git"
BRANCH="${BRANCH:-main}"  # Default to main, allow override via env var

# Logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        error "This script must be run as root"
        exit 1
    fi
    success "Running as root"
}

# Check OS
check_os() {
    log "Checking operating system..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
    else
        error "Cannot detect OS"
        exit 1
    fi
    
    case $OS in
        "Ubuntu")
            if [ "$VERSION" != "20.04" ] && [ "$VERSION" != "22.04" ] && [ "$VERSION" != "24.04" ]; then
                warning "Ubuntu $VERSION not tested. Recommended: 20.04 or 22.04"
            fi
            ;;
        "Debian GNU/Linux")
            warning "Debian detected. Ubuntu recommended."
            ;;
        *)
            error "OS $OS not supported. Use Ubuntu 20.04 or 22.04"
            exit 1
            ;;
    esac
    success "OS check passed: $OS $VERSION"
}

# Check and install dependencies
install_dependencies() {
    log "Installing dependencies..."
    
    # Fix any broken dependencies first
    log "Checking for broken dependencies..."
    apt --fix-broken install -y 2>/dev/null || true
    
    # Wait for apt lock to be released (fresh VPSes may be running cloud-init updates)
    log "Waiting for package manager (this may take 2-3 minutes on fresh VPS)..."
    LOCK_HELD=0
    for i in {1..180}; do  # Wait up to 3 minutes
        if ! lsof /var/lib/dpkg/lock-frontend >/dev/null 2>&1 && \
           ! lsof /var/lib/apt/lists/lock >/dev/null 2>&1 && \
           ! pgrep -x "apt-get" >/dev/null 2>&1; then
            LOCK_HELD=0
            break
        fi
        LOCK_HELD=1
        
        # Show progress every 10 seconds
        if [ $((i % 10)) -eq 0 ]; then
            log "Still waiting... ($((i/10))/18)"
            # Show what process is holding the lock
            lsof /var/lib/dpkg/lock-frontend 2>/dev/null | tail -1 | awk '{print "  Lock held by:", $1, "(PID", $2")"}' || true
        fi
        sleep 1
    done
    
    # If lock still held after 3 minutes, ask user or force kill
    if [ "$LOCK_HELD" -eq 1 ]; then
        warning "Package manager is still locked after 3 minutes"
        warning "This is normal for fresh VPS cloud-init updates"
        
        read -p "Force kill apt processes and continue? (yes/no) [yes]: " FORCE_KILL
        FORCE_KILL=${FORCE_KILL:-yes}
        
        if [[ "$FORCE_KILL" == "yes" || "$FORCE_KILL" == "y" ]]; then
            log "Killing stale apt processes..."
            pkill -9 apt-get 2>/dev/null || true
            pkill -9 dpkg 2>/dev/null || true
            sleep 2
        else
            error "Cannot proceed while package manager is locked. Please wait and try again."
            exit 1
        fi
    fi
    
    # Clean up any stale locks
    rm -f /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock /var/cache/apt/archives/lock 2>/dev/null || true
    dpkg --configure -a 2>/dev/null || true
    
    apt-get update -qq
    
    # Essential packages
    PACKAGES="curl wget git jq net-tools dnsutils"
    
    # Docker check
    if ! command -v docker &> /dev/null; then
        log "Installing Docker..."
        curl -fsSL https://get.docker.com | sh
        systemctl enable docker
        systemctl start docker
        success "Docker installed"
    else
        success "Docker already installed"
    fi
    
    # Docker Compose check
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log "Installing Docker Compose..."
        apt-get install -y docker-compose-plugin
        success "Docker Compose installed"
    else
        success "Docker Compose already installed"
    fi
    
    apt-get install -y $PACKAGES -qq
    success "Dependencies installed"
}

# Get user input
gather_info() {
    log "Gathering configuration information..."
    echo ""
    echo "==================================="
    echo "BillionMail Configuration"
    echo "==================================="
    echo ""
    
    # Main domain
    read -p "Enter your main domain (e.g., b2bscale.xyz): " MAIN_DOMAIN
    if [ -z "$MAIN_DOMAIN" ]; then
        error "Domain is required"
        exit 1
    fi
    
    # Admin credentials
    read -p "Enter admin username [admin]: " ADMIN_USER
    ADMIN_USER=${ADMIN_USER:-admin}
    
    read -s -p "Enter admin password: " ADMIN_PASS
    echo ""
    if [ -z "$ADMIN_PASS" ]; then
        ADMIN_PASS=$(openssl rand -base64 12)
        warning "Generated random password: $ADMIN_PASS"
    fi
    
    # Safe path
    read -p "Enter admin panel path [admin888]: " SAFE_PATH
    SAFE_PATH=${SAFE_PATH:-admin888}
    
    # IPs
    log "Detecting server IP..."
    PRIMARY_IP=$(curl -s4 ifconfig.me || curl -s4 icanhazip.com || hostname -I | awk '{print $1}')
    read -p "Enter primary server IP [$PRIMARY_IP]: " VPS_IP
    VPS_IP=${VPS_IP:-$PRIMARY_IP}
    
    read -p "Enter additional IPs (comma-separated, or press Enter for none): " EXTRA_IPS
    
    # SMTP Relay option
    echo ""
    echo "==================================="
    echo "For reliable Gmail/Hotmail delivery, SMTP relay is recommended."
    echo "Options: SendGrid (free 100/day), Amazon SES, Mailgun"
    echo ""
    read -p "Set up SMTP relay now? (yes/no) [no]: " SETUP_RELAY
    SETUP_RELAY=${SETUP_RELAY:-no}
    
    if [[ "$SETUP_RELAY" == "yes" || "$SETUP_RELAY" == "y" ]]; then
        echo "Select relay provider:"
        echo "1) SendGrid (free 100/day)"
        echo "2) Amazon SES"
        echo "3) Mailgun"
        echo "4) Other"
        read -p "Choice [1]: " RELAY_CHOICE
        RELAY_CHOICE=${RELAY_CHOICE:-1}
        
        case $RELAY_CHOICE in
            1) RELAY_HOST="smtp.sendgrid.net"; RELAY_PORT="587" ;;
            2) RELAY_HOST="email-smtp.us-east-1.amazonaws.com"; RELAY_PORT="587" ;;
            3) RELAY_HOST="smtp.mailgun.org"; RELAY_PORT="587" ;;
            4) 
                read -p "Enter SMTP host: " RELAY_HOST
                read -p "Enter SMTP port [587]: " RELAY_PORT
                RELAY_PORT=${RELAY_PORT:-587}
                ;;
        esac
        
        read -p "Enter SMTP username: " RELAY_USER
        read -s -p "Enter SMTP password: " RELAY_PASS
        echo ""
    fi
    
    # Noez GRE Tunnel option
    echo ""
    echo "==================================="
    echo "Noez GRE Tunnel Setup (Optional)"
    echo "For sending from dedicated Noez IP addresses via GRE tunnel."
    echo "Requires: Noez account with GRE tunnel service"
    echo ""
    read -p "Set up Noez GRE Tunnel now? (yes/no) [no]: " SETUP_NOEZ
    SETUP_NOEZ=${SETUP_NOEZ:-no}
    
    if [[ "$SETUP_NOEZ" == "yes" || "$SETUP_NOEZ" == "y" ]]; then
        echo ""
        echo "Enter Noez configuration:"
        read -p "Noez IP address (e.g., 5.230.168.0): " NOEZ_IP
        read -p "Noez GRE endpoint (from Noez panel, e.g., 5.230.205.35): " NOEZ_GRE_REMOTE
        read -p "Cloudflare API token (optional, for auto-DNS): " CF_API_TOKEN
        CF_API_TOKEN=${CF_API_TOKEN:-}
    fi
    
    # Load existing passwords if .env exists to prevent "split-brain" password mismatch on re-installs
    if [ -f "$BILLIONMAIL_DIR/.env" ]; then
        log "Loading existing passwords from .env..."
        # Extract DBPASS and REDISPASS without sourcing the whole file (safer for shell)
        EXT_DBPASS=$(grep '^DBPASS=' "$BILLIONMAIL_DIR/.env" | cut -d'=' -f2)
        EXT_REDISPASS=$(grep '^REDISPASS=' "$BILLIONMAIL_DIR/.env" | cut -d'=' -f2)
        [ -n "$EXT_DBPASS" ] && DBPASS="$EXT_DBPASS"
        [ -n "$EXT_REDISPASS" ] && REDISPASS="$EXT_REDISPASS"
    fi

    # Generate secure passwords ONLY if they aren't already set/loaded
    # Note: Base64 passwords with == padding break DockerEnv which splits on =
    [ -z "$DBPASS" ] && DBPASS=$(LC_ALL=C </dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c 32)
    [ -z "$REDISPASS" ] && REDISPASS=$(LC_ALL=C </dev/urandom tr -dc A-Za-z0-9 2>/dev/null | head -c 32)
    
    # EXPORT for install.sh inheritance
    export DBPASS REDISPASS
    
    success "Configuration gathered"
}

# Setup server IPs
setup_ips() {
    log "Setting up IP addresses..."
    
    # Detect network interface
    INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    success "Network interface: $INTERFACE"
    
    # Get subnet from primary IP (usually /24)
    SUBNET=$(ip addr show dev $INTERFACE | grep "$VPS_IP" | awk '{print $2}' | cut -d'/' -f2 | head -1)
    SUBNET=${SUBNET:-24}
    
    # Add primary IP if not already set
    if ! ip addr show dev $INTERFACE | grep -q "$VPS_IP"; then
        warning "Primary IP $VPS_IP not found on interface"
        warning "Make sure your VPS has this IP assigned"
    fi
    
    # Add extra IPs temporarily
    declare -a IP_LIST
    if [ -n "$EXTRA_IPS" ]; then
        IFS=',' read -ra IPS <<< "$EXTRA_IPS"
        for ip in "${IPS[@]}"; do
            ip=$(echo $ip | xargs) # trim whitespace
            IP_LIST+=("$ip")
            if ! ip addr show dev $INTERFACE | grep -q "$ip"; then
                log "Adding IP $ip to $INTERFACE (temporary)"
                ip addr add $ip/32 dev $INTERFACE 2>/dev/null || warning "Failed to add $ip (may need manual setup)"
            else
                success "IP $ip already configured"
            fi
        done
    fi
    
    # Make IPs persistent via netplan
    make_ips_persistent "$INTERFACE" "$VPS_IP" "$SUBNET" "${IP_LIST[@]}"
}

# Make IPs persistent in netplan
make_ips_persistent() {
    local INTERFACE=$1
    local PRIMARY_IP=$2
    local SUBNET=$3
    shift 3
    local EXTRA_IPS_LIST=("$@")
    
    NETPLAN_FILE="/etc/netplan/50-cloud-init.yaml"
    NETPLAN_BACKUP="/etc/netplan/50-cloud-init.yaml.bak.$(date +%Y%m%d_%H%M%S)"
    
    if [ ! -f "$NETPLAN_FILE" ]; then
        warning "Netplan config not found at $NETPLAN_FILE"
        warning "IP configuration will not persist after reboot"
        return
    fi
    
    log "Making IPs persistent in netplan..."
    
    # Backup original
    cp "$NETPLAN_FILE" "$NETPLAN_BACKUP"
    
    # Create Python script to safely modify YAML
    cat > /tmp/update_netplan.py << 'PYEOF'
import sys
import yaml
import re

def update_netplan(file_path, interface, primary_ip, subnet, extra_ips):
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Load YAML
    try:
        config = yaml.safe_load(content)
    except yaml.YAMLError as e:
        print(f"Error parsing YAML: {e}")
        return False
    
    if not config or 'network' not in config:
        print("Invalid netplan config structure")
        return False
    
    network = config['network']
    
    # Find the interface configuration
    if 'ethernets' in network:
        ethernets = network['ethernets']
        
        # Check if interface exists or use first ethernet
        if interface in ethernets:
            iface_config = ethernets[interface]
        else:
            # Try to find matching interface
            iface_config = None
            for iface, cfg in ethernets.items():
                if cfg.get('dhcp4', False) == False or 'addresses' in cfg:
                    iface_config = cfg
                    interface = iface
                    break
            
            if iface_config is None:
                # Use first interface
                for iface, cfg in ethernets.items():
                    iface_config = cfg
                    interface = iface
                    break
        
        if iface_config:
            # Build addresses list
            addresses = [f"{primary_ip}/{subnet}"]
            for ip in extra_ips:
                if ip and ip != primary_ip:
                    addresses.append(f"{ip}/32")
            
            # Update config
            iface_config['dhcp4'] = False
            iface_config['addresses'] = addresses
            
            # Add routes if not present (for default gateway)
            if 'routes' not in iface_config:
                # Get default gateway
                import subprocess
                try:
                    result = subprocess.run(['ip', 'route', 'show', 'default'], 
                                          capture_output=True, text=True)
                    if result.returncode == 0:
                        gateway = None
                        for line in result.stdout.split('\n'):
                            if 'via' in line:
                                parts = line.split()
                                via_idx = parts.index('via')
                                if via_idx + 1 < len(parts):
                                    gateway = parts[via_idx + 1]
                                    break
                        
                        if gateway:
                            iface_config['routes'] = [
                                {'to': 'default', 'via': gateway}
                            ]
                except:
                    pass
            
            # Add nameservers if not present
            if 'nameservers' not in iface_config:
                iface_config['nameservers'] = {
                    'addresses': ['8.8.8.8', '8.8.4.4']
                }
    
    # Write back
    with open(file_path, 'w') as f:
        yaml.dump(config, f, default_flow_style=False, sort_keys=False)
    
    return True

if __name__ == '__main__':
    if len(sys.argv) < 5:
        print("Usage: update_netplan.py <file> <interface> <primary_ip> <subnet> [extra_ips...]")
        sys.exit(1)
    
    file_path = sys.argv[1]
    interface = sys.argv[2]
    primary_ip = sys.argv[3]
    subnet = sys.argv[4]
    extra_ips = sys.argv[5:] if len(sys.argv) > 5 else []
    
    success = update_netplan(file_path, interface, primary_ip, subnet, extra_ips)
    sys.exit(0 if success else 1)
PYEOF
    
    # Install PyYAML if needed
    if ! python3 -c "import yaml" 2>/dev/null; then
        log "Installing PyYAML..."
        apt-get install -y python3-yaml -qq 2>/dev/null || pip3 install pyyaml -q 2>/dev/null || true
    fi
    
    # Run Python script
    if python3 /tmp/update_netplan.py "$NETPLAN_FILE" "$INTERFACE" "$PRIMARY_IP" "$SUBNET" "${EXTRA_IPS_LIST[@]}"; then
        success "Netplan config updated"
        
        # Validate and apply
        if netplan generate 2>/dev/null; then
            success "Netplan configuration is valid"
            
            # Apply netplan (may disconnect SSH briefly)
            log "Applying netplan configuration..."
            if netplan apply 2>/dev/null; then
                success "Netplan applied successfully"
                success "IPs will persist after reboot"
            else
                warning "Netplan apply had issues, but config is saved"
                warning "Changes will take effect on next boot"
            fi
        else
            warning "Netplan config validation failed, restoring backup"
            cp "$NETPLAN_BACKUP" "$NETPLAN_FILE"
        fi
    else
        warning "Failed to update netplan config automatically"
        warning "IPs added temporarily but will not persist after reboot"
        warning "Manual config: Edit $NETPLAN_FILE and run 'netplan apply'"
    fi
    
    rm -f /tmp/update_netplan.py
}

# Clone repository
clone_repo() {
    log "Cloning BillionMail repository..."
    
    if [ -d "$BILLIONMAIL_DIR" ]; then
        warning "Directory $BILLIONMAIL_DIR exists"
        read -p "Remove and reinstall? (yes/no) [no]: " REINSTALL
        if [[ "$REINSTALL" == "yes" || "$REINSTALL" == "y" ]]; then
            rm -rf $BILLIONMAIL_DIR
        else
            error "Installation cancelled"
            exit 1
        fi
    fi
    
    git clone -b "$BRANCH" "$REPO_URL" "$BILLIONMAIL_DIR"
    cd "$BILLIONMAIL_DIR"
    success "Repository cloned to $BILLIONMAIL_DIR"
}

# Create .env file
create_env() {
    log "Creating environment configuration..."
    
    cat > .env << EOF
# Database
DBUSER=billionmail
DBNAME=billionmail
DBPASS=$DBPASS

# Redis
REDISPASS=$REDISPASS

# Timezone
TZ=UTC

# Hostname
BILLIONMAIL_HOSTNAME=$MAIN_DOMAIN

# Admin credentials
ADMIN_USERNAME=$ADMIN_USER
ADMIN_PASSWORD=$ADMIN_PASS
SafePath=$SAFE_PATH

# Network
IPV4_NETWORK=172.66.1

# Ports
HTTP_PORT=80
HTTPS_PORT=443
SMTP_PORT=25
SMTPS_PORT=465
SUBMISSION_PORT=587
IMAP_PORT=143
IMAPS_PORT=993
POP_PORT=110
POPS_PORT=995
SQL_PORT=25432
REDIS_PORT=26379

# Settings
RETENTION_DAYS=7
FAIL2BAN_INIT=y
IP_WHITELIST_ENABLE=false
EOF

    success ".env file created"
}

# Fix SQL configs with correct password (before install)
fix_sql_configs() {
    log "Configuring SQL connection files..."
    
    # Update all Postfix SQL config files with correct password
    for f in conf/postfix/sql/pgsql_*.cf; do
        if [ -f "$f" ]; then
            sed -i "s/^password = .*/password = $DBPASS/" "$f"
        fi
    done
    
    # Update Dovecot SQL config with correct password
    if [ -f "conf/dovecot/conf.d/dovecot-sql.conf.ext" ]; then
        sed -i "s/^connect = .*/connect = host=pgsql dbname=$DBNAME user=$DBUSER password=$DBPASS/" conf/dovecot/conf.d/dovecot-sql.conf.ext
    fi
    
    # (SSL config override removed as it causes bootloops on fresh servers)
    
    # Update Rspamd Redis config with correct password
    if [ -f "conf/rspamd/local.d/redis.conf" ]; then
        sed -i "s/^servers.*password=.*/servers = \"redis:6379\";\n  password = \"$REDISPASS\";/" conf/rspamd/local.d/redis.conf
    fi
    
    # Fix Postfix main.cf hostname BEFORE containers start
    if [ -f "conf/postfix/main.cf" ]; then
        log "Setting Postfix hostname to $MAIN_DOMAIN..."
        sed -i "s/^myhostname = .*/myhostname = $MAIN_DOMAIN/" conf/postfix/main.cf
        # Also set myorigin for proper domain alignment
        sed -i "s/^#*myorigin = .*/myorigin = $MAIN_DOMAIN/" conf/postfix/main.cf 2>/dev/null || true
    fi
    
    success "SQL configs updated"
}

# Clean up old domain configs from previous installations
cleanup_old_configs() {
    log "Cleaning up old configuration files..."
    
    # Reset DKIM signing config to clean state (domains will be re-added via API)
    if [ -f "conf/rspamd/local.d/dkim_signing.conf" ]; then
        # Keep the header, remove all domain blocks
        head -1 conf/rspamd/local.d/dkim_signing.conf > /tmp/dkim_signing.conf.tmp
        cat >> /tmp/dkim_signing.conf.tmp << 'EOF'

use_esld = false;

domain {
#BT_DOMAIN_DKIM_BEGIN

}
#BT_DOMAIN_DKIM_END
EOF
        mv /tmp/dkim_signing.conf.tmp conf/rspamd/local.d/dkim_signing.conf
    fi
    
    # Clean up old vmail_ssl.map entries
    if [ -f "conf/postfix/conf/vmail_ssl.map" ]; then
        echo -n > conf/postfix/conf/vmail_ssl.map
    fi
    
    success "Old configs cleaned up"
}

# Wait for Postgres to be ready and schema initialized
wait_for_db() {
    log "Waiting for PostgreSQL to be ready and initialized..."
    local MAX_RETRIES=45
    local RETRY_COUNT=0
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        # Check if pg_isready
        if docker exec billionmail-pgsql-billionmail-1 pg_isready -U billionmail -d billionmail >/dev/null 2>&1; then
            # Now check if the mailbox table exists
            if docker exec -e PGPASSWORD=$DBPASS billionmail-pgsql-billionmail-1 psql -U billionmail -d billionmail -c "SELECT 1 FROM mailbox LIMIT 1" >/dev/null 2>&1; then
                success "PostgreSQL is ready and schema initialized"
                return 0
            fi
        fi
        RETRY_COUNT=$((RETRY_COUNT + 1))
        # After 15 tries (30 sec), try to manually push the init.sql if tables are still missing
        if [ $RETRY_COUNT -eq 15 ]; then
            warning "Initialization taking longer than expected. Attempting manual schema push..."
            docker exec -i billionmail-pgsql-billionmail-1 psql -U billionmail -d billionmail < init.sql >/dev/null 2>&1 || true
        fi
        sleep 2
    done
    error "PostgreSQL failed to initialize in time"
    return 1
}

# Thoroughly enforce SQL passwords and hostname across all config files
enforce_sql_passwords() {
    log "Enforcing configuration alignment..."
    # 1. Postfix SQL maps
    if [ -d "conf/postfix/sql" ]; then
        for f in conf/postfix/sql/pgsql_*.cf; do
            if [ -f "$f" ]; then
                sed -i "s/^password = .*/password = $DBPASS/" "$f"
                # Ensure it uses the right host too (some scripts might use 127.0.0.1)
                sed -i "s/^hosts = .*/hosts = pgsql/" "$f"
            fi
        done
    fi
    # 2. Dovecot SQL
    if [ -f "conf/dovecot/conf.d/dovecot-sql.conf.ext" ]; then
        sed -i "s/password=[^ ]*/password=$DBPASS/" conf/dovecot/conf.d/dovecot-sql.conf.ext
        sed -i "s/host=[^ ]*/host=pgsql/" conf/dovecot/conf.d/dovecot-sql.conf.ext
    fi
    # 3. Postfix main.cf (Enforce correct hostname)
    if [ -f "conf/postfix/main.cf" ]; then
        sed -i "s/^myhostname = .*/myhostname = $MAIN_DOMAIN/" conf/postfix/main.cf
    fi
    success "Passwords and hostname synchronized in all configs"
}

# Run install script
run_install() {
    log "Running BillionMail install script..."
    
    # 1. Primary cleanup
    cleanup_old_configs
    
    # 2. Initial SQL setup 
    fix_sql_configs
    
    # Fix Postfix myhostname to match domain (for PTR record alignment)
    log "Configuring Postfix..."
    sed -i "s/^myhostname = .*/myhostname = $MAIN_DOMAIN/" conf/postfix/main.cf 2>/dev/null || true
    
    chmod +x install.sh
    
    # Remove existing config files to avoid overwrite prompts
    rm -f billionmail.conf .env 2>/dev/null || true
    
    # Re-create .env file (install.sh uses it)
    cat > .env << EOF
DBUSER=billionmail
DBNAME=billionmail
DBPASS=$DBPASS
REDISPASS=$REDISPASS
TZ=UTC
BILLIONMAIL_HOSTNAME=$MAIN_DOMAIN
ADMIN_USERNAME=$ADMIN_USER
ADMIN_PASSWORD=$ADMIN_PASS
SafePath=$SAFE_PATH
IPV4_NETWORK=172.66.1
HTTP_PORT=80
HTTPS_PORT=443
SMTP_PORT=25
SMTPS_PORT=465
SUBMISSION_PORT=587
IMAP_PORT=143
IMAPS_PORT=993
POP_PORT=110
POPS_PORT=995
SQL_PORT=25432
REDIS_PORT=26379
RETENTION_DAYS=7
FAIL2BAN_INIT=y
IP_WHITELIST_ENABLE=false
EOF
    
    # Run install in background and show progress
    ./install.sh 2>&1 | tee install.log &
    INSTALL_PID=$!
    
    # Show spinner
    spin='-\|/'
    i=0
    while kill -0 $INSTALL_PID 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r${spin:$i:1} Installing... (this may take 5-10 minutes)"
        sleep .5
    done
    printf "\r"
    
    wait $INSTALL_PID
    if [ $? -eq 0 ]; then
        success "BillionMail core installation finished"
    else
        error "Installation failed. Check install.log"
        exit 1
    fi
    
    success "BillionMail core installation finished"
}

# Setup SMTP relay if requested
setup_smtp_relay() {
    if [[ "$SETUP_RELAY" == "yes" || "$SETUP_RELAY" == "y" ]]; then
        log "Setting up SMTP relay..."
        
        # Create sasl_passwd
        echo "$RELAY_USER:$RELAY_PASS" > conf/postfix/conf/sasl_passwd
        docker exec billionmail-postfix-billionmail-1 postmap /etc/postfix/conf/sasl_passwd 2>/dev/null || true
        
        # Add to database
        docker exec -e PGPASSWORD=$DBPASS billionmail-pgsql-billionmail-1 psql -U billionmail -d billionmail << EOF
INSERT INTO bm_relay_config (remark, rtype, relay_host, relay_port, auth_user, auth_password, active)
VALUES ('SMTP Relay', 'custom', '$RELAY_HOST', $RELAY_PORT, '$RELAY_USER', '$RELAY_PASS', 1)
ON CONFLICT DO NOTHING;
EOF
        
        # Map domains to relay
        docker exec -e PGPASSWORD=$DBPASS billionmail-pgsql-billionmail-1 psql -U billionmail -d billionmail << EOF
INSERT INTO bm_relay_domain_mapping (sender_domain, relay_id)
SELECT domain, 1 FROM domain
ON CONFLICT DO NOTHING;
EOF
        
        # Restart postfix
        docker compose restart postfix-billionmail
        
        success "SMTP relay configured: $RELAY_HOST"
    fi
}

# Setup Noez GRE Tunnel if requested
setup_noez() {
    if [[ "$SETUP_NOEZ" == "yes" || "$SETUP_NOEZ" == "y" ]]; then
        log "Setting up Noez GRE Tunnel..."
        
        if [ ! -f "$BILLIONMAIL_DIR/noez_setup.sh" ]; then
            warning "Noez setup script not found. Skipping Noez setup."
            return
        fi
        
        cd "$BILLIONMAIL_DIR"
        
        # Create noez_setup.env
        cat > noez_setup.env << EOF
# Noez GRE Tunnel Configuration
NOEZ_IP="$NOEZ_IP"
HOST_IP="$VPS_IP"
NOEZ_GRE_REMOTE="$NOEZ_GRE_REMOTE"
DOMAIN="$MAIN_DOMAIN"
ALL_NOEZ_IPS="$NOEZ_IP"
CF_API_TOKEN="$CF_API_TOKEN"
EOF
        
        # Run Noez setup
        log "Running Noez setup..."
        bash noez_setup.sh || warning "Noez setup had some issues. Check logs above."
        
        success "Noez GRE Tunnel configured for IP: $NOEZ_IP"
    fi
}

# Verify installation
verify_install() {
    log "Verifying installation..."
    
    cd "$BILLIONMAIL_DIR"
    
    # Wait for containers to fully start
    log "Waiting for containers to initialize (30 seconds)..."
    sleep 10
    
    # Check containers with better status detection
    log "Checking container status..."
    sleep 5
    
    RUNNING_COUNT=$(docker compose ps --format json 2>/dev/null | grep -c '"State":"running"' || docker compose ps 2>/dev/null | grep -c "Up" || echo "0")
    TOTAL_COUNT=$(docker compose ps --format json 2>/dev/null | grep -c '"Service":' || docker compose ps 2>/dev/null | tail -n +2 | wc -l || echo "0")
    
    if [ "$RUNNING_COUNT" -ge 6 ] || docker compose ps | grep -q "Up"; then
        success "Containers are running ($RUNNING_COUNT/$TOTAL_COUNT)"
        docker compose ps
    else
        warning "Some containers may still be starting..."
        docker compose ps
    fi
    
    # Wait more for core to be ready
    log "Waiting for core service to initialize..."
    sleep 15
    
    # Check if core is responding (JWT fix verification)
    HTTP_PORT=${HTTP_PORT:-80}
    if curl -s http://localhost:$HTTP_PORT/api/health > /dev/null 2>&1 || \
       curl -s http://localhost:$HTTP_PORT/ > /dev/null 2>&1 || \
       curl -sk https://localhost:443/ > /dev/null 2>&1; then
        success "Core web service is responding"
    else
        warning "Core service may still be initializing"
        warning "If you see 'no default jwt secret' errors, they should resolve shortly"
    fi
    
    # Check Postfix config (with retry)
    for i in 1 2 3; do
        MYHOSTNAME=$(docker exec billionmail-postfix-billionmail-1 postconf -h myhostname 2>/dev/null)
        if [ -n "$MYHOSTNAME" ]; then
            break
        fi
        sleep 2
    done
    
    if [ "$MYHOSTNAME" == "$MAIN_DOMAIN" ]; then
        success "Postfix hostname correct: $MYHOSTNAME"
    elif [ -n "$MYHOSTNAME" ]; then
        warning "Postfix hostname is '$MYHOSTNAME' (expected '$MAIN_DOMAIN')"
        warning "Run this to fix: docker exec billionmail-postfix-billionmail-1 postconf -e myhostname=$MAIN_DOMAIN"
    else
        warning "Could not check Postfix hostname (container may still be starting)"
    fi
    
    # Test database connection from Postfix container (with retry)
    for i in 1 2 3; do
        if docker exec -e PGPASSWORD=$DB_PASS billionmail-postfix-billionmail-1 psql -h pgsql -U billionmail -d billionmail -c "SELECT 1;" > /dev/null 2>&1; then
            success "Database connection from Postfix OK"
            DB_OK=1
            break
        fi
        sleep 2
    done
    
    if [ -z "$DB_OK" ]; then
        warning "Database connection from Postfix - may need a moment to initialize"
    fi
    
    # Test database connection
    if docker exec -e PGPASSWORD=$DB_PASS billionmail-pgsql-billionmail-1 psql -U billionmail -d billionmail -c "SELECT 1;" > /dev/null 2>&1; then
        success "Database connection OK"
    else
        warning "Database connection check pending (container initializing)"
    fi
    
    success "Installation verification complete"
    warning "If any services show as pending, wait 1-2 minutes and run: docker compose ps"
}

# Display final info
show_info() {
    echo ""
    echo "==================================="
    echo "✅ BILLIONMAIL INSTALLATION COMPLETE"
    echo "==================================="
    echo ""
    echo "🔗 Access URLs:"
    echo "  HTTPS: https://$VPS_IP/$SAFE_PATH"
    echo "  Domain: https://$MAIN_DOMAIN/$SAFE_PATH (after DNS setup)"
    echo ""
    echo "🔐 Admin Credentials:"
    echo "  Username: $ADMIN_USER"
    echo "  Password: $ADMIN_PASS"
    echo ""
    echo "📁 Installation Directory: $BILLIONMAIL_DIR"
    echo ""
    echo "⚙️  Useful Commands:"
    echo "  cd $BILLIONMAIL_DIR"
    echo "  sudo docker compose ps        # Check status"
    echo "  sudo docker compose logs -f   # View logs"
    echo "  sudo bash bm.sh               # Management menu"
    echo ""
    echo "📧 Testing Email:"
    echo "  echo 'Test' | sendmail -v yourgmail@gmail.com"
    echo ""
    
    if [[ "$SETUP_RELAY" == "yes" || "$SETUP_RELAY" == "y" ]]; then
        echo "✉️  SMTP Relay: $RELAY_HOST"
        echo "   Gmail/Hotmail delivery: ENABLED"
    else
        echo "⚠️  SMTP Relay: NOT CONFIGURED"
        echo "   For Gmail/Hotmail delivery, run:"
        echo "   sudo bash $BILLIONMAIL_DIR/setup_smtp_relay.sh"
    fi
    
    if [[ "$SETUP_NOEZ" == "yes" || "$SETUP_NOEZ" == "y" ]]; then
        echo ""
        echo "🌐 Noez GRE Tunnel: CONFIGURED"
        echo "   IP: $NOEZ_IP"
        echo "   Sending domain: $MAIN_DOMAIN"
        echo "   Test: Send email from admin@$MAIN_DOMAIN"
    fi
    
    echo ""
    echo "📝 NEXT STEPS:"
    echo "1. Set up DNS records (A, MX, SPF, DKIM, DMARC)"
    echo "2. Add domains in BillionMail web UI"
    echo "3. Generate DKIM keys"
    echo "4. Test email delivery"
    
    if [[ "$SETUP_NOEZ" == "yes" || "$SETUP_NOEZ" == "y" ]]; then
        echo ""
        echo "📚 Noez Documentation:"
        echo "   cat $BILLIONMAIL_DIR/NOEZ_SETUP.md"
        echo "   cat $BILLIONMAIL_DIR/SKILLS.md (for AI agents)"
    fi
    
    echo ""
    echo "==================================="
}

# Main execution
main() {
    echo "==================================="
    echo "BillionMail MoeScale V5.0.0"
    echo "One-Command Installer (with Noez Support)"
    echo "==================================="
    echo ""
    
    check_root
    check_os
    install_dependencies
    gather_info
    setup_ips
    clone_repo
    create_env
    run_install
    setup_smtp_relay
    setup_noez
    verify_install
    
    # --- FINAL STABILIZATION SWEEP ---
    log "Performing intermediate configuration alignment..."
    wait_for_db
    sleep 5
    enforce_sql_passwords
    
    log "Final mail service refresh..."
    docker compose restart postfix-billionmail dovecot-billionmail >/dev/null 2>&1 || true
    
    # Immediate fix for any existing SQL config mismatches
    bash fix_db_password_missmatch.sh
    
    # Delayed background fix for files the core app creates asynchronously after container startup
    (sleep 30 && cd /opt/billionmail && bash fix_db_password_missmatch.sh) &
    
    show_info
}

# Run main function
main
