#!/bin/bash
# Noez GRE Tunnel Complete Setup for BillionMail
# One script to handle everything from fresh install to working email sending
#
# Usage:
#   sudo bash noez_setup.sh              # Run complete setup
#   sudo bash noez_setup.sh test         # Test email sending
#   sudo bash noez_setup.sh add IP DOMAIN # Add new IP/domain
#   sudo bash noez_setup.sh status       # Check status
#
# Version: 6.1 - Production Ready - Robust Fresh Install Support
#
# Configuration:
#   1. Copy noez_setup.env.example to noez_setup.env
#   2. Fill in your actual values in noez_setup.env
#   3. Run: sudo bash noez_setup.sh
#   OR run interactively without config file

set -e

# =============================================================================
# LOAD CONFIGURATION FROM ENV FILE (IF EXISTS)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/noez_setup.env"

if [ -f "$ENV_FILE" ]; then
    echo "Loading configuration from $ENV_FILE..."
    # shellcheck source=/dev/null
    source "$ENV_FILE"
fi

# =============================================================================
# DEFAULT CONFIGURATION (used if not set in env file or for interactive mode)
# =============================================================================

# REQUIRED: Your Noez IP (the IP you want to send emails from)
NOEZ_IP="${NOEZ_IP:-}"

# REQUIRED: Your VPS public IP (the IP Noez created the GRE tunnel to)
HOST_IP="${HOST_IP:-}"

# REQUIRED: Noez GRE tunnel remote endpoint (provided by Noez)
NOEZ_GRE_REMOTE="${NOEZ_GRE_REMOTE:-}"

# REQUIRED: Domain to use for sending
DOMAIN="${DOMAIN:-}"

# GRE tunnel internal IPs (usually provided by Noez)
GRE_LOCAL="${GRE_LOCAL:-192.168.31.2}"     # Your side
GRE_REMOTE="${GRE_REMOTE:-192.168.31.1}"    # Noez side
GRE_SUBNET="${GRE_SUBNET:-192.168.31.0/30}" # GRE subnet

# BillionMail API Settings (optional - for API-based domain creation)
BM_API_URL="${BM_API_URL:-}"
BM_API_TOKEN="${BM_API_TOKEN:-}"

# Docker settings (auto-detected if possible)
CONTAINER_NAME="${CONTAINER_NAME:-billionmail-postfix-billionmail-1}"
CONTAINER_NET_NS_IP="${CONTAINER_NET_NS_IP:-}"
DOCKER_BRIDGE_GW="${DOCKER_BRIDGE_GW:-}"
DOCKER_BRIDGE="${DOCKER_BRIDGE:-}"
DOCKER_NETWORK="${DOCKER_NETWORK:-billionmail_network}"
DOCKER_SUBNET="${DOCKER_SUBNET:-172.66.2.0/24}"

# List of all Noez IPs to auto-configure on boot (space-separated)
ALL_NOEZ_IPS="${ALL_NOEZ_IPS:-}"

# Cloudflare DNS Configuration (optional - for automatic DNS setup)
CF_API_TOKEN="${CF_API_TOKEN:-}"
CF_ZONE_ID="${CF_ZONE_ID:-}"
CF_EMAIL="${CF_EMAIL:-}"

