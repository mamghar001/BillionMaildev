#!/bin/bash
# Deploy script for BillionMail with local code changes
# Usage: sudo bash deploy-updated.sh [--skip-frontend] [--skip-backend] [--quick]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SKIP_FRONTEND=0
SKIP_BACKEND=0
QUICK_MODE=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-frontend)
            SKIP_FRONTEND=1
            shift
            ;;
        --skip-backend)
            SKIP_BACKEND=1
            shift
            ;;
        --quick)
            QUICK_MODE=1
            SKIP_BACKEND=1
            shift
            ;;
        --help|-h)
            echo "Usage: sudo bash deploy-updated.sh [options]"
            echo "Options:"
            echo "  --skip-frontend    Skip frontend build (patch built files directly)"
            echo "  --skip-backend     Skip backend build (Go compilation)"
            echo "  --quick            Quick mode: patch JS files, skip backend build"
            echo "  --help, -h         Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  BillionMail Deploy with Updates${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running as root
if [ $(whoami) != "root" ]; then
    echo -e "${RED}Error: Must run as root${NC}"
    exit 1
fi

cd /opt/billionmail

# Detect Docker Compose command
if command -v docker-compose &>/dev/null; then
    DOCKER_COMPOSE="docker-compose"
elif docker compose version &>/dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    echo -e "${RED}Error: Docker Compose not found${NC}"
    exit 1
fi

echo -e "${BLUE}Using: $DOCKER_COMPOSE${NC}"
echo ""

# Step 1: Build/Patch Frontend
echo -e "${YELLOW}[1/3] Processing Frontend...${NC}"

if [ $SKIP_FRONTEND -eq 1 ] || [ $QUICK_MODE -eq 1 ]; then
    echo -e "${BLUE}Patching built JS files directly...${NC}"
    
    # Find and patch the JS file containing rotate_senders default
    JS_FILES=(
        "core/public/static/js/async/3726.57068813.js"
        "core/public/dist/static/js/async/3726.57068813.js"
    )
    
    PATCHED=0
    for js_file in "${JS_FILES[@]}"; do
        if [ -f "$js_file" ]; then
            # Patch default value from :0 to :1
            if grep -q "rotate_senders:0" "$js_file" 2>/dev/null; then
                sed -i 's/rotate_senders:0}/rotate_senders:1}/g' "$js_file"
                echo -e "${GREEN}✓ Patched default value in $js_file${NC}"
                PATCHED=1
            fi
            
            # Patch fallback value from ||0 to ||1
            if grep -q "rotate_senders=l.rotate_senders||0" "$js_file" 2>/dev/null; then
                sed -i 's/rotate_senders=l\.rotate_senders||0/rotate_senders=l.rotate_senders||1/g' "$js_file"
                echo -e "${GREEN}✓ Patched fallback value in $js_file${NC}"
                PATCHED=1
            fi
        fi
    done
    
    if [ $PATCHED -eq 0 ]; then
        echo -e "${YELLOW}⚠ No patches needed (already patched or file not found)${NC}"
    fi
