#!/bin/bash
# Fix DB password mismatch across all Postfix/Dovecot SQL config files.
# Reads DBPASS dynamically from .env — no hardcoded values.

set -e

BILLIONMAIL_DIR="/opt/billionmail"
cd "$BILLIONMAIL_DIR"

# Read current .env password dynamically
if [ ! -f ".env" ]; then
    echo "[fix_db_password_missmatch] .env not found, skipping."
    exit 0
fi

DBPASS=$(grep '^DBPASS=' .env | cut -d'=' -f2-)
if [ -z "$DBPASS" ]; then
    echo "[fix_db_password_missmatch] DBPASS empty in .env, skipping."
    exit 0
fi

FIXED=0

# Fix Postfix SQL maps
if [ -d "conf/postfix/sql" ]; then
    for f in conf/postfix/sql/pgsql_*.cf; do
        if [ -f "$f" ]; then
            CURRENT_PASS=$(grep '^password = ' "$f" | awk -F'password = ' '{print $2}' | head -n1 || true)
            if [ "$CURRENT_PASS" != "$DBPASS" ]; then
                sed -i "s/^password = .*/password = $DBPASS/" "$f"
                FIXED=1
                echo "[fix_db_password_missmatch] Fixed: $f"
            fi
            # Ensure host is always pgsql
            sed -i "s/^hosts = .*/hosts = pgsql/" "$f"
        fi
    done
fi

# Fix Dovecot SQL
if [ -f "conf/dovecot/conf.d/dovecot-sql.conf.ext" ]; then
    sed -i "s/password=[^ ]*/password=$DBPASS/" conf/dovecot/conf.d/dovecot-sql.conf.ext
    sed -i "s/host=[^ ]*/host=pgsql/" conf/dovecot/conf.d/dovecot-sql.conf.ext
fi

# Restart Postfix only if we actually changed something
if [ "$FIXED" -eq 1 ]; then
    echo "[fix_db_password_missmatch] Password mismatch detected and fixed. Restarting Postfix..."
    docker restart billionmail-postfix-billionmail-1 >/dev/null 2>&1 || true
fi

echo "[fix_db_password_missmatch] Done."