# =============================================================================
# END CONFIGURATION
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[✓]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_info() { echo -e "${CYAN}[i]${NC} $1"; }
print_section() { 
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Check root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root (use sudo)"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load .env for DB credentials
source .env 2>/dev/null || true

# Detect Docker bridge interface automatically
detect_docker_bridge() {
    print_info "Detecting Docker bridge..."
    
    # Get container's network info
    local container_networks=$(docker inspect -f '{{json .NetworkSettings.Networks}}' $CONTAINER_NAME 2>/dev/null)
    
    # Try to find the bridge interface
    # First try: network with "b2bscale" or "net-" in name (typically 172.66.2.x)
    DOCKER_BRIDGE_IP=$(echo "$container_networks" | python3 -c "import sys,json; d=json.load(sys.stdin); nets=[v['IPAddress'] for k,v in d.items() if 'b2bscale' in k or 'net-' in k]; print(nets[0] if nets else list(d.values())[0]['IPAddress'])")
    
    if [ -n "$DOCKER_BRIDGE_IP" ]; then
        # Extract the network prefix (e.g., 172.66.2.100 -> 172.66.2.0/24)
        local subnet=$(echo "$DOCKER_BRIDGE_IP" | sed 's/\.[0-9]*$/.0\/24/')
        # Find the bridge interface for this subnet
        DOCKER_BRIDGE=$(ip route | grep "$subnet" | awk '{print $3}' | head -1)
        DOCKER_BRIDGE_GW=$(echo "$DOCKER_BRIDGE_IP" | sed 's/\.[0-9]*$/.1/')
        CONTAINER_NET_NS_IP="$DOCKER_BRIDGE_IP"
    fi
    
    if [ -z "$DOCKER_BRIDGE" ]; then
        # Fallback: try common bridge names
        for br in br-825cda742c28 br-billionmail docker0; do
            if ip link show "$br" &>/dev/null; then
                # Check if container IP is in this network
                local br_subnet=$(ip addr show "$br" | grep "inet " | awk '{print $2}')
                if [ -n "$br_subnet" ]; then
                    DOCKER_BRIDGE="$br"
                    DOCKER_BRIDGE_GW=$(echo "$br_subnet" | sed 's|/.*||' | sed 's/\.1$/.1/')
                    break
                fi
            fi
        done
    fi
    
    if [ -n "$DOCKER_BRIDGE" ]; then
        print_status "Detected Docker bridge: $DOCKER_BRIDGE (GW: $DOCKER_BRIDGE_GW, Container: $CONTAINER_NET_NS_IP)"
    else
        print_error "Could not detect Docker bridge!"
        print_info "Please set DOCKER_BRIDGE manually in noez_setup.env"
        exit 1
    fi
}

# Setup systemd service for auto IP configuration on boot
setup_systemd_service() {
    print_section "Setting Up Auto-Start Service"
    
    # Create the comprehensive IP setup script with GRE tunnel creation
    cat > /opt/billionmail/setup_noez_ips.sh << 'EOFSCRIPT'
#!/bin/bash
# =============================================================================
# Noez GRE Tunnel & IP Auto-Setup for BillionMail
# =============================================================================
# This script runs on boot to recreate the GRE tunnel and re-add all Noez IPs
# to the container. It is idempotent — safe to run multiple times.
#
# Called by: systemd service noez-ips.service
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/noez_setup.env"

# =============================================================================
# LOAD CONFIGURATION
# =============================================================================

if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

# REQUIRED: Get these from noez_setup.env
HOST_IP="${HOST_IP:-}"
NOEZ_GRE_REMOTE="${NOEZ_GRE_REMOTE:-}"
ALL_NOEZ_IPS="${ALL_NOEZ_IPS:-}"

# GRE tunnel defaults
GRE_LOCAL="${GRE_LOCAL:-192.168.31.2}"
GRE_REMOTE="${GRE_REMOTE:-192.168.31.1}"

# Docker defaults
CONTAINER_NAME="${CONTAINER_NAME:-billionmail-postfix-billionmail-1}"

# =============================================================================
# VALIDATION
# =============================================================================

if [ -z "$HOST_IP" ]; then
    echo "ERROR: HOST_IP not set. Please configure noez_setup.env"
    exit 1
fi

if [ -z "$NOEZ_GRE_REMOTE" ]; then
    echo "ERROR: NOEZ_GRE_REMOTE not set. Please configure noez_setup.env"
    exit 1
fi

if [ -z "$ALL_NOEZ_IPS" ]; then
    echo "ERROR: ALL_NOEZ_IPS not set. Please configure noez_setup.env"
    exit 1
fi

# =============================================================================
# STEP 1: DETECT DOCKER BRIDGE
# =============================================================================

echo "=== Detecting Docker bridge ==="

# Get container's network info
CONTAINER_NETWORKS=$(docker inspect -f '{{json .NetworkSettings.Networks}}' "$CONTAINER_NAME" 2>/dev/null || echo "{}")

# Try to find the bridge interface
DOCKER_BRIDGE=""
DOCKER_BRIDGE_GW=""
CONTAINER_NET_NS_IP=""

# First try: network with "b2bscale" or "net-" in name (typically 172.66.2.x)
DOCKER_BRIDGE_IP=$(echo "$CONTAINER_NETWORKS" | python3 -c "
import sys, json
d = json.load(sys.stdin)
nets = [v['IPAddress'] for k, v in d.items() if 'b2bscale' in k or 'net-' in k]
print(nets[0] if nets else (list(d.values())[0]['IPAddress'] if d else ''))
" 2>/dev/null || true)

if [ -n "$DOCKER_BRIDGE_IP" ]; then
    SUBNET=$(echo "$DOCKER_BRIDGE_IP" | sed 's/\.[0-9]*$/.0\/24/')
    DOCKER_BRIDGE=$(ip route | grep "$SUBNET" | awk '{print $3}' | head -1)
    DOCKER_BRIDGE_GW=$(echo "$DOCKER_BRIDGE_IP" | sed 's/\.[0-9]*$/.1/')
    CONTAINER_NET_NS_IP="$DOCKER_BRIDGE_IP"
fi

if [ -z "$DOCKER_BRIDGE" ]; then
    DOCKER_BRIDGE=$(ip route | grep "172.66." | grep "dev br-" | awk '{print $3}' | head -1)
    if [ -n "$DOCKER_BRIDGE" ]; then
        DOCKER_BRIDGE_GW=$(ip addr show "$DOCKER_BRIDGE" | grep "inet " | awk '{print $2}' | sed 's|/.*||' | head -1)
    fi
fi

if [ -z "$DOCKER_BRIDGE" ]; then
    for br in br-billionmail docker0; do
        if ip link show "$br" &>/dev/null; then
            DOCKER_BRIDGE="$br"
            DOCKER_BRIDGE_GW=$(ip addr show "$br" | grep "inet " | awk '{print $2}' | sed 's|/.*||' | head -1)
            break
        fi
    done
fi

if [ -z "$DOCKER_BRIDGE" ]; then
    echo "ERROR: Could not detect Docker bridge!"
    exit 1
fi

if [ -z "$DOCKER_BRIDGE_GW" ]; then
    DOCKER_BRIDGE_GW="172.66.2.1"
fi

echo "Docker bridge: $DOCKER_BRIDGE (GW: $DOCKER_BRIDGE_GW)"

# =============================================================================
# STEP 2: CREATE/VERIFY GRE TUNNEL
# =============================================================================

echo "=== Setting up GRE tunnel ==="

if ! ip link show gre1 &>/dev/null; then
    echo "Creating GRE tunnel..."
    echo "  Local:  $HOST_IP"
    echo "  Remote: $NOEZ_GRE_REMOTE"
    
    ip tunnel add gre1 mode gre local "$HOST_IP" remote "$NOEZ_GRE_REMOTE" ttl 255 || {
        echo "ERROR: Failed to create GRE tunnel!"
        echo "You may need to load the gre module: modprobe ip_gre"
        exit 1
    }
    
    ip addr add "$GRE_LOCAL/30" dev gre1
    ip link set gre1 up
    
    ip route add default via "$GRE_REMOTE" dev gre1 table 20 2>/dev/null || true
    
    echo "GRE tunnel created."
else
    echo "GRE tunnel exists. Verifying..."
    
    CURRENT_LOCAL=$(ip tunnel show gre1 | grep -oP 'local \K[0-9.]+')
    CURRENT_REMOTE=$(ip tunnel show gre1 | grep -oP 'remote \K[0-9.]+')
    
    if [ "$CURRENT_LOCAL" != "$HOST_IP" ] || [ "$CURRENT_REMOTE" != "$NOEZ_GRE_REMOTE" ]; then
        echo "WARNING: Tunnel endpoints don't match config. Recreating..."
        ip link del gre1
        ip tunnel add gre1 mode gre local "$HOST_IP" remote "$NOEZ_GRE_REMOTE" ttl 255
        ip addr add "$GRE_LOCAL/30" dev gre1
        ip link set gre1 up
        ip route add default via "$GRE_REMOTE" dev gre1 table 20 2>/dev/null || true
        echo "GRE tunnel recreated."
    fi
    
    if ! ip addr show gre1 | grep -q "$GRE_LOCAL"; then
        echo "Adding tunnel local IP $GRE_LOCAL..."
        ip addr add "$GRE_LOCAL/30" dev gre1
    fi
    
    if ! ip route show table 20 | grep -q "default via $GRE_REMOTE"; then
        echo "Adding table 20 route..."
        ip route add default via "$GRE_REMOTE" dev gre1 table 20 2>/dev/null || true
    fi
fi

# =============================================================================
# STEP 3: ADD ALL NOEZ IPs TO GRE TUNNEL
# =============================================================================

echo "=== Adding Noez IPs to GRE tunnel ==="

for IP in $ALL_NOEZ_IPS; do
    if ! ip addr show gre1 | grep -q "$IP"; then
        echo "Adding $IP to gre1..."
        ip addr add "$IP/32" dev gre1
    fi
    
    if ! ip rule | grep -q "from $IP lookup 20"; then
        echo "Adding ip rule for $IP -> table 20..."
        ip rule add from "$IP" table 20 prio 200
    fi
done

echo "All Noez IPs on GRE tunnel."

# =============================================================================
# STEP 4: WAIT FOR CONTAINER
# =============================================================================

echo "=== Waiting for container $CONTAINER_NAME ==="

for i in {1..60}; do
    if [ "$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null)" == "running" ]; then
        break
    fi
    echo "Waiting for container... ($i/60)"
    sleep 1
done

CONTAINER_PID=$(docker inspect -f '{{.State.Pid}}' "$CONTAINER_NAME" 2>/dev/null)
if [ -z "$CONTAINER_PID" ]; then
    echo "ERROR: Container $CONTAINER_NAME not found or not running!"
    exit 1
fi

echo "Container PID: $CONTAINER_PID"

# =============================================================================
# STEP 5: ADD NOEZ IPs TO CONTAINER LOOPBACK
# =============================================================================

echo "=== Adding Noez IPs to container loopback ==="

for IP in $ALL_NOEZ_IPS; do
    if ! nsenter -t "$CONTAINER_PID" -n ip addr show lo | grep -q "$IP"; then
        echo "Adding $IP to container lo..."
        nsenter -t "$CONTAINER_PID" -n ip addr add "$IP/32" dev lo
    fi
    
    if ! nsenter -t "$CONTAINER_PID" -n ip rule | grep -q "from $IP"; then
        nsenter -t "$CONTAINER_PID" -n ip rule add from "$IP" table 100
    fi
    
    if ! nsenter -t "$CONTAINER_PID" -n ip route show table 100 | grep -q "default"; then
        nsenter -t "$CONTAINER_PID" -n ip route add default via "$DOCKER_BRIDGE_GW" table 100
    fi
done

# =============================================================================
# STEP 6: CONFIGURE HOST ROUTING
# =============================================================================

echo "=== Configuring host routes ==="

for IP in $ALL_NOEZ_IPS; do
    ip route del table local "$IP" 2>/dev/null || true
    ip route replace "$IP" dev "$DOCKER_BRIDGE" 2>/dev/null || ip route add "$IP" dev "$DOCKER_BRIDGE" 2>/dev/null || true
done

ip route flush cache

# =============================================================================
# STEP 7: IPTABLES RULES
# =============================================================================

echo "=== Setting up iptables rules ==="

for IP in $ALL_NOEZ_IPS; do
    if ! iptables -C FORWARD -s "$IP" -j ACCEPT 2>/dev/null; then
        iptables -I FORWARD -s "$IP" -j ACCEPT
    fi
    if ! iptables -C FORWARD -d "$IP" -j ACCEPT 2>/dev/null; then
        iptables -I FORWARD -d "$IP" -j ACCEPT
    fi
done

# Get Core container IP dynamically to route web traffic (80/443)
CORE_CONTAINER_NAME="billionmail-core-billionmail-1"
CORE_IP=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$v.IPAddress}}{{end}}' "$CORE_CONTAINER_NAME" 2>/dev/null || true)
if [ -n "$CORE_IP" ]; then
    echo "Core container IP: $CORE_IP. Adding DNAT rules for ports 80 and 443..."
    for IP in $ALL_NOEZ_IPS; do
        # Port 80
        if ! iptables -t nat -C PREROUTING -d "$IP" -p tcp --dport 80 -j DNAT --to-destination "$CORE_IP:80" 2>/dev/null; then
            iptables -t nat -A PREROUTING -d "$IP" -p tcp --dport 80 -j DNAT --to-destination "$CORE_IP:80"
        fi
        if ! iptables -t nat -C OUTPUT -d "$IP" -p tcp --dport 80 -j DNAT --to-destination "$CORE_IP:80" 2>/dev/null; then
            iptables -t nat -A OUTPUT -d "$IP" -p tcp --dport 80 -j DNAT --to-destination "$CORE_IP:80"
        fi
        # Port 443
        if ! iptables -t nat -C PREROUTING -d "$IP" -p tcp --dport 443 -j DNAT --to-destination "$CORE_IP:443" 2>/dev/null; then
            iptables -t nat -A PREROUTING -d "$IP" -p tcp --dport 443 -j DNAT --to-destination "$CORE_IP:443"
        fi
        if ! iptables -t nat -C OUTPUT -d "$IP" -p tcp --dport 443 -j DNAT --to-destination "$CORE_IP:443" 2>/dev/null; then
            iptables -t nat -A OUTPUT -d "$IP" -p tcp --dport 443 -j DNAT --to-destination "$CORE_IP:443"
        fi
    done
else
    echo "WARNING: Core container IP not found, skipping web DNAT rules."
fi

if command -v ufw &>/dev/null && ufw status | grep -q "Status: active"; then
    echo "UFW is active, ensuring GRE is allowed..."
    iptables -C ufw-before-input -p 47 -s "$NOEZ_GRE_REMOTE" -j ACCEPT 2>/dev/null || \
        iptables -I ufw-before-input 1 -p 47 -s "$NOEZ_GRE_REMOTE" -j ACCEPT
fi

# =============================================================================
# STEP 8: VERIFY
# =============================================================================

echo "=== Verification ==="

if ip link show gre1 &>/dev/null; then
    echo "✓ GRE tunnel: UP"
else
    echo "✗ GRE tunnel: MISSING"
    exit 1
fi

TUNNEL_IP_COUNT=$(ip addr show gre1 | grep -c "inet 5\.230\.")
echo "✓ Tunnel IPs: $TUNNEL_IP_COUNT"

RULE_COUNT=$(ip rule | grep -c "lookup 20")
echo "✓ ip rules: $RULE_COUNT"

CONTAINER_IP_COUNT=$(nsenter -t "$CONTAINER_PID" -n ip addr show lo | grep -c "inet 5\.230\.")
echo "✓ Container IPs: $CONTAINER_IP_COUNT"

HOST_ROUTE_COUNT=$(ip route | grep -c "dev $DOCKER_BRIDGE")
echo "✓ Host routes: $HOST_ROUTE_COUNT"

if ping -c 1 -W 3 "$GRE_REMOTE" &>/dev/null; then
    echo "✓ Tunnel endpoint reachable"
else
    echo "⚠ Tunnel endpoint NOT reachable (Noez may need to activate)"
fi

echo ""
echo "========================================"
echo "Noez setup complete!"
echo "========================================"
EOFSCRIPT
    chmod +x /opt/billionmail/setup_noez_ips.sh
    print_status "Created comprehensive IP setup script (with GRE tunnel creation)"
    
    # Create systemd service file
    cat > /etc/systemd/system/noez-ips.service << 'EOFSERVICE'
[Unit]
Description=Noez GRE Tunnel & IPs Setup for BillionMail
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/opt/billionmail/setup_noez_ips.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOFSERVICE
    
    # Reload systemd and enable service
    systemctl daemon-reload
    systemctl enable noez-ips.service
    
    # Start the service now
    systemctl start noez-ips.service 2>/dev/null || true
    
    print_status "Systemd service enabled for auto-start on boot"
    print_info "Service: noez-ips.service"
    print_info "Script: /opt/billionmail/setup_noez_ips.sh"
}

