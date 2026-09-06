# Noez GRE Tunnel Setup for BillionMail

> **ONE SCRIPT - ONE COMMAND - DOES EVERYTHING**
>
> ✅ GRE Tunnel Setup  
> ✅ BillionMail Domain Configuration  
> ✅ Container Networking  
> ✅ Postfix Configuration  
> ✅ Cloudflare DNS (automatic SPF, A, DMARC records)  
> ✅ Auto-start on Boot  
> ✅ Multiple Domains per IP  

## 🚀 QUICK START (Fresh VPS Install)

### Prerequisites
- Ubuntu/Debian VPS with public IP
- Noez account with GRE tunnel service
- BillionMail installed at `/opt/billionmail`
- Root/sudo access

### Step 1: Create Configuration File

```bash
cd /opt/billionmail
cp noez_setup.env.example noez_setup.env
nano noez_setup.env
```

Fill in your values:
```bash
# REQUIRED - Get these from Noez panel
NOEZ_IP="5.230.168.0"
HOST_IP="YOUR_VPS_PUBLIC_IP"
NOEZ_GRE_REMOTE="5.230.205.35"  # From Noez panel

# Your domain
DOMAIN="yourdomain.com"

# All your Noez IPs (for auto-setup)
ALL_NOEZ_IPS="5.230.168.0"

# Optional: Cloudflare for auto-DNS
CF_API_TOKEN="your-cloudflare-token"
```

### Step 2: Run Setup

```bash
sudo bash noez_setup.sh
```

That's it! The script will:
1. Create GRE tunnel
2. Configure container networking
3. Add domain to BillionMail
4. Setup Cloudflare DNS (if token provided)
5. Configure Postfix with IP binding
6. Enable auto-start on boot

### Step 3: Test

Send a test email from `admin@yourdomain.com` to [mail-tester.com](https://www.mail-tester.com/)

---

## 📊 Commands

| Command | Description |
|---------|-------------|
| `sudo bash noez_setup.sh` | **COMPLETE SETUP** - Run everything |
| `sudo bash noez_setup.sh add IP DOMAIN` | Add new IP/domain pair |
| `sudo bash noez_setup.sh status` | Check status |

---

## 🔄 Adding More IPs/Domains

### Add Another IP + Domain

```bash
sudo bash noez_setup.sh add 5.230.168.X newdomain.com
```

### Multiple Domains on Same IP

```bash
# Domain 1
sudo bash noez_setup.sh add 5.230.168.10 domain1.com

# Domain 2 (same IP)
sudo bash noez_setup.sh add 5.230.168.10 domain2.com
```

**How it works:**
- Both domains share the same Postfix transport
- Each domain has its own DNS records
- Both send from IP `5.230.168.10`

### Update ALL_NOEZ_IPS

After adding all IPs, update `noez_setup.env`:
```bash
ALL_NOEZ_IPS="5.230.168.0 5.230.168.1 5.230.168.2 5.230.168.10"
```

This ensures all IPs are re-added on boot.

---

## 🔧 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         HOST (VPS)                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              GRE Tunnel (gre1)                       │   │
│  │  ┌──────────────────────────────────────────────┐   │   │
│  │  │ 5.230.168.0  ┌───┐                          │   │   │
│  │  │ 5.230.168.1  │IP1│  →  Internet (Noez)      │   │   │
│  │  │ 5.230.168.2  └───┘                          │   │   │
│  │  │ 5.230.168.10                                  │   │   │
│  │  └──────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                  │
│                    Docker Bridge                             │
│                           │                                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         BillionMail Postfix Container               │   │
│  │  ┌──────────────────────────────────────────────┐   │   │
│  │  │ Lo interface:                                │   │   │
│  │  │   5.230.168.0/32 (binds to IP1)             │   │   │
│  │  │   5.230.168.1/32 (binds to IP2)             │   │   │
│  │  │   ...                                        │   │   │
│  │  └──────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

**Key Points:**
- GRE tunnel carries all Noez IPs
- Container loopback binds to each IP for Postfix
- Host routes reply traffic back to container (not locally)
- Postfix `smtp_bind_address` ensures correct source IP

---

## 🆘 Troubleshooting

### "Email sent from wrong IP"

**Cause:** Postfix transport missing `smtp_bind_address`

**Fix:** Already fixed in latest version. Verify in `conf/postfix/master.cf`:
```
smtp_bind_ip_5_230_168_10 unix - - n - - smtp
  -o smtp_bind_address=5.230.168.10
```

### "No reply from container"

**Cause:** Host processing Noez IP traffic locally instead of forwarding to container

**Fix:** Run the setup script again, or manually:
```bash
# Remove local route
ip route del table local 5.230.168.10 dev gre1

# Add route to container
ip route add 5.230.168.10 dev br-825cda742c28
```

### "Container not found"

```bash
cd /opt/billionmail
docker compose up -d
```

### Check logs:
```bash
tail -f /opt/billionmail/logs/postfix/mail.log
```

---

## 💾 Auto-Start on Boot

The script automatically creates a systemd service (`noez-ips.service`) that:
1. Waits for Docker to start
2. Waits for BillionMail container
3. Re-adds all Noez IPs to container
4. Configures host routing

**Verify:**
```bash
systemctl status noez-ips.service
```

**Manual run:**
```bash
sudo bash /opt/billionmail/setup_noez_ips.sh
```

---

## 📝 Files

| File | Purpose | In Git? |
|------|---------|---------|
| `noez_setup.sh` | **Main script** | ✅ Yes |
| `noez_setup.env.example` | Config template | ✅ Yes |
| `noez_setup.env` | **Your private config** | ❌ No (gitignored) |
| `NOEZ_SETUP.md` | This documentation | ✅ Yes |
| `setup_noez_ips.sh` | Auto-generated helper | ❌ No |

---

## ✅ Tested Configurations

- Ubuntu 22.04 LTS
- Docker 24.x
- BillionMail v5.x
- Noez GRE tunnel service
- Cloudflare DNS API

**Version:** 6.1 - Production Ready  
**Date:** 2026-03-30
