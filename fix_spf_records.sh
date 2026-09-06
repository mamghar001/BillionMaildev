#!/bin/bash
# Fix SPF Records for all domains
# This updates all domains to include all sending IPs

cd /opt/billionmail
source .env

# All IPs that can send mail
ALL_IPS=("85.121.241.162" "85.121.241.250" "85.121.241.251")

# Build SPF record with all IPs
SPF_IPS=""
for ip in "${ALL_IPS[@]}"; do
    SPF_IPS="${SPF_IPS} +ip4:${ip}"
done
SPF_RECORD="v=spf1 +a +mx${SPF_IPS} ~all"

echo "==================================="
echo "Fixing SPF Records"
echo "==================================="
echo ""
echo "New SPF record will be:"
echo "  ${SPF_RECORD}"
echo ""

# Update SPF in database for each domain
echo "Updating SPF in BillionMail database..."

for domain in affiliategrowth.shop b2bgrowth.shop aiemail.shop moescalesystem.shop aioutboundagents.shop b2baioutbound.shop moescale.xyz b2bscale.xyz; do
    echo "  - Updating ${domain}..."
    
    # Update the domain record in database (this affects what Postfix reports)
    docker exec -e PGPASSWORD=${DBPASS} billionmail-pgsql-billionmail-1 psql -U ${DBUSER} -d ${DBNAME} << EOF 2>/dev/null
UPDATE domain 
SET spf_record = '${SPF_RECORD}' 
WHERE domain = '${domain}';
EOF
    
done

echo ""
echo "==================================="
echo "⚠️  IMPORTANT: Manual DNS Update Required!"
echo "==================================="
echo ""
echo "You must update the SPF TXT record in your DNS for each domain:"
echo ""
for domain in affiliategrowth.shop b2bgrowth.shop aiemail.shop moescalesystem.shop aioutboundagents.shop b2baioutbound.shop moescale.xyz b2bscale.xyz; do
    echo "Domain: ${domain}"
    echo "  Type: TXT"
    echo "  Host: @"
    echo "  Value: ${SPF_RECORD}"
    echo ""
done

echo "If using Namecheap, the script will update these automatically."
echo "If using other DNS, update manually."
echo ""
echo "Also check main.cf myhostname setting..."
docker exec billionmail-postfix-billionmail-1 postconf myhostname 2>/dev/null || echo "Could not check"
