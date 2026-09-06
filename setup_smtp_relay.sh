#!/bin/bash
# Setup SMTP Relay for BillionMail
# This configures Postfix to send through an SMTP relay instead of direct delivery

set -e

cd /opt/billionmail
source .env

echo "==================================="
echo "BillionMail SMTP Relay Setup"
echo "==================================="
echo ""
echo "This will configure BillionMail to send emails through an SMTP relay"
echo "instead of sending directly (which is blocked by Gmail/Hotmail)."
echo ""

# Check if running as root
if [ "$(id -u)" != "0" ]; then
   echo "Error: This script must be run as root" 
   exit 1
fi

# Get relay information
echo "Select your SMTP relay provider:"
echo "1) SendGrid"
echo "2) Amazon SES"
echo "3) Mailgun"
echo "4) Postmark"
echo "5) Custom SMTP"
echo ""
read -p "Enter choice (1-5): " relay_choice

case $relay_choice in
    1)
        RELAY_HOST="smtp.sendgrid.net"
        RELAY_PORT="587"
        echo "Using SendGrid: $RELAY_HOST:$RELAY_PORT"
        ;;
    2)
        RELAY_HOST="email-smtp.us-east-1.amazonaws.com"
        RELAY_PORT="587"
        echo "Using Amazon SES: $RELAY_HOST:$RELAY_PORT"
        echo "Note: Use your SES SMTP credentials, not AWS credentials"
        ;;
    3)
        RELAY_HOST="smtp.mailgun.org"
        RELAY_PORT="587"
        echo "Using Mailgun: $RELAY_HOST:$RELAY_PORT"
        ;;
    4)
        RELAY_HOST="smtp.postmarkapp.com"
        RELAY_PORT="587"
        echo "Using Postmark: $RELAY_HOST:$RELAY_PORT"
        ;;
    5)
        read -p "Enter SMTP host: " RELAY_HOST
        read -p "Enter SMTP port (587): " RELAY_PORT
        RELAY_PORT=${RELAY_PORT:-587}
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
read -p "Enter SMTP username: " RELAY_USER
read -s -p "Enter SMTP password: " RELAY_PASS
echo ""

echo ""
echo "Configuring SMTP relay..."

# Create/update relay configuration
docker exec -e PGPASSWORD=${DBPASS} billionmail-pgsql-billionmail-1 psql -U ${DBUSER} -d ${DBNAME} << EOF
-- Insert or update relay config
INSERT INTO bm_relay_config (remark, rtype, relay_host, relay_port, auth_user, auth_password, active)
VALUES ('Primary SMTP Relay', 'custom', '${RELAY_HOST}', ${RELAY_PORT}, '${RELAY_USER}', '${RELAY_PASS}', 1)
ON CONFLICT (id) DO UPDATE SET
    relay_host = EXCLUDED.relay_host,
    relay_port = EXCLUDED.relay_port,
    auth_user = EXCLUDED.auth_user,
    auth_password = EXCLUDED.auth_password,
    active = 1;
EOF

# Get the relay config ID
RELAY_ID=$(docker exec -e PGPASSWORD=${DBPASS} billionmail-pgsql-billionmail-1 psql -U ${DBUSER} -d ${DBNAME} -t -c "SELECT id FROM bm_relay_config WHERE active = 1 LIMIT 1;" | xargs)

echo "Relay config ID: $RELAY_ID"

# Map all domains to use this relay
docker exec -e PGPASSWORD=${DBPASS} billionmail-pgsql-billionmail-1 psql -U ${DBUSER} -d ${DBNAME} << EOF
-- Map all domains to use the relay
INSERT INTO bm_relay_domain_mapping (sender_domain, relay_id)
SELECT domain, ${RELAY_ID} FROM domain
ON CONFLICT (sender_domain) DO UPDATE SET relay_id = EXCLUDED.relay_id;
EOF

# Update sasl_passwd for Postfix
echo "${RELAY_USER}:${RELAY_PASS}" > conf/postfix/conf/sasl_passwd

# Rebuild hash
docker exec billionmail-postfix-billionmail-1 postmap /etc/postfix/conf/sasl_passwd 2>/dev/null || true

# Enable sender_dependent_relayhost_maps in main.cf
if ! grep -q "^sender_dependent_relayhost_maps" conf/postfix/main.cf; then
    echo "sender_dependent_relayhost_maps = pgsql:/etc/postfix/sql/pgsql_sender_relay_maps.cf" >> conf/postfix/main.cf
fi

# Restart Postfix
docker compose restart postfix-billionmail

echo ""
echo "==================================="
echo "✅ SMTP Relay configured!"
echo "==================================="
echo ""
echo "Relay: ${RELAY_HOST}:${RELAY_PORT}"
echo "All domains will now send through this relay."
echo ""
echo "Test with: echo 'Test' | sendmail -v yourgmail@gmail.com"
echo ""
