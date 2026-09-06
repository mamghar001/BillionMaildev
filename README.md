# BillionMail - MoeScale Edition

> **🚀 ONE-COMMAND INSTALL:**
> ```bash
> bash <(curl -sSL https://raw.githubusercontent.com/mamghar001/MoeScale-BillionMail/main/one-command-install.sh)
> ```

---

## 🏷️ Current Release: v4.9.0

| Version | Status | Notes |
|---------|--------|-------|
| **v4.9.0** | ✅ **Stable** | Fresh-install ready — all critical bugs fixed |

---

## ✅ What's Fixed in v4.9.0

1. **Dovecot SSL bootloop** — Removed hardcoded private domain SSL blocks that caused Dovecot to fatal-crash on startup on every fresh VPS.
2. **Postfix DB password desync** — The installer now re-applies SQL config passwords *after* `install.sh` finishes, preventing the `451 Temporary lookup failure` that blocked email sending.
3. **Sanitized private config remnants** — All hardcoded private domain routes, DKIM selectors, BCC aliases, and SSL mappings removed from repo skeleton.

---

## 📦 Quick Start

### One-Command Install (Recommended)
```bash
bash <(curl -sSL https://raw.githubusercontent.com/mamghar001/MoeScale-BillionMail/main/one-command-install.sh)
```

### 🏷️ Advanced: Install Specific Version or Branch
If you need to target a specific release tag or development branch, you can pass the `BRANCH` environment variable:
```bash
# Example: Install v4.9.0
BRANCH=v4.9.0 bash <(curl -sSL https://raw.githubusercontent.com/mamghar001/MoeScale-BillionMail/main/one-command-install.sh)

# Example: Install a development branch
BRANCH=moescale-fixed bash <(curl -sSL https://raw.githubusercontent.com/mamghar001/MoeScale-BillionMail/main/one-command-install.sh)
```

The script will:
- Check system requirements (Ubuntu 20.04/22.04/24.04)
- Install Docker & dependencies
- Ask for your domain, admin credentials, and IPs
- Clone the v4.9.0 stable release
- Configure and start all services automatically
- Sync SQL passwords and restart Postfix post-install

You only need to provide:
- Your domain name (e.g. `brainbaba.org`)
- Admin username & password
- Your server IP(s)
- (Optional) SMTP relay credentials for Gmail/Hotmail delivery

---

## ✅ Setup Checklist

### 1. Server Requirements
- Ubuntu 20.04, 22.04, or 24.04 VPS
- 2GB+ RAM, 20GB+ disk
- Root access
- Ports open: `25, 465, 587, 80, 443, 110, 143, 993, 995`

### 2. DNS Records (before install)
| Type | Name | Value |
|------|------|-------|
| A | `@` | Your VPS IP |
| A | `mail` | Your VPS IP |
| MX | `@` | `mail.yourdomain.com` (priority 10) |
| TXT | `@` | `v=spf1 +a +mx +ip4:YOUR_IP ~all` |
| TXT | `_dmarc` | `v=DMARC1;p=quarantine;rua=mailto:dmarc@yourdomain.com` |

> After install: generate DKIM key in BillionMail web UI and add as DNS TXT record.

### 3. Install
```bash
bash <(curl -sSL https://raw.githubusercontent.com/mamghar001/MoeScale-BillionMail/main/one-command-install.sh)
```

### 4. Post-install
1. Open `https://YOUR_IP/adminPanel` → log in
2. Add your domain in **Domain Management**
3. Generate & add DKIM records
4. Create a mailbox
5. Test via **WebMail** at `https://YOUR_IP/roundcube`

---

## 🔧 Management Commands

```bash
cd /opt/billionmail

# Status
bash bm.sh status

# Restart all
bash bm.sh restart

# Restart specific container
docker compose restart postfix-billionmail

# View logs
docker compose logs postfix-billionmail --tail 50
docker compose logs dovecot-billionmail --tail 50
```

---

## ⚠️ Gmail & Hotmail Delivery

Fresh IPs may be blocked. Options:

1. **SMTP Relay (Recommended)** — set up during install (SendGrid free tier: 100/day)
2. **IP Warmup** — send 10–50 emails/day for 2–4 weeks
3. **Check blocklists:**
   - https://www.spamhaus.org/query/ip/YOUR_IP
   - https://mxtoolbox.com/blacklists.aspx

---

## 📂 Repository Structure

```
.
├── conf/                   # Config files (Postfix, Dovecot, Rspamd)
├── core/                   # BillionMail core application
├── one-command-install.sh  # ⭐ One-command installer (use this)
├── install.sh              # Base installer (called by one-command)
├── bm.sh                   # Management script
├── docker-compose.yml      # Docker services
└── README.md               # This file
```

---

## 📚 Documentation

- **[NOEZ_SETUP.md](NOEZ_SETUP.md)** — Noez GRE tunnel setup guide
- **[SKILLS.md](SKILLS.md)** — Full architecture, troubleshooting, and AI agent knowledge base

---

## 📝 License

MIT License — see original [BillionMail](https://github.com/BillionMail/BillionMail) repository for details.
