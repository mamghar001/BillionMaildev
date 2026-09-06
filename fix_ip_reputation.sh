#!/bin/bash
# Fix IP Reputation Script
echo "==================================="
echo "IP Reputation Fix Guide"
echo "==================================="
echo ""
echo "Your IPs: 85.121.241.162, 85.121.241.250, 85.121.241.251"
echo ""

echo "Step 1: Check current blocklist status"
echo "--------------------------------------"
for ip in 85.121.241.162 85.121.241.250 85.121.241.251; do
    echo "Checking $ip..."
    echo "  Spamhaus: https://www.spamhaus.org/query/ip/$ip"
    echo "  MXToolbox: https://mxtoolbox.com/SuperTool.aspx?action=blacklist:$ip"
done

echo ""
echo "Step 2: Set rDNS/PTR Records (Contact your hosting provider)"
echo "--------------------------------------------------------------"
echo "Request these PTR records:"
echo "  85.121.241.162 → mail.affiliategrowth.shop"
echo "  85.121.241.250 → mail.b2bscale.xyz"
echo "  85.121.241.251 → mail.yourdomain.com"
echo ""

echo "Step 3: IP Warmup Schedule (IMPORTANT)"
echo "---------------------------------------"
echo "Week 1: Send max 50 emails/day to Gmail/Hotmail"
echo "Week 2: Send max 100 emails/day"
echo "Week 3: Send max 250 emails/day"
echo "Week 4: Send max 500 emails/day"
echo "Week 5+: Gradually increase"
echo ""

echo "Step 4: Request Delisting"
echo "--------------------------"
echo "1. Spamhaus: https://www.spamhaus.org/removal/"
echo "2. Microsoft: https://sender.office.com/"
echo "3. Google: https://support.google.com/mail/contact/sf_wl_bulk"
echo ""

echo "Step 5: Verify Setup"
echo "---------------------"
echo "Check your SPF record includes all IPs:"
dig +short affiliategrowth.shop TXT | grep spf
echo ""
echo "Check DKIM is working:"
dig +short default._domainkey.b2bscale.xyz TXT
echo ""

echo "==================================="
echo "This process takes 2-4 weeks minimum!"
echo "For immediate delivery, use SMTP Relay instead."
echo "==================================="