# Validate configuration
validate_config() {
    print_section "Configuration"
    
    local errors=0
    local interactive=0
    
    # Check if running interactively
    if [ -t 0 ]; then
        interactive=1
    fi
    
    # NOEZ_IP
    if [ -z "$NOEZ_IP" ]; then
        if [ $interactive -eq 1 ]; then
            print_warning "NOEZ_IP not configured"
            read -p "Enter your Noez IP (e.g., 5.230.168.0): " NOEZ_IP
        else
            print_error "NOEZ_IP not configured! Run interactively or edit the script."
            ((errors++))
        fi
    fi
    
    # HOST_IP
    if [ -z "$HOST_IP" ]; then
        if [ $interactive -eq 1 ]; then
            print_warning "HOST_IP not configured"
            DETECTED_IP=$(ip route get 8.8.8.8 2>/dev/null | head -1 | grep -oP 'src \K[\d.]+')
            if [ -n "$DETECTED_IP" ]; then
                read -p "Enter your VPS IP [detected: $DETECTED_IP]: " HOST_IP
                HOST_IP=${HOST_IP:-$DETECTED_IP}
            else
                read -p "Enter your VPS IP: " HOST_IP
            fi
        else
            print_error "HOST_IP not configured! Run interactively or edit the script."
            ((errors++))
        fi
    fi
    
    # NOEZ_GRE_REMOTE
    if [ -z "$NOEZ_GRE_REMOTE" ]; then
        if [ $interactive -eq 1 ]; then
            print_warning "NOEZ_GRE_REMOTE not configured"
            read -p "Enter Noez GRE remote endpoint (from Noez panel): " NOEZ_GRE_REMOTE
        else
            print_error "NOEZ_GRE_REMOTE not configured! Run interactively or edit the script."
            ((errors++))
        fi
    fi
    
    # DOMAIN
    if [ -z "$DOMAIN" ]; then
        if [ $interactive -eq 1 ]; then
            print_warning "DOMAIN not configured"
            read -p "Enter domain to send from: " DOMAIN
        else
            print_error "DOMAIN not configured! Run interactively or edit the script."
            ((errors++))
        fi
    fi
    
    if [ $errors -gt 0 ]; then
        echo ""
        print_error "Configuration incomplete!"
        print_info "Either:"
        print_info "  1. Run this script interactively (with a TTY)"
        print_info "  2. Create noez_setup.env config file"
        exit 1
    fi
    
    # Show final configuration
    echo ""
    print_status "Configuration:"
    echo "  Noez IP: $NOEZ_IP"
    echo "  Host IP: $HOST_IP"
    echo "  GRE Endpoint: $NOEZ_GRE_REMOTE"
    echo "  Domain: $DOMAIN"
    echo ""
    
    if [ $interactive -eq 1 ]; then
        read -p "Is this correct? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Setup cancelled"
            exit 1
        fi
    fi
}

