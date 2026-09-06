#!/bin/bash
# =============================================================================
# Noez GRE Tunnel & IP Auto-Setup for BillionMail
# =============================================================================
# This script runs on boot to recreate the GRE tunnel and re-add all Noez IPs
# to the container. It is idempotent — safe to run multiple times.
#
# Usage: sudo bash /opt/billionmail/setup_noez_ips.sh
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
ALL_NOEZ_IPS="5.230.228.116 5.230.228.117 5.230.228.118 5.230.228.138 5.230.228.152 5.230.228.153 5.230.228.174 5.230.229.133 5.230.229.154 5.230.229.161 5.230.229.164 5.230.229.165 5.230.229.166 5.230.119.170 5.230.122.3 5.230.122.4"

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
    # Extract the network prefix (e.g., 172.66.2.100 -> 172.66.2.0/24)
    SUBNET=$(echo "$DOCKER_BRIDGE_IP" | sed 's/\.[0-9]*$/.0\/24/')
    # Find the bridge interface for this subnet
    DOCKER_BRIDGE=$(ip route | grep "$SUBNET" | awk '{print $3}' | head -1)
    DOCKER_BRIDGE_GW=$(echo "$DOCKER_BRIDGE_IP" | sed 's/\.[0-9]*$/.1/')
    CONTAINER_NET_NS_IP="$DOCKER_BRIDGE_IP"
fi

if [ -z "$DOCKER_BRIDGE" ]; then
    # Fallback: try to detect from routing table
    DOCKER_BRIDGE=$(ip route | grep "172.66." | grep "dev br-" | awk '{print $3}' | head -1)
    if [ -n "$DOCKER_BRIDGE" ]; then
        DOCKER_BRIDGE_GW=$(ip addr show "$DOCKER_BRIDGE" | grep "inet " | awk '{print $2}' | sed 's|/.*||' | head -1)
    fi
fi

if [ -z "$DOCKER_BRIDGE" ]; then
    # Last fallback: try common bridge names
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
    
    # Add default route for table 20
    ip route add default via "$GRE_REMOTE" dev gre1 table 20 2>/dev/null || true
    
    echo "GRE tunnel created."
else
    echo "GRE tunnel exists. Verifying..."
    
    # Verify tunnel has correct endpoints
    CURRENT_LOCAL=$(ip tunnel show gre1 | grep -oP 'local \K[0-9.]+')
    CURRENT_REMOTE=$(ip tunnel show gre1 | grep -oP 'remote \K[0-9.]+')
    
    if [ "$CURRENT_LOCAL" != "$HOST_IP" ] || [ "$CURRENT_REMOTE" != "$NOEZ_GRE_REMOTE" ]; then
        echo "WARNING: Tunnel endpoints don't match config."
        echo "  Current: local=$CURRENT_LOCAL remote=$CURRENT_REMOTE"
        echo "  Expected: local=$HOST_IP remote=$NOEZ_GRE_REMOTE"
        echo "Recreating tunnel..."
        ip link del gre1
        ip tunnel add gre1 mode gre local "$HOST_IP" remote "$NOEZ_GRE_REMOTE" ttl 255
        ip addr add "$GRE_LOCAL/30" dev gre1
        ip link set gre1 up
        ip route add default via "$GRE_REMOTE" dev gre1 table 20 2>/dev/null || true
        echo "GRE tunnel recreated."
    fi
    
    # Ensure tunnel local IP is set
    if ! ip addr show gre1 | grep -q "$GRE_LOCAL"; then
        echo "Adding tunnel local IP $GRE_LOCAL..."
        ip addr add "$GRE_LOCAL/30" dev gre1
    fi
    
    # Ensure table 20 route exists
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
    
    # Ensure ip rule exists
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
    
    # Add container routing policy
    if ! nsenter -t "$CONTAINER_PID" -n ip rule | grep -q "from $IP"; then
        nsenter -t "$CONTAINER_PID" -n ip rule add from "$IP" table 100
    fi
    
    # Add container default route in table 100
    if ! nsenter -t "$CONTAINER_PID" -n ip route show table 100 | grep -q "default"; then
        nsenter -t "$CONTAINER_PID" -n ip route add default via "$DOCKER_BRIDGE_GW" table 100
    fi
done

# =============================================================================
# STEP 6: CONFIGURE HOST ROUTING (forward to container, not local)
# =============================================================================

echo "=== Configuring host routes ==="

for IP in $ALL_NOEZ_IPS; do
    # Delete local route (prevents host from intercepting replies)
    ip route del table local "$IP" 2>/dev/null || true
    
    # Add route via bridge to container
    ip route replace "$IP" dev "$DOCKER_BRIDGE" 2>/dev/null || ip route add "$IP" dev "$DOCKER_BRIDGE" 2>/dev/null || true
done

# Flush route cache
ip route flush cache

# =============================================================================
# STEP 7: IPTABLES RULES
# =============================================================================

echo "=== Setting up iptables rules ==="

# Allow forwarding for all Noez IPs (both directions)
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

# Allow GRE protocol through UFW (if active)
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

# Test tunnel connectivity
if ping -c 1 -W 3 "$GRE_REMOTE" &>/dev/null; then
    echo "✓ Tunnel endpoint reachable"
else
    echo "⚠ Tunnel endpoint NOT reachable (Noez may need to activate)"
fi

echo ""
echo "========================================"
echo "Noez setup complete!"
echo "========================================"
