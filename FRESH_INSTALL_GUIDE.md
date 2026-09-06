# Fresh VPS Install Guide - MoeScale V5.0.0

## ⚠️ Prerequisites (Do These FIRST!)

### 1. Server Requirements
- Ubuntu 20.04/22.04
- 4GB+ RAM
- Docker & Docker Compose installed
- Ports 25, 465, 587, 80, 443, 110, 143, 993, 995 open

### 2. Add Your IPs to Interface
```bash
# Check current IPs
ip addr show dev eth0

# Add secondary IPs (replace eth0 with your interface)
sudo ip addr add 85.121.241.250/32 dev eth0
sudo ip addr add 85.121.241.251/32 dev eth0

# Make permanent (Ubuntu 20.04+)
sudo nano /etc/netplan/50-cloud-init.yaml
```

Add under `ethernets:`:
```yaml
            addresses:
            - 85.121.241.162/24
            - 85.121.241.250/32
            - 85.121.241.251/32
```

Then: `sudo netplan apply`

### 3. Set DNS Records (BEFORE installing!)

For EACH domain in Cloudflare/Namecheap:

**A Records:**
- `@` → 85.121.241.162
- `mail` → 85.121.241.162

**MX Record:**
- `@` → `mail.yourdomain.com` (priority 10)

**SPF Record (CRITICAL!):**
```
v=spf1 +a +mx +ip4:85.121.241.162 +ip4:85.121.241.250 +ip4:85.121.241.251 ~all
```

**DMARC Record:**
```
v=DMARC1;p=quarantine;rua=mailto:dmarc@yourdomain.com
```

---

## 🚀 Installation Steps

### Step 1: Clone & Setup
```bash
cd /opt
sudo git clone -b MoeScale-V5.0.0 https://github.com/mamghar001/MoeScale-BillionMail.git
cd MoeScale-BillionMail

# Create .env file
sudo bash -c 'cat > .env << EOF
DBUSER=billionmail
DBNAME=billionmail
DBPASS=billionmail123
REDISPASS=redis123
TZ=UTC
BILLIONMAIL_HOSTNAME=b2bscale.xyz
ADMIN_USERNAME=admin
ADMIN_PASSWORD=your_admin_password
SafePath=admin888
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
IP_WHITELIST_ENABLE=true
EOF'
```

### Step 2: Run Install
```bash
sudo bash install.sh
```

### Step 3: Configure Multi-IP (if needed)
```bash
# Add domains to bm_multi_ip_domain table first (via web UI or SQL)
# Then run:
sudo bash bm.sh multi_ip
```

### Step 4: Verify DNS
```bash
# Check SPF
dig +short yourdomain.com TXT | grep spf

# Should show all 3 IPs
```

---

## ⚠️ EXPECTED ISSUES & FIXES

### Issue 1: Emails to Gmail/Hotmail Bounced
**Cause:** IP reputation

**Solutions:**
1. **Use SMTP Relay (Recommended)** - Set up SendGrid/AWS SES relay
2. **IP Warmup** - Send only 10-50 emails/day for first 2 weeks
3. **Request Delisting** - Check spamhaus.org and request removal

### Issue 2: SPF Failures
**Cause:** DNS not propagated or wrong IPs

**Fix:**
```bash
# Verify SPF includes your actual sending IP
dig +short yourdomain.com TXT

# Should contain: +ip4:85.121.241.162 (your main IP)
```

### Issue 3: Database Connection Errors
**Cause:** Containers not ready

**Fix:**
```bash
sudo docker compose restart
sudo docker compose ps
```

---

## ✅ Testing After Install

```bash
# Test internal delivery
echo "Test" | sendmail -v test@yourdomain.com

# Test external (expect Gmail to block initially)
echo "Test" | sendmail -v yourgmail@gmail.com

# Check logs
sudo tail -f /opt/billionmail/logs/postfix/mail.log
```

---

## 🎯 Is V5.0.0 "Perfect"?

**NO** - but it fixes the CODE bugs. You still need to:
1. ✅ Configure server properly
2. ✅ Set up DNS correctly
3. ✅ Handle IP reputation (biggest issue)
4. ✅ Possibly use SMTP relay for Gmail

**The code won't magically make Gmail accept your emails** if your IP has bad reputation. That's a separate infrastructure issue.

---

## 📞 Still Having Issues?

Check these in order:
1. `docker compose ps` - all containers running?
2. `docker exec billionmail-postfix-billionmail-1 postconf myhostname` - correct domain?
3. `dig yourdomain.com TXT` - SPF has your IPs?
4. `ip addr show` - all 3 IPs attached?
5. Logs: `tail logs/postfix/mail.log`