# Get Cloudflare record ID
get_cf_record_id() {
    local zone_id="$1"
    local record_name="$2"
    local record_type="$3"
    
    curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=$record_type&name=$record_name" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result'][0]['id'])" 2>/dev/null
}

# Get DKIM public key from rspamd container
get_dkim_public_key() {
    local domain="$1"
    local selector="${2:-default}"
    
    # Use Python to extract the full DKIM key reliably from multi-line format
    docker exec billionmail-rspamd-billionmail-1 cat "/var/lib/rspamd/dkim/$domain/$selector.pub" 2>/dev/null | python3 -c '
import sys, re
content = sys.stdin.read()
key_parts = []
lines = content.split("\n")
capturing = False
for line in lines:
    line = line.strip()
    if "p=" in line:
        capturing = True
        match = re.search(r"p=([^\"]+)\"", line)
        if match:
            key_parts.append(match.group(1))
    elif capturing and line.startswith("\"") and not line.startswith("\"v="):
        match = re.search(r"\"([^\"]+)\"", line)
        if match:
            key_parts.append(match.group(1))
    elif capturing and (")" in line or line.endswith(");")):
        break
print("".join(key_parts))
'
}

# Generate DKIM keys for a domain (default + short) inside the rspamd container
generate_dkim_keys() {
    local domain="$1"
    local dkim_dir="/opt/billionmail/rspamd-data/dkim/$domain"
    local conf_file="/opt/billionmail/conf/rspamd/local.d/dkim_signing.conf"
    
    print_info "Ensuring DKIM keys exist for $domain..."
    
    # Generate keys inside the rspamd container if they don't exist on host
    if [ ! -f "$dkim_dir/default.private" ] || [ ! -f "$dkim_dir/short.private" ]; then
        docker exec billionmail-rspamd-billionmail-1 bash -c "
            mkdir -p /var/lib/rspamd/dkim/$domain
            if [ ! -f /var/lib/rspamd/dkim/$domain/default.private ]; then
                rspamadm dkim_keygen -s default -b 2048 -d $domain -k /var/lib/rspamd/dkim/$domain/default.private > /var/lib/rspamd/dkim/$domain/default.pub
            fi
            if [ ! -f /var/lib/rspamd/dkim/$domain/short.private ]; then
                rspamadm dkim_keygen -s short -b 1024 -d $domain -k /var/lib/rspamd/dkim/$domain/short.private > /var/lib/rspamd/dkim/$domain/short.pub
            fi
            chmod 644 /var/lib/rspamd/dkim/$domain/*.private
        "
        print_status "✓ DKIM keys generated for $domain"
    else
        print_status "DKIM keys already exist for $domain"
    fi
    
    # Ensure dkim_signing.conf exists with proper skeleton
    if [ ! -f "$conf_file" ]; then
        cat > "$conf_file" << 'EOF'
sign_headers = "from:sender:reply-to:subject:date:message-id:to:cc:mime-version:content-type:content-transfer-encoding:content-language:resent-to:resent-cc:resent-from:resent-sender:resent-message-id:in-reply-to:references:list-id:list-help:list-owner:list-unsubscribe:list-subscribe:list-post:list-unsubscribe-post:disposition-notification-to:disposition-notification-options:original-recipient:openpgp:autocrypt";

use_esld = false;

domain {
#BT_DOMAIN_DKIM_BEGIN
#BT_DOMAIN_DKIM_END
}
EOF
    fi
    
    # Add domain block to dkim_signing.conf if missing
    if ! grep -q "${domain}_DKIM_BEGIN" "$conf_file"; then
        local dkim_block_file="/tmp/${domain}_dkim_block.txt"
        cat > "$dkim_block_file" << INNER_EOF
#${domain}_DKIM_BEGIN
${domain} {
   selectors [
    {
      path: "/var/lib/rspamd/dkim/${domain}/default.private";
      selector: "default";
    },
    {
      path: "/var/lib/rspamd/dkim/${domain}/short.private";
      selector: "short";
    }
  ]
}
#${domain}_DKIM_END
INNER_EOF
        sed -i "/^#BT_DOMAIN_DKIM_BEGIN$/r $dkim_block_file" "$conf_file"
        rm -f "$dkim_block_file"
        print_status "✓ DKIM config added to dkim_signing.conf for $domain"
        
        # Reload rspamd to pick up new config
        docker exec billionmail-rspamd-billionmail-1 rspamadm control reload >/dev/null 2>&1 || true
    fi
}

# Setup Cloudflare DNS records
setup_cloudflare_dns() {
    local DOMAIN_TO_SETUP="$1"
    
    if [ -z "$CF_API_TOKEN" ]; then
        print_info "Cloudflare API token not configured, skipping DNS setup"
        return 0
    fi
    
    print_section "Setting Up Cloudflare DNS for $DOMAIN_TO_SETUP"
    
    # Find Zone ID if not set
    if [ -z "$CF_ZONE_ID" ]; then
        print_info "Zone ID not configured, trying to find it..."
        CF_ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN_TO_SETUP" \
            -H "Authorization: Bearer $CF_API_TOKEN" \
            -H "Content-Type: application/json" | grep -oP '"id":"\K[^"]+' | head -1)
        
        if [ -n "$CF_ZONE_ID" ]; then
            print_status "Found Zone ID: $CF_ZONE_ID"
        else
            print_error "Could not find Zone ID for $DOMAIN_TO_SETUP"
            return 1
        fi
    fi
    
    # Delete ALL old A records for mail subdomain (there should be only one)
    print_info "Cleaning up old A records for mail.$DOMAIN_TO_SETUP..."
    local existing_a_records=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records?type=A&name=mail.$DOMAIN_TO_SETUP" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json")
    
    echo "$existing_a_records" | python3 -c "import sys,json; d=json.load(sys.stdin); [print(r['id']) for r in d.get('result', [])]" 2>/dev/null | while read record_id; do
        if [ -n "$record_id" ]; then
            curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$record_id" \
                -H "Authorization: Bearer $CF_API_TOKEN" \
                -H "Content-Type: application/json" > /dev/null 2>&1
        fi
    done
    
    # Delete ALL old SPF records (there should be only one)
    print_info "Cleaning up old SPF records..."
    local existing_spf=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records?type=TXT&name=$DOMAIN_TO_SETUP" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json")
    
    echo "$existing_spf" | python3 -c "import sys,json,re; d=json.load(sys.stdin); [print(r['id']) for r in d.get('result', []) if 'v=spf1' in r.get('content', '')]" 2>/dev/null | while read record_id; do
        if [ -n "$record_id" ]; then
            curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$record_id" \
                -H "Authorization: Bearer $CF_API_TOKEN" \
                -H "Content-Type: application/json" > /dev/null 2>&1
        fi
    done
    
    # Delete ALL old DMARC records (there should be only one)
    print_info "Cleaning up old DMARC records..."
    local existing_dmarc=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records?type=TXT&name=_dmarc.$DOMAIN_TO_SETUP" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json")
    
    echo "$existing_dmarc" | python3 -c "import sys,json; d=json.load(sys.stdin); [print(r['id']) for r in d.get('result', [])]" 2>/dev/null | while read record_id; do
        if [ -n "$record_id" ]; then
            curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$record_id" \
                -H "Authorization: Bearer $CF_API_TOKEN" \
                -H "Content-Type: application/json" > /dev/null 2>&1
        fi
    done
    
    # Delete ALL old DKIM records (default selector)
    print_info "Cleaning up old DKIM records..."
    local existing_dkim=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records?type=TXT&name=default._domainkey.$DOMAIN_TO_SETUP" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json")
    
    echo "$existing_dkim" | python3 -c "import sys,json; d=json.load(sys.stdin); [print(r['id']) for r in d.get('result', [])]" 2>/dev/null | while read record_id; do
        if [ -n "$record_id" ]; then
            curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records/$record_id" \
                -H "Authorization: Bearer $CF_API_TOKEN" \
                -H "Content-Type: application/json" > /dev/null 2>&1
        fi
    done
    
    # Create A record
    print_info "Setting up A record: mail.$DOMAIN_TO_SETUP -> $HOST_IP"
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"type\":\"A\",\"name\":\"mail.$DOMAIN_TO_SETUP\",\"content\":\"$HOST_IP\",\"ttl\":120,\"proxied\":false}" > /dev/null 2>&1
    print_status "✓ A record created: mail.$DOMAIN_TO_SETUP -> $HOST_IP"
    
    # Create SPF record
    print_info "Creating SPF TXT record..."
    local spf_content="v=spf1 ip4:$NOEZ_IP ~all"
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"type\":\"TXT\",\"name\":\"$DOMAIN_TO_SETUP\",\"content\":\"$spf_content\",\"ttl\":120}" > /dev/null 2>&1
    print_status "✓ SPF record created: $spf_content"
    
    # Create DMARC record
    print_info "Creating DMARC TXT record..."
    local dmarc_content="v=DMARC1; p=quarantine; rua=mailto:dmarc@$DOMAIN_TO_SETUP"
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"type\":\"TXT\",\"name\":\"_dmarc.$DOMAIN_TO_SETUP\",\"content\":\"$dmarc_content\",\"ttl\":120}" > /dev/null 2>&1
    print_status "✓ DMARC record created"
    
    # Create DKIM record
    print_info "Creating DKIM TXT record (selector: default)..."
    local dkim_key=$(get_dkim_public_key "$DOMAIN_TO_SETUP" "default")
    
    if [ -n "$dkim_key" ]; then
        local dkim_content="v=DKIM1; k=rsa; p=$dkim_key"
        # Truncate if too long (Cloudflare has limits, but DKIM keys are long)
        curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records" \
            -H "Authorization: Bearer $CF_API_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"type\":\"TXT\",\"name\":\"default._domainkey.$DOMAIN_TO_SETUP\",\"content\":\"$dkim_content\",\"ttl\":120}" > /dev/null 2>&1
        print_status "✓ DKIM record created (selector: default)"
    else
        print_warning "DKIM key not found for $DOMAIN_TO_SETUP - you may need to generate it in BillionMail dashboard first"
    fi
    
    print_status "Cloudflare DNS setup complete!"
}

# Add domain to BillionMail
add_domain_to_billionmail() {
    local DOMAIN_TO_ADD="$1"
    
    print_section "Adding Domain to BillionMail: $DOMAIN_TO_ADD"
    
    # Check if domain already exists
    local domain_exists=$(docker exec -i $CONTAINER_NAME psql -U billionmail -d billionmail -t -c \
        "SELECT COUNT(*) FROM domain WHERE domain='$DOMAIN_TO_ADD';" 2>/dev/null | xargs)
    
    if [ "$domain_exists" == "1" ]; then
        print_status "Domain $DOMAIN_TO_ADD already exists in BillionMail"
        # Update A record to the Noez IP for blacklist checking
        print_info "Updating A record to Noez IP for blacklist checking..."
        docker exec -i $CONTAINER_NAME psql -U billionmail -d billionmail -c \
            "UPDATE domain SET a_record='$NOEZ_IP' WHERE domain='$DOMAIN_TO_ADD';" 2>/dev/null
        print_status "✓ A record updated to $NOEZ_IP"
    else
        print_info "Adding domain directly to database..."
        local current_time=$(date +%s)
        
        docker exec -i $CONTAINER_NAME psql -U billionmail -d billionmail -c \
            "INSERT INTO domain (domain, a_record, mailboxes, mailbox_quota, quota, rate_limit, create_time, active, urls, hasbrandinfo, current_usage) 
             VALUES ('$DOMAIN_TO_ADD', '$NOEZ_IP', 101, 5368709120, 10737418240, 12, $current_time, 1, '{}', 0, 0) 
             ON CONFLICT (domain) DO UPDATE SET a_record='$NOEZ_IP';" 2>/dev/null
        
        print_status "✓ Domain added to BillionMail with A record: $NOEZ_IP"
    fi
    
    # RE-ENABLE bm_multi_ip_domain for UI display (with dummy subnet to avoid SNAT issues)
    # The subnet is set to 127.0.0.2/32 so that BillionMail's iptables SNAT rules
    # will never match real traffic (no container traffic originates from 127.0.0.2).
    # This gives us the UI display without the harmful SNAT behavior.
    print_info "Configuring multi-IP domain for UI display..."
    local current_time=$(date +%s)
    docker exec -i $CONTAINER_NAME psql -U billionmail -d billionmail -c         "INSERT INTO bm_multi_ip_domain (domain, outbound_ip, network_name, subnet, postfix_ip, aliases, smtp_server_name, active, create_time, update_time, status) 
         VALUES ('$DOMAIN_TO_ADD', '$NOEZ_IP', 'noez', '127.0.0.2/32', '$NOEZ_IP', '', 'mail', 1, $current_time, $current_time, 'active') 
         ON CONFLICT (domain, outbound_ip) DO UPDATE SET 
            outbound_ip='$NOEZ_IP', 
            postfix_ip='$NOEZ_IP',
            network_name='noez',
            subnet='127.0.0.2/32',
            update_time=$current_time, 
            status='active';" 2>/dev/null
    print_status "✓ Multi-IP domain configured for UI display"
    
    # Generate DKIM keys locally so Cloudflare DNS can publish them
    generate_dkim_keys "$DOMAIN_TO_ADD"
    
    # Setup Cloudflare DNS
    setup_cloudflare_dns "$DOMAIN_TO_ADD"
}

# Setup GRE tunnel
setup_gre_tunnel() {
    print_section "Setting Up GRE Tunnel"
    
    if ip link show gre1 &>/dev/null; then
        print_status "GRE tunnel 'gre1' already exists"
        
        if ip addr show gre1 | grep -q "$NOEZ_IP"; then
            print_status "GRE tunnel already configured with $NOEZ_IP"
            return 0
        else
            print_warning "GRE tunnel exists but may have different configuration"
            read -p "Recreate GRE tunnel? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                ip link del gre1 2>/dev/null || true
            else
                return 0
            fi
        fi
    fi
    
    print_info "Creating GRE tunnel..."
    print_info "  Local: $HOST_IP"
    print_info "  Remote: $NOEZ_GRE_REMOTE"
    print_info "  Noez IP: $NOEZ_IP"
    
    # Create GRE tunnel
    ip tunnel add gre1 mode gre local $HOST_IP remote $NOEZ_GRE_REMOTE ttl 255 || {
        print_error "Failed to create GRE tunnel!"
        print_info "You may need to load the gre module: modprobe ip_gre"
        return 1
    }
    
    # Add addresses
    ip addr add $GRE_LOCAL/30 dev gre1
    ip addr add $NOEZ_IP/32 dev gre1
    
    # Bring up
    ip link set gre1 up
    
    # Add routing policy
    ip rule add from $NOEZ_IP table 20 prio 200 2>/dev/null || true
    ip route add default via $GRE_REMOTE dev gre1 table 20 2>/dev/null || true
    
    print_status "GRE tunnel created successfully!"
}

# Setup container networking
setup_container() {
    print_section "Setting Up Container Networking"
    
    CONTAINER_PID=$(docker inspect -f '{{.State.Pid}}' $CONTAINER_NAME 2>/dev/null) || {
        print_error "Container $CONTAINER_NAME not found!"
        print_info "Start BillionMail first: docker compose up -d"
        exit 1
    }
    
    print_status "Container PID: $CONTAINER_PID"
    
    # Add Noez IP to container's loopback
    print_info "Adding $NOEZ_IP to container..."
    if nsenter -t $CONTAINER_PID -n ip addr add $NOEZ_IP/32 dev lo 2>/dev/null; then
        print_status "Added $NOEZ_IP to container"
    else
        print_warning "$NOEZ_IP may already exist in container"
    fi
    
    # Add container routing
    nsenter -t $CONTAINER_PID -n ip rule add from $NOEZ_IP table 100 2>/dev/null || true
    nsenter -t $CONTAINER_PID -n ip route add default via $DOCKER_BRIDGE_GW table 100 2>/dev/null || true
    
    print_status "Container networking configured!"
}

# Setup host iptables and routing
setup_host_routing() {
    print_section "Setting Up Host Routing"
    
    # Add forwarding rules
    print_info "Adding forwarding rules..."
    iptables -C FORWARD -s $NOEZ_IP -j ACCEPT 2>/dev/null || iptables -I FORWARD -s $NOEZ_IP -j ACCEPT
    iptables -C FORWARD -d $NOEZ_IP -j ACCEPT 2>/dev/null || iptables -I FORWARD -d $NOEZ_IP -j ACCEPT
    print_status "Added forwarding rules"
    
    # CRITICAL FIX: Ensure host routes Noez IP traffic to container, not locally
    print_info "Configuring host routes for $NOEZ_IP..."
    # Delete local route if exists (prevents host from processing replies locally)
    ip route del table local $NOEZ_IP dev gre1 2>/dev/null || true
    # Add route via bridge to container
    if [ -n "$DOCKER_BRIDGE" ]; then
        ip route replace $NOEZ_IP dev $DOCKER_BRIDGE 2>/dev/null || ip route add $NOEZ_IP dev $DOCKER_BRIDGE 2>/dev/null || true
        print_status "Host will forward $NOEZ_IP traffic to container via $DOCKER_BRIDGE"
    fi
    
    # Flush route cache
    ip route flush cache
    print_status "Route cache flushed"
}

# Setup Postfix
setup_postfix() {
    print_section "Configuring Postfix"
    
    TRANSPORT_NAME="smtp_bind_ip_$(echo $NOEZ_IP | tr '.' '_')"
    
    # Check if transport already exists
    if grep -q "^$TRANSPORT_NAME" conf/postfix/master.cf; then
        print_status "Transport $TRANSPORT_NAME already exists"
        # Check if it has smtp_bind_address configured
        if ! grep -A1 "^$TRANSPORT_NAME" conf/postfix/master.cf | grep -q "smtp_bind_address"; then
            print_info "Adding smtp_bind_address to existing transport..."
            sed -i "/^$TRANSPORT_NAME unix/a\\  -o smtp_bind_address=$NOEZ_IP" conf/postfix/master.cf
            print_status "Updated transport with bind address $NOEZ_IP"
        fi
    else
        print_info "Adding transport to master.cf..."
        cat >> conf/postfix/master.cf << EOF

# Noez IP for $DOMAIN
$TRANSPORT_NAME unix  -       -       n       -       -       smtp
  -o smtp_bind_address=$NOEZ_IP
EOF
        print_status "Added transport $TRANSPORT_NAME with bind address $NOEZ_IP"
    fi
    
    # Add domain mapping in database
    print_info "Adding domain transport mapping..."
    
    local existing=$(docker exec -i $CONTAINER_NAME psql -U billionmail -d billionmail -t -c \
        "SELECT COUNT(*) FROM bm_domain_smtp_transport WHERE domain = '@$DOMAIN';" 2>/dev/null | xargs)
    
    if [ "$existing" == "1" ]; then
        print_info "Domain transport mapping already exists, updating..."
        docker exec -i $CONTAINER_NAME psql -U billionmail -d billionmail -c \
            "UPDATE bm_domain_smtp_transport SET smtp_name = '$TRANSPORT_NAME' WHERE domain = '@$DOMAIN';" 2>/dev/null
    else
        docker exec -i $CONTAINER_NAME psql -U billionmail -d billionmail -c \
            "INSERT INTO bm_domain_smtp_transport (atype, domain, smtp_name) VALUES ('dedicated_ip', '@$DOMAIN', '$TRANSPORT_NAME');" 2>/dev/null
        print_status "Added domain transport mapping: @$DOMAIN -> $TRANSPORT_NAME"
    fi
    
    # Restart Postfix (reload doesn't pick up new transports)
    print_info "Restarting Postfix to load new transport..."
    docker restart $CONTAINER_NAME 2>/dev/null && sleep 3 || {
        print_warning "Postfix restart failed"
    }
    
    # Restore Noez IPs to container loopback after restart wipes them
    bash /opt/billionmail/setup_noez_ips.sh >/dev/null 2>&1
    
    print_status "Postfix configured!"
}

# Test connectivity
test_connectivity() {
    print_section "Testing Connectivity"
    
    CONTAINER_PID=$(docker inspect -f '{{.State.Pid}}' $CONTAINER_NAME 2>/dev/null)
    
    print_info "Testing container internet connectivity..."
    if nsenter -t $CONTAINER_PID -n ping -c 3 8.8.8.8 &>/dev/null; then
        print_status "✅ Container can reach internet!"
    else
        print_warning "⚠️ Container internet test failed (may be temporary)"
    fi
    
    print_info "Testing DNS resolution..."
    if nsenter -t $CONTAINER_PID -n nslookup google.com &>/dev/null; then
        print_status "✅ DNS working!"
    else
        print_warning "⚠️ DNS may have issues"
    fi
}

# Add new IP/domain
add_new_ip() {
    local NEW_IP="$1"
    local NEW_DOMAIN="$2"
    
    if [ -z "$NEW_IP" ] || [ -z "$NEW_DOMAIN" ]; then
        print_error "Usage: $0 add <NOEZ_IP> <DOMAIN>"
        exit 1
    fi
    
    print_section "Adding New IP: $NEW_IP for Domain: $NEW_DOMAIN"
    
    # Save original values
    ORIG_NOEZ_IP="$NOEZ_IP"
    ORIG_DOMAIN="$DOMAIN"
    
    NOEZ_IP="$NEW_IP"
    DOMAIN="$NEW_DOMAIN"
    
    # Detect Docker bridge
    detect_docker_bridge
    
    # Check/create GRE tunnel
    print_section "Setting Up GRE Tunnel for $NEW_IP"
    
    if ! ip link show gre1 &>/dev/null; then
        print_info "GRE tunnel not found, creating..."
        setup_gre_tunnel
    else
        print_status "GRE tunnel exists"
        
        if ! ip addr show gre1 | grep -q "$NEW_IP"; then
            print_info "Adding $NEW_IP to GRE tunnel..."
            ip addr add $NEW_IP/32 dev gre1
            print_status "Added $NEW_IP to GRE tunnel"
        else
            print_status "$NEW_IP already on GRE tunnel"
        fi
        
        print_info "Adding routing policy for $NEW_IP..."
        ip rule add from $NEW_IP table 20 prio 200 2>/dev/null || print_info "Routing policy may already exist"
        ip route add default via $GRE_REMOTE dev gre1 table 20 2>/dev/null || true
        print_status "Routing policy configured"
    fi
    
    # Add domain to BillionMail
    add_domain_to_billionmail "$NEW_DOMAIN"
    
    # Run setup steps
    setup_container
    setup_host_routing
    setup_postfix
    test_connectivity
    
    # Create 100 mailboxes for the new domain
    print_section "Creating 100 Mailboxes for $NEW_DOMAIN"
    print_info "This will create 100 mailboxes with USA women's names"
    print_info "Format: firstname.lastname@$NEW_DOMAIN"
    print_info ""
    
    # Check if Python script exists
    MAILBOX_SCRIPT="/opt/create_100_mailboxes.py"
    if [ -f "$MAILBOX_SCRIPT" ]; then
        # Ask user if they want to create mailboxes
        read -p "Create 100 mailboxes for $NEW_DOMAIN? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Starting mailbox creation..."
            python3 "$MAILBOX_SCRIPT" "$NEW_DOMAIN" --skip-confirm
            if [ $? -eq 0 ]; then
                print_status "✓ Mailboxes created successfully!"
                print_info "Check mailboxes/mailboxes_${NEW_DOMAIN//./_}.csv for credentials"
            else
                print_warning "Some mailboxes may have failed. Check the logs."
            fi
        else
            print_info "Skipping mailbox creation"
            print_info "You can create them later with: python3 $MAILBOX_SCRIPT $NEW_DOMAIN"
        fi
    else
        print_warning "Mailbox creation script not found at $MAILBOX_SCRIPT"
        print_info "You can create mailboxes manually later"
    fi
    
    # Restore original values
    NOEZ_IP="$ORIG_NOEZ_IP"
    DOMAIN="$ORIG_DOMAIN"
    
    print_section "✅ New IP Added Successfully!"
    print_info "IP: $NEW_IP"
    print_info "Domain: $NEW_DOMAIN"
    print_info ""
    print_info "Note: Domain should appear in BillionMail UI. Refresh if needed."
}

# Show status
show_status() {
    print_section "Noez GRE Tunnel Status"
    
    echo ""
    echo -e "${CYAN}Configuration:${NC}"
    echo "  Noez IP: $NOEZ_IP"
    echo "  Domain: $DOMAIN"
    echo "  Host IP: $HOST_IP"
    
    echo ""
    echo -e "${CYAN}GRE Tunnel:${NC}"
    if ip link show gre1 &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} GRE tunnel exists"
        ip addr show gre1 | grep "inet " | head -1 | sed 's/^/  /'
    else
        echo -e "  ${RED}✗${NC} GRE tunnel not found"
    fi
    
    echo ""
    echo -e "${CYAN}Container:${NC}"
    if docker ps | grep -q "$CONTAINER_NAME"; then
        echo -e "  ${GREEN}✓${NC} Container running"
        CONTAINER_PID=$(docker inspect -f '{{.State.Pid}}' $CONTAINER_NAME 2>/dev/null)
        if nsenter -t $CONTAINER_PID -n ip addr show lo 2>/dev/null | grep -q "$NOEZ_IP"; then
            echo -e "  ${GREEN}✓${NC} Noez IP ($NOEZ_IP) in container"
        else
            echo -e "  ${RED}✗${NC} Noez IP not in container"
        fi
    else
        echo -e "  ${RED}✗${NC} Container not running"
    fi
    
    echo ""
    echo -e "${CYAN}Routing Rules:${NC}"
    ip rule | grep -E "(from $NOEZ_IP)" | sed 's/^/  /' || echo "  (none found)"
    
    echo ""
    echo -e "${CYAN}Auto-Start Service:${NC}"
    if systemctl is-enabled noez-ips.service &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} noez-ips.service enabled"
        systemctl is-active noez-ips.service &>/dev/null && echo -e "  ${GREEN}✓${NC} Service active" || echo -e "  ${YELLOW}!${NC} Service inactive"
    else
        echo -e "  ${RED}✗${NC} noez-ips.service not enabled"
    fi
}

# Main setup
main_setup() {
    validate_config
    detect_docker_bridge
    setup_gre_tunnel
    add_domain_to_billionmail "$DOMAIN"
    setup_container
    setup_host_routing
    setup_postfix
    setup_systemd_service
    test_connectivity
    
    print_section "✅ Setup Complete!"
    print_info "Domain: $DOMAIN"
    print_info "Noez IP: $NOEZ_IP"
    print_info ""
    print_info "You can now send emails from $DOMAIN"
    print_info "Test with: sudo bash $0 test"
    print_info "Check status: sudo bash $0 status"
}

# Main
case "${1:-}" in
    add)
        add_new_ip "$2" "$3"
        ;;
    status)
        show_status
        ;;
    test)
        print_section "Send test email from BillionMail UI"
        print_info "Go to your BillionMail dashboard and send a test email"
        print_info "from admin@$DOMAIN to mail-tester.com"
        ;;
    *)
        main_setup
        ;;
esac