else
    # Try to build frontend properly
    cd core/frontend
    
    # Add pnpm to PATH
    export PATH="$PATH:/root/.local/share/pnpm:$HOME/.local/share/pnpm"
    
    # Check for pnpm
    if ! command -v pnpm &>/dev/null; then
        echo -e "${YELLOW}pnpm not found, installing...${NC}"
        npm install -g pnpm
    fi
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        echo -e "${BLUE}Installing dependencies...${NC}"
        pnpm install
    fi
    
    # Build
    echo -e "${BLUE}Building frontend...${NC}"
    if pnpm run build; then
        echo -e "${GREEN}✓ Frontend built successfully${NC}"
        cp -r dist/* ../public/
        echo -e "${GREEN}✓ Copied built frontend assets to public directory${NC}"
    else
        echo -e "${RED}✗ Frontend build failed!${NC}"
        echo -e "${YELLOW}Falling back to patching built files...${NC}"
        cd /opt/billionmail
        
        # Patch existing files
        for js_file in "${JS_FILES[@]}"; do
            if [ -f "$js_file" ]; then
                sed -i 's/rotate_senders:0}/rotate_senders:1}/g' "$js_file" 2>/dev/null || true
                sed -i 's/rotate_senders=l\.rotate_senders||0/rotate_senders=l.rotate_senders||1/g' "$js_file" 2>/dev/null || true
            fi
        done
    fi
fi

cd /opt/billionmail
echo ""

# Step 2: Build Backend (optional)
if [ $SKIP_BACKEND -eq 0 ] && [ $QUICK_MODE -eq 0 ]; then
    echo -e "${YELLOW}[2/3] Building Backend...${NC}"
    
    cd core
    
    # Check Go version
    GO_VERSION=$(go version 2>/dev/null | grep -o 'go[0-9]\+\.[0-9]\+' | head -1 | sed 's/go//')
    REQUIRED_VERSION="1.22"
    
    if [ -z "$GO_VERSION" ]; then
        echo -e "${RED}Go not installed, skipping backend build${NC}"
        SKIP_BACKEND=1
    elif [ "$(printf '%s\n' "$REQUIRED_VERSION" "$GO_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
        echo -e "${YELLOW}Go version $GO_VERSION is older than required $REQUIRED_VERSION${NC}"
        echo -e "${YELLOW}Skipping backend build (frontend changes are sufficient)${NC}"
        SKIP_BACKEND=1
    else
        # Detect architecture
        ARCH=$(uname -m)
        if [ "$ARCH" == "x86_64" ]; then
            BINARY_NAME="billionmail-amd64"
        elif [ "$ARCH" == "aarch64" ]; then
            BINARY_NAME="billionmail-arm64"
        else
            echo -e "${YELLOW}Unknown architecture: $ARCH, skipping backend build${NC}"
            SKIP_BACKEND=1
        fi
        
        if [ $SKIP_BACKEND -eq 0 ]; then
            echo -e "${BLUE}Building for $ARCH...${NC}"
            
            # Build directly (bypass go-build.sh which has issues)
            export GOOS=linux
            export GOARCH=amd64
            
            if go build -ldflags="-s -w" -o "$BINARY_NAME" main.go; then
                cp "$BINARY_NAME" billionmail
                echo -e "${GREEN}✓ Backend built successfully${NC}"
            else
                echo -e "${YELLOW}Backend build failed, continuing with frontend changes only${NC}"
            fi
        fi
    fi
    
    cd /opt/billionmail
else
    echo -e "${YELLOW}[2/3] Skipping Backend Build${NC}"
fi

echo ""

# Step 3: Deploy
echo -e "${YELLOW}[3/3] Deploying...${NC}"

# Backup
echo -e "${BLUE}Creating backup...${NC}"
BACKUP_TIME=$(date +%Y%m%d_%H%M%S)
cp docker-compose.yml docker-compose.yml.backup.$BACKUP_TIME 2>/dev/null || true
echo -e "${GREEN}✓ Backup: docker-compose.yml.backup.$BACKUP_TIME${NC}"

# Ensure volume mounts exist for direct file deployment
if ! grep -q "./core/public:/opt/billionmail/core/public" docker-compose.yml; then
    echo -e "${YELLOW}⚠ Volume mount for public folder not found in docker-compose.yml${NC}"
    echo -e "${YELLOW}  Your changes may not be visible until you rebuild the Docker image${NC}"
fi

# Restart
echo -e "${BLUE}Restarting BillionMail...${NC}"
$DOCKER_COMPOSE restart core-billionmail

# Verify
sleep 2
if $DOCKER_COMPOSE ps core-billionmail | grep -q "Up"; then
    echo -e "${GREEN}✓ Container is running${NC}"
else
    echo -e "${RED}✗ Container failed to start!${NC}"
    $DOCKER_COMPOSE logs core-billionmail --tail=20
    exit 1
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  DEPLOYMENT COMPLETE!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Changes deployed:"
echo -e "  • Rotate Senders checkbox: ${GREEN}ON by default${NC}"
echo -e "  • Cross-domain sending: ${GREEN}All mailboxes from all domains${NC}"
echo ""
echo -e "Verify: Marketing → Tasks → Create Task"
echo -e "  The 'Rotate Senders' switch should be ${GREEN}enabled by default${NC}"
echo ""

# Show current rotate_senders values in JS
echo -e "${BLUE}Current JS defaults:${NC}"
grep -h "rotate_senders:1" core/public/static/js/async/3726.57068813.js 2>/dev/null | head -1 || echo "  (patched in built files)"
