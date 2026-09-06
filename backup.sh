#!/bin/bash
# ============================================================
# BillionMail Backup Script
# Usage: bash backup.sh
# Creates a timestamped archive of all data + configs
# ============================================================

set -e

PROJECT_DIR="/opt/billionmail"
BACKUP_DIR="/opt/billionmail-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="billionmail_backup_${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

if [ "$(whoami)" != "root" ]; then
    log_error "Please run as root: sudo bash $0"
fi

if [ -f "/opt/PWD-Billion-Mail.txt" ]; then
    PROJECT_DIR=$(cat /opt/PWD-Billion-Mail.txt)
fi

if [ ! -d "$PROJECT_DIR" ]; then
    log_error "BillionMail project not found at $PROJECT_DIR"
fi

cd "$PROJECT_DIR"

if ! docker compose ps &>/dev/null && ! docker-compose ps &>/dev/null; then
    log_warn "Docker Compose not running. Will backup files only."
    COMPOSE_CMD=""
else
    if docker compose version &>/dev/null; then
        COMPOSE_CMD="docker compose"
    else
        COMPOSE_CMD="docker-compose"
    fi
fi

mkdir -p "$BACKUP_PATH"

log_info "Starting BillionMail backup: $BACKUP_NAME"

# 1. Backup .env (critical)
cp .env "${BACKUP_PATH}/env" 2>/dev/null || true

# 2. Backup configs
cp -r conf "${BACKUP_PATH}/conf"

# 3. Backup SSL certs
cp -r ssl "${BACKUP_PATH}/ssl" 2>/dev/null || true
cp -r ssl-self-signed "${BACKUP_PATH}/ssl-self-signed" 2>/dev/null || true

# 4. Backup core data
cp -r core-data "${BACKUP_PATH}/core-data" 2>/dev/null || true

# 5. Backup webmail data
cp -r webmail-data "${BACKUP_PATH}/webmail-data" 2>/dev/null || true

# 6. Backup vmail data (mailboxes)
log_info "Backing up vmail data (this may be large)..."
cp -r vmail-data "${BACKUP_PATH}/vmail-data" 2>/dev/null || true

# 7. Database dump
if [ -n "$COMPOSE_CMD" ]; then
    log_info "Dumping PostgreSQL database..."
    DB_CONTAINER=$($COMPOSE_CMD ps -q pgsql-billionmail 2>/dev/null || true)
    if [ -n "$DB_CONTAINER" ]; then
        source .env
        docker exec "$DB_CONTAINER" pg_dump -U "${DBUSER:-billionmail}" -d "${DBNAME:-billionmail}" > "${BACKUP_PATH}/database.sql"
        log_ok "Database dumped"
    else
        log_warn "PostgreSQL container not running, skipping DB dump"
    fi
else
    log_warn "Docker not running, skipping DB dump"
fi

# 8. Package
log_info "Compressing backup..."
cd "$BACKUP_DIR"
tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
rm -rf "$BACKUP_PATH"

FINAL_SIZE=$(du -h "${BACKUP_NAME}.tar.gz" | cut -f1)

log_ok "Backup complete: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz (${FINAL_SIZE})"
echo ""
echo "To restore on a new server:"
echo "  1. Copy the .tar.gz to the new server"
echo "  2. Extract it over a fresh BillionMail install"
echo "  3. Restore the DB with: docker exec -i CONTAINER psql -U billionmail -d billionmail < database.sql"
