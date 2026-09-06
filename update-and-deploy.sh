#!/bin/bash
# Full update script: Pull latest code + Deploy changes
# Usage: sudo bash update-and-deploy.sh [--ours]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

GIT_STRATEGY="theirs"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  BillionMail Update & Deploy${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ $(whoami) != "root" ]; then
    echo -e "${RED}Error: Must run as root${NC}"
    exit 1
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --ours)
            GIT_STRATEGY="ours"
            shift
            ;;
        --help|-h)
            echo "Usage: sudo bash update-and-deploy.sh [options]"
            echo "Options:"
            echo "  --ours     Keep local changes (use 'ours' merge strategy)"
            echo "  --help     Show this help"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

cd /opt/billionmail

# Detect Docker Compose
if command -v docker-compose &>/dev/null; then
    DOCKER_COMPOSE="docker-compose"
elif docker compose version &>/dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    echo -e "${RED}Error: Docker Compose not found${NC}"
    exit 1
fi

# Step 1: Git Update
echo -e "${YELLOW}[1/4] Updating Code from Git...${NC}"

if [ ! -d ".git" ]; then
    echo -e "${RED}Error: Not a git repository${NC}"
    exit 1
fi

if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

# Set git user if not set
if [[ -z "$(git config user.name)" ]]; then
    git config user.name "BillionMail"
    git config user.email "BillionMail@BillionMail.com"
fi

# Commit current changes
echo -e "${BLUE}Committing local changes...${NC}"
git add -u
git commit -am "Auto-commit before update $(date +%Y-%m-%d_%H:%M:%S)" 2>/dev/null || true

# Fetch and merge
echo -e "${BLUE}Fetching updates...${NC}"
git fetch origin

echo -e "${BLUE}Merging with strategy: $GIT_STRATEGY${NC}"
git config merge.defaultToUpstream true

if git merge -X"$GIT_STRATEGY" -Xpatience -m "Auto-update $(date +%Y-%m-%d_%H:%M:%S)"; then
    echo -e "${GREEN}✓ Code updated successfully${NC}"
else
    echo -e "${RED}✗ Merge failed! There may be conflicts.${NC}"
    echo -e "${YELLOW}Check: git status${NC}"
    exit 1
fi

echo ""

# Step 2: Deploy
echo -e "${YELLOW}[2/4] Deploying Changes...${NC}"

# Use the deploy script with quick mode (frontend patch only)
if [ -f "deploy-updated.sh" ]; then
    bash deploy-updated.sh --quick
else
    echo -e "${YELLOW}deploy-updated.sh not found, using basic restart...${NC}"
    $DOCKER_COMPOSE restart core-billionmail
fi

echo ""

# Step 3: Update Docker images (optional)
echo -e "${YELLOW}[3/4] Checking for Docker image updates...${NC}"
echo -e "${BLUE}Pulling latest images...${NC}"
$DOCKER_COMPOSE pull || echo -e "${YELLOW}Some images may have failed to pull (this is OK for custom builds)${NC}"

echo ""

# Step 4: Final status
echo -e "${YELLOW}[4/4] Final Status...${NC}"

# Check container
if $DOCKER_COMPOSE ps core-billionmail | grep -q "Up"; then
    echo -e "${GREEN}✓ BillionMail is running${NC}"
else
    echo -e "${RED}✗ BillionMail is not running!${NC}"
    $DOCKER_COMPOSE logs core-billionmail --tail=20
    exit 1
fi

# Show recent changes
echo ""
echo -e "${BLUE}Recent commits:${NC}"
git log --oneline -3

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  UPDATE & DEPLOY COMPLETE!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Your BillionMail is now up to date!"
echo ""
