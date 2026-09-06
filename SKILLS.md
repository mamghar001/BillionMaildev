# BillionMail Noez GRE Tunnel - Complete AI Agent Knowledge Base

> **⚠️ CRITICAL: READ THIS ENTIRE FILE BEFORE MODIFYING ANYTHING**
> 
> This document contains ALL knowledge gained from 20+ hours of debugging the Noez GRE tunnel integration. Missing any section will likely cause you to repeat our mistakes.

---

## 📋 TABLE OF CONTENTS

1. [Project Overview](#1-project-overview)
2. [Complete Architecture](#2-complete-architecture)
3. [All Project Files](#3-all-project-files)
4. [Configuration Deep Dive](#4-configuration-deep-dive)
5. [Complete Setup Process](#5-complete-setup-process)
6. [ALL Bugs & Solutions (Chronological)](#6-all-bugs--solutions-chronological)
7. [Mailbox Creation Tool](#7-mailbox-creation-tool)
8. [Troubleshooting Decision Trees](#8-troubleshooting-decision-trees)
9. [Emergency Recovery Procedures](#9-emergency-recovery-procedures)
10. [Testing & Verification](#10-testing--verification)
11. [Integration Points](#11-integration-points)
12. [Command Reference](#12-command-reference)
13. [Common Pitfalls](#13-common-pitfalls)
14. [Noez Blacklist Fix Deep Dive](./NOEZ_BLACKLIST_FIX.md)
15. [Dynamic Sending & Jitter Plan](./DYNAMIC_SENDING_PLAN.md)
16. [How to Rebuild & Redeploy Backend Code](#16-how-to-rebuild--redeploy-backend-code)
17. [How to Create & Schedule Outbound Campaigns](#17-how-to-create--schedule-outbound-campaigns)
18. [Deliverability Protection & Dynamic Limits](#18-deliverability-protection--dynamic-limits)
19. [Advanced Template Syntax & Spintax Mandates](#19-advanced-template-syntax--spintax-mandates)
20. [Telegram Bot Daemon & Daily Cron Audits](#20-telegram-bot-daemon--daily-cron-audits)
21. [Mailbox Migration & Rebuild Procedures](#21-mailbox-migration--rebuild-procedures)
22. [Automated Deliverability & Authentication Testing (aboutmy.email)](#22-automated-deliverability--authentication-testing-aboutmyemail)

---

## 1. PROJECT OVERVIEW

### What This Project Does

Integrates **Noez GRE tunnel service** with **BillionMail** to allow sending emails from dedicated Noez IPs through a GRE tunnel.

### Why GRE Tunnel?

- Noez provides clean IP addresses for email sending
- GRE tunnel routes traffic through Noez network
- Container binds to Noez IPs for source IP control
- Postfix uses specific IPs per domain

### Components Involved

1. **Host VPS** - Runs Docker, GRE tunnel, iptables rules
2. **GRE Tunnel** - Connects to Noez (gre1 interface)
3. **Docker Container** - BillionMail Postfix
4. **Noez Network** - Provides clean IP reputation
5. **Cloudflare** - DNS management (optional)

---

## 2. COMPLETE ARCHITECTURE

### Network Flow (Detailed)

```
OUTBOUND EMAIL FLOW:
====================

1. User sends email via BillionMail UI
   ↓
2. BillionMail core → Postfix container
   (via internal Docker network 172.66.1.x)
   ↓
3. Postfix determines transport based on sender domain
   - Looks up domain in bm_domain_smtp_transport table
   - Finds: @domain.com → smtp_bind_ip_5_230_168_10
   ↓
4. Postfix uses transport with smtp_bind_address
   - Binds to 5.230.168.10 on container lo interface
   ↓
5. Packet leaves container via eth0 (172.66.2.100)
   - Container routing: from 5.230.168.10 → table 100
   - Table 100 default via 172.66.2.1 (Docker bridge)
   ↓
6. Host receives packet on Docker bridge (br-825cda742c28)
   - Host sees source IP: 5.230.168.10
   - iptables SNAT not needed (source is already correct)
   ↓
7. Host routing: from 5.230.168.10 → table 20
   - Table 20: default via 192.168.31.1 dev gre1
   ↓
8. Packet enters GRE tunnel
   - Encapsulated in GRE header
   - Sent to Noez endpoint (5.230.205.35)
   ↓
9. Noez network routes to destination
   - Destination sees source: 5.230.168.10
   ↓
10. Email delivered ✓


REPLY/INBOUND FLOW:
===================

1. Remote server replies to 5.230.168.10
   ↓
2. Noez network receives reply
   ↓
3. GRE tunnel delivers to host
   - Host sees packet for 5.230.168.10
   ↓
4. CRITICAL: Host routing decision
   
   WRONG (causes failure):
   - ip route show table local → local 5.230.168.10 dev gre1
   - Host thinks IP is LOCAL, processes packet itself
   - Packet never reaches container!
   
   CORRECT (what we need):
   - ip route show → 5.230.168.10 dev br-825cda742c28
   - Host forwards packet to Docker bridge
   ↓
5. Docker bridge delivers to container
   - Container receives reply on eth0
   - Routing delivers to application
   ↓
6. Postfix receives reply ✓
```

### Component Relationships

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              HOST VPS                                    │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                     GRE TUNNEL (gre1)                            │   │
│  │  ┌─────────────────────────────────────────────────────────┐   │   │
│  │  │ IPs bound to interface:                                  │   │   │
│  │  │   • 192.168.31.2/30 (tunnel local)                      │   │   │
│  │  │   • 5.230.168.0/32 (Noez IP 1)                          │   │   │
│  │  │   • 5.230.168.1/32 (Noez IP 2)                          │   │   │
│  │  │   • 5.230.168.2/32 (Noez IP 3)                          │   │   │
│  │  │   • 5.230.168.10/32 (Noez IP 4)                         │   │   │
│  │  │   • 5.230.168.11/32 (Noez IP 5)                         │   │   │
│  │  │   • 5.230.168.12/32 (Noez IP 6)                         │   │   │
│  │  └─────────────────────────────────────────────────────────┘   │   │
│  │  Tunnel endpoint: 5.230.205.35                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                              │                                           │
│                              │ GRE tunnel interface                      │
│                              │                                           │
│  ┌───────────────────────────┼───────────────────────────────────────┐ │
│  │                           │    HOST NETWORKING                     │ │
│  │  ┌──────────────────────┴─────────────────────────────────────┐  │ │
│  │  │ Routing Tables:                                              │  │ │
│  │  │   • Main table: default via VPS gateway                     │  │ │
│  │  │   • Table 20: default via 192.168.31.1 (for Noez IPs)       │  │ │
│  │  │   • ip rule: from 5.230.168.x lookup 20                     │  │ │
│  │  └─────────────────────────────────────────────────────────────┘  │ │
│  │                                                                     │ │
│  │  ┌─────────────────────────────────────────────────────────────┐   │ │
│  │  │ iptables Rules:                                              │   │ │
│  │  │   • FORWARD: ACCEPT for 5.230.168.x (both directions)       │   │ │
│  │  │   • NAT: Not needed for source (already correct)            │   │ │
│  │  └─────────────────────────────────────────────────────────────┘   │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                              │                                           │
│                              │ Docker bridge                             │
│                              │ (br-825cda742c28)                        │
│                              │                                           │
│  ┌───────────────────────────┴───────────────────────────────────────┐ │
│  │                         DOCKER CONTAINER                           │ │
│  │              (billionmail-postfix-billionmail-1)                   │ │
│  │                                                                    │ │
│  │  ┌──────────────────────────────────────────────────────────────┐ │ │
│  │  │ Container Interfaces:                                         │ │ │
│  │  │   • eth0: 172.66.2.100/24 (Docker network)                   │ │ │
│  │  │   • eth1: 172.66.1.100/24 (BillionMail internal)             │ │ │
│  │  │   • lo: 127.0.0.1 + Noez IPs as aliases                      │ │ │
│  │  │          - 5.230.168.0/32                                     │ │ │
│  │  │          - 5.230.168.1/32                                     │ │ │
│  │  │          - 5.230.168.2/32                                     │ │ │
│  │  │          - 5.230.168.10/32                                    │ │ │
│  │  │          - 5.230.168.11/32                                    │ │ │
│  │  │          - 5.230.168.12/32                                    │ │ │
│  │  └──────────────────────────────────────────────────────────────┘ │ │
│  │                                                                     │ │
│  │  ┌──────────────────────────────────────────────────────────────┐  │ │
│  │  │ Container Routing:                                            │  │ │
│  │  │   • ip rule: from 5.230.168.x lookup 100                     │  │ │
│  │  │   • table 100: default via 172.66.2.1                        │  │ │
│  │  └──────────────────────────────────────────────────────────────┘  │ │
│  │                                                                     │ │
│  │  ┌──────────────────────────────────────────────────────────────┐  │ │
│  │  │ Postfix Configuration:                                        │  │ │
│  │  │   master.cf:                                                 │  │ │
│  │  │     smtp_bind_ip_5_230_168_0 unix - - n - - smtp            │  │ │
│  │  │       -o smtp_bind_address=5.230.168.0                       │  │ │
│  │  │     smtp_bind_ip_5_230_168_1 unix - - n - - smtp            │  │ │
│  │  │       -o smtp_bind_address=5.230.168.1                       │  │ │
│  │  │     ...                                                      │  │ │
│  │  │                                                              │  │ │
│  │  │   Database:                                                  │  │ │
│  │  │     bm_domain_smtp_transport:                                │  │ │
│  │  │       @domain1.com → smtp_bind_ip_5_230_168_0               │  │ │
│  │  │       @domain2.com → smtp_bind_ip_5_230_168_1               │  │ │
│  │  └──────────────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 3. ALL PROJECT FILES

### Core Noez Files (User Focused)

| File | Purpose | Who Edits | Who Runs |
|------|---------|-----------|----------|
| `noez_setup.sh` | **MAIN SCRIPT** - Does everything | Never | Admin (sudo) |
| `noez_setup.env` | **PRIVATE CONFIG** - IPs, tokens | Admin | Sourced by main script |
| `noez_setup.env.example` | Template for noez_setup.env | AI dev | Reference only |
| `NOEZ_SETUP.md` | User documentation | AI dev | Reference only |
| `setup_noez_ips.sh` | Boot helper (auto-generated) | Never | systemd (auto) |
| `SKILLS.md` | This file - AI knowledge base | AI dev | AI agents must read |

### BillionMail Core Files (Integration Points)

| File | Purpose | Modified By |
|------|---------|-------------|
| `conf/postfix/master.cf` | Postfix transports | noez_setup.sh |
| `conf/postfix/main.cf` | Main Postfix config | BillionMail install |
| `docker-compose.yml` | Container orchestration | BillionMail install |
| `.env` | DB credentials | BillionMail install |
| `data/postgresql/` | Database files | Runtime |
| `logs/postfix/mail.log` | Email logs | Runtime |

### Auto-Generated/Runtime Files

| File | Purpose | Created By |
|------|---------|------------|
| `/etc/systemd/system/noez-ips.service` | Boot service | noez_setup.sh |
| `postfix-data/pid/unix.smtp_bind_ip_*` | Transport sockets | Postfix runtime |
| `core-data/session/billion-mail/` | Telegram sessions | BillionMail runtime |

---

## 4. CONFIGURATION DEEP DIVE

### noez_setup.env - All Options Explained

```bash
# =============================================================================
# REQUIRED FIELDS (Must be filled)
# =============================================================================

# NOEZ_IP
# The specific Noez IP you want to use for this domain
# Format: x.x.x.x
# Get from: Noez control panel
# Example: NOEZ_IP="5.230.168.0"
NOEZ_IP=""

# HOST_IP  
# Your VPS public IP address (the one Noez creates GRE tunnel to)
# Format: x.x.x.x
# Get from: curl ifconfig.me or VPS dashboard
# Example: HOST_IP="85.121.241.162"
HOST_IP=""

# NOEZ_GRE_REMOTE
# Noez GRE tunnel endpoint IP
# Format: x.x.x.x
# Get from: Noez control panel (GRE tunnel section)
# Example: NOEZ_GRE_REMOTE="5.230.205.35"
NOEZ_GRE_REMOTE=""

# DOMAIN
# The domain you'll send emails from
# Format: domain.com
# Must: Have DNS managed by you (Cloudflare recommended)
# Example: DOMAIN="mydomain.com"
DOMAIN=""

# ALL_NOEZ_IPS
# ALL Noez IPs you own (space-separated)
# Used by: systemd service for auto-setup on boot
# Format: "ip1 ip2 ip3 ..."
# Example: ALL_NOEZ_IPS="5.230.168.0 5.230.168.1 5.230.168.2"
ALL_NOEZ_IPS=""

# =============================================================================
# OPTIONAL FIELDS (But highly recommended)
# =============================================================================

# CF_API_TOKEN
# Cloudflare API token for automatic DNS
# Permissions needed: Zone:Read, DNS:Edit
# Get from: https://dash.cloudflare.com/profile/api-tokens
# If empty: Manual DNS setup required
CF_API_TOKEN=""

# CF_ZONE_ID
# Cloudflare Zone ID (auto-detected if empty)
# Get from: Cloudflare domain overview page (bottom right)
CF_ZONE_ID=""

# =============================================================================
# ADVANCED FIELDS (Usually auto-detected)
# =============================================================================

# CONTAINER_NAME
# Docker container name for Postfix
# Default: billionmail-postfix-billionmail-1
# Only change if: Custom Docker setup
CONTAINER_NAME="billionmail-postfix-billionmail-1"

# DOCKER_SUBNET
# Docker network subnet
# Default: 172.66.2.0/24
# Auto-detected from: ip route | grep 172.66
DOCKER_SUBNET="172.66.2.0/24"

# GRE_LOCAL
# Local IP for GRE tunnel (your side)
# Default: 192.168.31.2
# Only change if: Noez provides different
GRE_LOCAL="192.168.31.2"

# GRE_REMOTE
# Remote IP for GRE tunnel (Noez side)
# Default: 192.168.31.1
# Only change if: Noez provides different
GRE_REMOTE="192.168.31.1"
```

### Configuration Validation Rules

```bash
# All REQUIRED fields must be non-empty
# IP addresses must be valid IPv4
# DOMAIN must not include protocol (no https://)
# ALL_NOEZ_IPS must include NOEZ_IP
```

---

## 5. COMPLETE SETUP PROCESS

### Phase 1: Validation (noez_setup.sh)

```bash
1. Check running as root
2. Load .env file
3. Validate NOEZ_IP, HOST_IP, NOEZ_GRE_REMOTE, DOMAIN
4. If interactive: prompt for missing values
5. If non-interactive: fail with error
6. Show configuration summary
7. Get user confirmation
```

### Phase 2: Docker Bridge Detection

```bash
1. Get container network info from Docker
2. Try to find bridge interface:
   a. Look for network with "b2bscale" or "net-" in name
   b. Extract IP from container networks
   c. Find bridge from routing table
3. Fallback: Try common bridge names (br-*, br-billionmail, docker0)
4. Set DOCKER_BRIDGE, DOCKER_BRIDGE_GW, CONTAINER_NET_NS_IP
5. Fail if cannot detect
```

### Phase 3: GRE Tunnel Setup

```bash
1. Check if gre1 exists
2. If exists and has our IP: skip
3. If exists but different: ask to recreate
4. Create tunnel:
   ip tunnel add gre1 mode gre local $HOST_IP remote $NOEZ_GRE_REMOTE ttl 255
5. Add addresses:
   ip addr add $GRE_LOCAL/30 dev gre1
   ip addr add $NOEZ_IP/32 dev gre1
6. Bring up:
   ip link set gre1 up
7. Add routing policy:
   ip rule add from $NOEZ_IP table 20 prio 200
   ip route add default via $GRE_REMOTE dev gre1 table 20
8. Test: ping -I $NOEZ_IP 8.8.8.8
```

### Phase 4: Cloudflare DNS Setup

```bash
1. Skip if CF_API_TOKEN not set
2. Find Zone ID (if not provided)
3. Delete old SPF records (cleanup duplicates)
4. Delete old DMARC records (cleanup duplicates)
5. Create/Update A record: mail.DOMAIN → HOST_IP
6. Create SPF: v=spf1 ip4:NOEZ_IP ~all
7. Create DMARC: v=DMARC1; p=quarantine; rua=mailto:dmarc@DOMAIN
8. Report results
```

### Phase 5: BillionMail Domain Setup

```bash
1. Check if domain exists in 'domain' table
2. If not: INSERT INTO domain (...)
3. Add/update bm_multi_ip_domain entry
4. Show domain in BillionMail UI
```

### Phase 6: Container Networking

```bash
1. Get container PID
2. Add IP to container loopback:
   nsenter -t $PID -n ip addr add $NOEZ_IP/32 dev lo
3. Add container routing:
   nsenter -t $PID -n ip rule add from $NOEZ_IP table 100
   nsenter -t $PID -n ip route add default via $DOCKER_BRIDGE_GW table 100
```

### Phase 7: Host Routing

```bash
1. Add forwarding rules:
   iptables -I FORWARD -s $NOEZ_IP -j ACCEPT
   iptables -I FORWARD -d $NOEZ_IP -j ACCEPT

2. CRITICAL: Fix local route issue
   # Delete local route (prevents host from intercepting replies)
   ip route del table local $NOEZ_IP dev gre1
   
   # Add route via bridge to container
   ip route add $NOEZ_IP dev $DOCKER_BRIDGE

3. Flush route cache
```

### Phase 8: Postfix Configuration

```bash
1. Check if transport exists in master.cf
2. If exists without smtp_bind_address:
   - Add: -o smtp_bind_address=$NOEZ_IP
3. If not exists:
   - Append transport with smtp_bind_address
4. Update database:
   INSERT/UPDATE bm_domain_smtp_transport
5. Restart Postfix container (not reload - need restart for new transports)
6. Wait 3 seconds
```

### Phase 9: Systemd Service Setup

```bash
1. Create /opt/billionmail/setup_noez_ips.sh
2. Create /etc/systemd/system/noez-ips.service
3. systemctl daemon-reload
4. systemctl enable noez-ips.service
5. systemctl start noez-ips.service
```

### Phase 10: Testing

```bash
1. Test container internet connectivity:
   nsenter -t $PID -n ping -c 3 8.8.8.8

2. Test DNS resolution:
   nsenter -t $PID -n nslookup google.com

3. Report results
```

---

## 6. ALL BUGS & SOLUTIONS (CHRONOLOGICAL)

### Bug #1: Wrong Source IP (CRITICAL)

**Date Discovered:** 2026-03-30
**Severity:** CRITICAL - Emails sent from wrong IP

**Symptom:**
```
Mail-tester shows:
"Your IP address 5.230.168.12 is associated with the domain 11.0-255.168.230.5.in-addr.arpa.
Nevertheless your message appears to be sent from mail.b2bscale.xyz"
```

**Root Cause:**
Postfix transport created WITHOUT `smtp_bind_address` option. Postfix uses default IP.

**How to Detect:**
```bash
grep "smtp_bind_ip" conf/postfix/master.cf
```

**Problem Output:**
```
smtp_bind_ip_5_230_168_10 unix - - n - - smtp
# No -o smtp_bind_address line!
```

**Solution:**
```bash
# Add the bind address to transport
sed -i '/^smtp_bind_ip_5_230_168_10 unix/a\  -o smtp_bind_address=5.230.168.10' conf/postfix/master.cf

# Verify
grep -A1 "smtp_bind_ip_5_230_168_10" conf/postfix/master.cf
# Should show:
# smtp_bind_ip_5_230_168_10 unix - - n - - smtp
#   -o smtp_bind_address=5.230.168.10

# Restart Postfix
docker restart billionmail-postfix-billionmail-1
```

**Code Fix Applied:**
Modified `setup_postfix()` to always include `-o smtp_bind_address=$NOEZ_IP`

---

### Bug #2: No Reply Packets (CRITICAL)

**Date Discovered:** 2026-03-30
**Severity:** CRITICAL - No bidirectional connectivity

**Symptom:**
```
Container can send ping but gets no replies:
--- 8.8.8.8 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss
```

**Root Cause:**
When adding IP to GRE tunnel, kernel creates LOCAL route:
```
local 5.230.168.10 dev gre1 scope host
```

Host thinks IP belongs to itself, intercepts reply packets, drops them (no process listening).

**How to Detect:**
```bash
ip route show table local | grep 5.230.168.10
# Shows: local 5.230.168.10 dev gre1 scope host ← BAD!

# Should be:
ip route | grep 5.230.168.10
# Shows: 5.230.168.10 dev br-825cda742c28 scope link ← GOOD!
```

**Solution:**
```bash
# Delete local route
ip route del table local 5.230.168.10 dev gre1

# Add route to container via bridge
ip route add 5.230.168.10 dev br-825cda742c28

# Verify
ip route get 5.230.168.10
# Should show: 5.230.168.10 dev br-825cda742c28 src 172.66.2.1
```

**Code Fix Applied:**
Added to `setup_host_routing()`:
```bash
ip route del table local $NOEZ_IP dev gre1 2>/dev/null || true
ip route add $NOEZ_IP dev $DOCKER_BRIDGE 2>/dev/null || true
```

---

### Bug #3: Docker Bridge Detection Failure

**Date Discovered:** 2026-03-30
**Severity:** HIGH - Script fails on fresh install

**Symptom:**
```
Could not detect Docker bridge!
Please set DOCKER_BRIDGE manually in noez_setup.env
```

**Root Cause:**
Container has TWO networks:
- 172.66.2.100 (b2bscale network - for Noez)
- 172.66.1.100 (billionmail network - internal)

Script only looked for specific names, didn't handle multiple networks.

**How to Detect:**
```bash
# Check container networks
docker inspect billionmail-postfix-billionmail-1 --format='{{range $k,$v := .NetworkSettings.Networks}}{{$k}}:{{$v.IPAddress}} {{end}}'
# Output: billionmail_billionmail-net-b2bscale:172.66.2.100 billionmail_billionmail-network:172.66.1.100
```

**Solution:**
Rewrote `detect_docker_bridge()` to:
1. Look for network with "b2bscale" or "net-" in name
2. Extract IP from that network
3. Find bridge from routing table
4. Fallback to trying common bridge names

---

### Bug #4: IP Not Added to GRE Tunnel on 'add' Command

**Date Discovered:** 2026-03-30
**Severity:** MEDIUM - Adding new IP/domain fails

**Symptom:**
```
Running: noez_setup.sh add 5.230.168.12 newdomain.com
Email sends from wrong IP or fails
```

**Root Cause:**
`add_new_ip()` function skipped adding IP to GRE tunnel - only added to container.

**Solution:**
Modified `add_new_ip()` to call GRE tunnel setup first.

---

### Bug #5: Systemd Service Missing Host Routing

**Date Discovered:** 2026-03-30
**Severity:** MEDIUM - Reboot breaks connectivity

**Symptom:**
After VPS reboot, emails fail until manually running setup script.

**Root Cause:**
`setup_systemd_service()` created script that only added IPs to container, didn't fix host routes.

**Solution:**
Rewrote generated `setup_noez_ips.sh` to:
1. Detect bridge automatically
2. Delete local routes
3. Add routes via bridge
4. Re-add container IPs

---

### Bug #6: iptables Mangle Rules Conflicting

**Date Discovered:** 2026-03-30
**Severity:** MEDIUM - Packet marking conflicts

**Symptom:**
Complex iptables rules not working, packets bypassing SNAT.

**Root Cause:**
Tried to use packet marking (mark 0x64) + SNAT by mark + Docker MASQUERADE rules.
Too complex, rules in wrong order.

**Solution:**
Simplified to source-based SNAT only:
```bash
# Deleted complex mangle rules
# Deleted mark-based SNAT
# Kept simple source-based forwarding
iptables -I FORWARD -s $NOEZ_IP -j ACCEPT
iptables -I FORWARD -d $NOEZ_IP -j ACCEPT
```

---

### Bug #7: Postfix Hostname 'localhost' Warning

**Date Discovered:** 2026-04-03
**Severity:** MEDIUM - Affects SMTP EHLO and causes installer warnings

**Symptom:**
```
⚠️ Postfix hostname is 'localhost' (expected 'yourdomain.com')
```

**Root Cause:**
The internal BillionMail installer resets `myhostname` in `conf/postfix/main.cf` to `localhost` or a generic value during initialization.

**How to Detect:**
```bash
grep "^myhostname =" conf/postfix/main.cf
```

**Solution:**
```bash
# Update main.cf with the correct domain
sed -i "s/^myhostname = .*/myhostname = yourdomain.com/" conf/postfix/main.cf

# Restart Postfix
docker restart billionmail-postfix-billionmail-1
```

**Code Fix Applied:**
Added to `enforce_sql_passwords()` in the one-command installer to automatically align `myhostname` with `$MAIN_DOMAIN` during the final stabilization phase.

---

### Bug #8: Split-Brain Password Auth Failure (CRITICAL)

**Date Discovered:** 2026-04-03
**Severity:** CRITICAL - All SMTP sending fails

**Symptom:**
```
Postfix logs show:
"FATAL: password authentication failed for user 'billionmail'"
"451 4.3.0 <recipient>: Temporary lookup failure"
```

**Root Cause:**
The BillionMail internal installer overwrites some Postfix SQL map files (e.g., `pgsql_sender_transport_maps.cf`) with hardcoded or mismatched passwords, while others retain the correct `.env` password. This creates a "split-brain" state where only some lookups fail.

**How to Detect:**
```bash
grep "^password =" conf/postfix/sql/pgsql_*.cf
# Compare if all passwords match the DBPASS in your .env file
```

**Solution:**
```bash
# Force-sync ALL SQL map files
DBPASS=$(grep '^DBPASS=' .env | cut -d'=' -f2)
find conf/postfix/sql/ -name 'pgsql_*.cf' -exec sed -i "s/^password = .*/password = $DBPASS/" {} +

# Restart Postfix
docker restart billionmail-postfix-billionmail-1
```

**Code Fix Applied:**
Implemented a `Final Stabilization` sweep in `one-command-install.sh` that iterates through ALL Postfix and Groupware SQL configuration files to enforce password consistency before finishing the installation.

---

### Bug #9: SQL Schema Mismatch - bm_multi_ip_domain (CRITICAL)

**Date Discovered:** 2026-04-08
**Severity:** CRITICAL - Domains not showing IPs in dashboard

**Symptom:**
```
- IPs not showing in BillionMail domain dashboard
- Domain appears in UI but without IP assignment
- Emails bounce or fail to send
- Script runs without error but domain setup incomplete
```

**Root Cause:**
BillionMail v4.9.0 changed `bm_multi_ip_domain` table schema from 3 columns to 12 columns:

**OLD Schema (v4.8.x and earlier):**
```sql
domain | ip | in_use
```

**NEW Schema (v4.9.0+):**
```sql
domain | outbound_ip | network_name | subnet | postfix_ip | aliases | smtp_server_name | active | create_time | update_time | status
```

**How to Detect:**
```bash
# Check table schema
docker exec -i billionmail-postfix-billionmail-1 psql -U billionmail -d billionmail -c "\d bm_multi_ip_domain"

# Check if insert failed silently
docker exec -i billionmail-postfix-billionmail-1 psql -U billionmail -d billionmail -c "SELECT * FROM bm_multi_ip_domain WHERE domain='yourdomain.com'"
```

**Solution:**
```bash
# Use correct SQL with all 12 columns
docker exec -i billionmail-postfix-billionmail-1 psql -U billionmail -d billionmail -c \
    "INSERT INTO bm_multi_ip_domain (domain, outbound_ip, network_name, subnet, postfix_ip, aliases, smtp_server_name, active, create_time, update_time, status) 
     VALUES ('domain.com', '5.230.168.X', 'noez', '5.230.0.0/16', '5.230.168.X', '', 'mail', 1, $(date +%s), $(date +%s), 'active') 
     ON CONFLICT (domain, outbound_ip) DO UPDATE SET 
        outbound_ip='5.230.168.X', 
        postfix_ip='5.230.168.X',
        network_name='noez',
        subnet='5.230.0.0/16',
        update_time=$(date +%s), 
        status='active';"
```

**Code Fix Applied:**
Modified `add_domain_to_billionmail()` in `noez_setup.sh` to use the new 12-column schema with proper `ON CONFLICT` clause.

---

### Bug #10: Double DKIM Signatures - Invalid DKIM (CRITICAL)

**Date Discovered:** 2026-04-08
**Severity:** CRITICAL - DKIM validation fails

**Symptom:**
```
Mail-tester shows:
"DKIM_INVALID - DKIM or DK signature exists, but is not valid"
"You have more than one DKIM signature in your message"

DKIM checks show TWO signatures:
- d=growthwithai.store; s=default
- d=growthwithai.store; s=short
```

**Root Cause:**
BillionMail generates TWO DKIM selectors by default:
- `default` - Full 2048-bit key (392 characters)
- `short` - Shorter key for compatibility

When both are configured in `dkim_signing.conf`, rspamd signs with BOTH, but DNS only has one record. The extra signature fails validation.

**How to Detect:**
```bash
# Check how many selectors per domain
cat conf/rspamd/local.d/dkim_signing.conf | grep -A10 "yourdomain.com"

# If you see TWO "path:" entries under selectors[], that's the problem
```

**Solution:**
```bash
# Edit dkim_signing.conf and remove the "short" selector
# Keep only "default" selector for each domain

# Or programmatically remove short selectors:
sed -i '/path: ".*short.private";/,/selector: "short";/d' conf/rspamd/local.d/dkim_signing.conf

# Restart rspamd
docker restart billionmail-rspamd-billionmail-1
```

**Code Fix Applied:**
Modified rspamd `dkim_signing.conf` to only use `default` selector (removed all `short` entries).

---

### Bug #11: Truncated DKIM Keys in DNS (CRITICAL)

**Date Discovered:** 2026-04-08
**Severity:** CRITICAL - DKIM validation fails

**Symptom:**
```
Mail-tester shows:
"DKIM_INVALID - DKIM or DK signature exists, but is not valid"

DNS record shows partial key:
"v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxtTFjoAJqCJs7O8HhW+YjWia0bkgR/jhuc8q3tJV6XeXzj+bS9jH442BlYfi20ZTsnc8wq6zfWBGcmXxvJtfyELF9DEA50O5enp2Wano3SVBJVjqX8CtacSacfE4CTMDmqfQ4l3PSXhZWtN5sOkoXDOTxxGDsHQ4C7pwW31PuRSqPIJAsAw7T41jh6GmvPbe3"
```

**Root Cause:**
DKIM public keys in rspamd are stored in multi-line format (split across lines for DNS record formatting). The extraction function only grabbed the first line.

**DKIM Key File Format:**
```
default._domainkey IN TXT ( "v=DKIM1; k=rsa; "
	"p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxtTFjoAJqCJs7O8HhW+YjWia0bkgR/jhuc8q3tJV6XeXzj+bS9jH442BlYfi20ZTsnc8wq6zfWBGcmXxvJtfyELF9DEA50O5enp2Wano3SVBJVjqX8CtacSacfE4CTMDmqfQ4l3PSXhZWtN5sOkoXDOTxxGDsHQ4C7pwW31PuRSqPIJAsAw7T41jh6GmvPbe3"
	"n4TPcwsd2F3FMRMj"
) ;
```

The old extraction only got:
- `MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxtTFjoAJqCJs7O8HhW+YjWia0bkgR/jhuc8q3tJV6XeXzj+bS9jH442BlYfi20ZTsnc8wq6zfWBGcmXxvJtfyELF9DEA50O5enp2Wano3SVBJVjqX8CtacSacfE4CTMDmqfQ4l3PSXhZWtN5sOkoXDOTxxGDsHQ4C7pwW31PuRSqPIJAsAw7T41jh6GmvPbe3` (253 chars)

Should be:
- `MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxtTFjoAJqCJs7O8HhW+YjWia0bkgR/jhuc8q3tJV6XeXzj+bS9jH442BlYfi20ZTsnc8wq6zfWBGcmXxvJtfyELF9DEA50O5enp2Wano3SVBJVjqX8CtacSacfE4CTMDmqfQ4l3PSXhZWtN5sOkoXDOTxxGDsHQ4C7pwW31PuRSqPIJAsAw7T41jh6GmvPbe3n4TPcwsd2F3FMRMj` (392 chars)

**How to Detect:**
```bash
# Check DKIM key length
docker exec billionmail-rspamd-billionmail-1 cat /var/lib/rspamd/dkim/yourdomain.com/default.pub | grep -o 'p=[^"]*' | sed 's/p=//' | tr -d '\n' | wc -c
# Should be 392 characters
# If 253, it's truncated!
```

**Solution:**
```bash
# Use Python to extract full multi-line key
docker exec billionmail-rspamd-billionmail-1 cat /var/lib/rspamd/dkim/yourdomain.com/default.pub | python3 -c '
import sys, re
content = sys.stdin.read()
key_parts = []
lines = content.split("\n")
capturing = False
for line in lines:
    line = line.strip()
    if "p=" in line:
        capturing = True
        match = re.search(r"p=([^\"]+)\"", line)
        if match:
            key_parts.append(match.group(1))
    elif capturing and line.startswith("\"") and not line.startswith("\"v="):
        match = re.search(r"\"([^\"]+)\"", line)
        if match:
            key_parts.append(match.group(1))
    elif capturing and (")" in line or line.endswith(");")):
        break
print("".join(key_parts))
'
```

**Code Fix Applied:**
Rewrote `get_dkim_public_key()` function in `noez_setup.sh` to use Python for proper multi-line DKIM key extraction.

---

### Bug #12: Incomplete DNS Record Cleanup

**Date Discovered:** 2026-04-08
**Severity:** MEDIUM - Duplicate/conflicting DNS records

**Symptom:**
```
- Multiple A records for mail.domain.com
- Multiple SPF records causing validation issues
- Old DKIM records conflicting with new ones
```

**Root Cause:**
Original `setup_cloudflare_dns()` function only updated records (PUT) if they existed, or created new ones. It didn't delete old records first, leading to duplicates when:
- Changing VPS IP
- Updating SPF IP ranges
- Re-adding domains

**Solution:**
```bash
# For each record type, DELETE ALL existing before creating new:

# 1. Delete ALL old A records
records=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=mail.$DOMAIN" ...)
echo "$records" | python3 -c "import sys,json; d=json.load(sys.stdin); [print(r['id']) for r in d.get('result', [])]" | while read id; do
    curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$id" ...
done

# 2. Create fresh A record
curl -s -X POST "..." -d '{"type":"A","name":"mail.'$DOMAIN'","content":"'$HOST_IP'"...'

# Repeat for SPF, DMARC, DKIM
```

**Code Fix Applied:**
Modified `setup_cloudflare_dns()` in `noez_setup.sh` to:
1. Delete ALL existing A records for mail.$DOMAIN
2. Delete ALL existing SPF records for $DOMAIN
3. Delete ALL existing DMARC records for _dmarc.$DOMAIN
4. Delete ALL existing DKIM records for default._domainkey.$DOMAIN
5. Then create fresh records

---


### Bug #13: Missing A Record for Blacklist Checking

**Date Discovered:** 2026-04-08
**Severity:** MEDIUM - Blacklist check fails

**Symptom:**
```
- Clicking "Check Blacklist" on domain shows "The ARecord field is required"
- Or checks wrong IP (VPS IP instead of Noez IP)
- Domain table shows empty a_record field
```

**Root Cause:**
The `domain` table has an `a_record` field that BillionMail uses for:
1. Blacklist checking (what IP to check)
2. DNS validation

When adding domains via script, this field was left empty.

**How to Detect:**
```bash
# Check if A record is set
docker exec -i billionmail-postfix-billionmail-1 psql -U billionmail -d billionmail -c "
SELECT domain, a_record FROM domain WHERE a_record = '' OR a_record IS NULL;
"
```

**Solution:**
```bash
# Set A record to Noez IP for blacklist checking
docker exec -i billionmail-postfix-billionmail-1 psql -U billionmail -d billionmail -c "
UPDATE domain SET a_record='$NOEZ_IP' WHERE domain='yourdomain.com';
"
```

**Code Fix Applied:**
Modified `add_domain_to_billionmail()` in `noez_setup.sh` to:
1. Set `a_record` to `$NOEZ_IP` when inserting new domain
2. Update `a_record` to `$NOEZ_IP` when domain already exists

This ensures blacklist checks validate the correct dedicated Noez IP.

> **🔄 v4.9.2 Update:** After applying the initial Bug #13 fix (setting `a_record` to a Noez IP), three new issues emerged: (1) the API validation rejected IPs, (2) `CheckBlacklist` tried to DNS-resolve the IP string causing "resolve failed", and (3) `FormatMX` displayed the IP as a hostname in DNS records. These were fixed in `v4.9.2`. See the full technical breakdown in [`NOEZ_BLACKLIST_FIX.md`](./NOEZ_BLACKLIST_FIX.md).

### Bug #14: Mailbox Default Limit Too Low (50)

**Date Discovered:** 2026-04-08
**Severity:** LOW - UI shows 50, need 100+ mailboxes per domain

**Symptom:**
```
- Domain form shows "Mailboxes: 50" by default
- Need 100 mailboxes per domain for email campaigns
```

**Root Cause:**
Default value in API and frontend was set to 50.

**Solution:**
Updated defaults from 50 to 101 in:
- `core/api/domains/v1/domains.go` - API default
- `core/frontend/src/views/domain/components/DomainForm.vue` - Frontend default
- `core/internal/service/database_initialization/mail_serv.go` - Schema default

Also updated all existing domains:
```sql
UPDATE domain SET mailboxes = 101;
```


### Bug #15: /domains and /market/task Pages Take 3-15 Minutes to Load (MASQUERADE Missing)

**Date Discovered:** 2026-08-29
**Severity:** HIGH - Web UI unusable for 2 main pages, but other pages fine
**Affects:** Any fresh BillionMail install on a Docker host where the BM bridge network has no MASQUERADE in the host's iptables NAT POSTROUTING

**Symptom:**
- `/mail.<domain>/domain` and `/mail.<domain>/market/task` take 3-15 minutes to load (returns 200 eventually, just very slow)
- `/contacts/group`, `/mailboxes`, `/dashboard` are instant (sub-second)
- `/api/domains/list` returns 200 with EXACTLY 180s response time every call (visible in `access-YYYYMMDD.log`)
- Other list endpoints (`/api/domains/all`, `/api/mailbox/list`) work fine
- System load, disk, and database are all healthy

**Root Cause:**
The BM Go core container runs on the `br-billionmail` Docker bridge (typically `172.66.1.0/24`). When the host's iptables NAT POSTROUTING has **no MASQUERADE rule for that bridge subnet**, the container can resolve external hostnames (Docker's internal DNS forwards to host's DNS) but **outbound TCP from the container has no source NAT** — packets leave with a private source IP, the remote site can't route the response, and the connection times out at the TCP layer (~90s per attempt).

The slow path is triggered by BM's `public.GetServerIP()` function in `core/internal/service/public/common.go:2092`:
1. Checks in-memory `gcache` for key `"ServerIP"` (2-hour TTL)
2. If cache miss/expired → HTTP GET to `https://ifconfig.me/ip`
3. If that fails → HTTP GET to `https://www.aapanel.com/api/common/getClientIP`
4. **No HTTP client timeout** — waits for the Go HTTP default (~90s TCP connect × 2 retries)
5. Total: ~180s per call when both endpoints hang

`/api/domains/list` calls `service.Get()` which spawns 4 goroutines per domain in a `sync.WaitGroup`. The DNS records goroutine calls `GetRecordsInCache(domain)` which falls back to `GetARecord(d, false)`, `GetSPFRecord(d, false)`, and `GetPTRRecord(d, false)` on cache miss. All three call `public.GetServerIP()`. With 39 domains × 3 GetServerIP calls each, all hung in parallel, `wg.Wait()` blocks for ~180s.

**Why other pages are fast:** `/api/mailbox/list`, `/api/domains/all`, and the dashboard widgets never call `GetServerIP()` — they only do SQL queries. Only the DNS/SPF/PTR record generation triggers it.

**Why it "used to work":** The `ServerIP` cache lives in process memory with a 2-hour TTL. After a BM process restart, the first call populates the cache (if it succeeds). 2 hours later, the cache expires and the HTTPS call happens again — silently failing or hanging. The page becomes mysteriously slow until the next restart.

**How to Detect:**
```bash
# 1. Look for 180s response times in access log
docker exec billionmail-core-billionmail-1 grep "/api/domains/list" /opt/billionmail/core/logs/access-$(date -u +%Y%m%d).log | tail -5
# Expected: every line ends with " 180.0XX," (the exact timeout)

# 2. Test if core container can reach the internet
docker exec billionmail-core-billionmail-1 python3 -c "import socket; s=socket.socket(); s.settimeout(5); s.connect(('1.1.1.1', 443)); print('OK')"
# Should print "OK". If it times out, you have this bug.

# 3. Check for MASQUERADE on the BM bridge
iptables -t nat -S POSTROUTING | grep "172.66.1.0/24.*MASQUERADE"
# If no output, MASQUERADE is missing.

# 4. Confirm the bridge subnet
ip route | grep br-billionmail
# Should show: 172.66.1.0/24 dev br-billionmail ...
```

**Solution (one iptables rule, no code change):**
```bash
# Add MASQUERADE for the BM bridge subnet
iptables -t nat -A POSTROUTING -s 172.66.1.0/24 ! -d 172.66.1.0/24 -j MASQUERADE
```

**Verify:**
```bash
# Re-run the python test - should print "OK" within 5s
docker exec billionmail-core-billionmail-1 python3 -c "import socket; s=socket.socket(); s.settimeout(5); s.connect(('1.1.1.1', 443)); print('OK')"

# Hit the slow page
time curl -sk -H "Authorization: Bearer <jwt>" "https://5.230.29.58/api/domains/list?page=1&page_size=20"
# Should complete in <2s
```

**Make it persistent (survives reboot):**
Create `/etc/systemd/system/bm-masquerade.service`:
```ini
[Unit]
Description=Add BM container MASQUERADE for internet access
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/sbin/iptables -t nat -A POSTROUTING -s 172.66.1.0/24 ! -d 172.66.1.0/24 -j MASQUERADE
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```
Then:
```bash
systemctl enable bm-masquerade.service
```

**Why not fix in BM code instead:** The `http.Get` calls in `GetServerIP()` have no timeout context. A proper fix would be to add a 5s `http.Client{Timeout: 5*time.Second}` wrapper. But since the official BM upstream is being modified by the user (see `mamghar001/MoeScale-BillionMail` fork), and the user has explicit "no code changes" constraints on the production box, the iptables fix is the lowest-risk permanent solution that doesn't touch the Go binary.

**Why the official `noez_setup.sh` doesn't catch this:** The setup script (Phase 6: Container Networking) handles GRE tunnel NAT, /24 SNAT for outbound mail, and per-domain IP bindings — but it never adds a generic MASQUERADE for the BM bridge. The assumption is that container-to-internet works out of the box (which it does on hosts with `net.ipv4.ip_forward=1` AND Docker's default `iptables=true` in daemon.json). On hosts where the operator has explicitly disabled Docker's iptables management (e.g. `iptables=false` in `/etc/docker/daemon.json`, which is the case for this NOEZ setup because the operator manages iptables manually), Docker no longer auto-installs MASQUERADE rules, and the bridge has no outbound NAT.

**Related diagnostic steps that look like the bug but aren't:**
- High disk iowait: misleading — the chown aftermath yesterday made disk I/O look bad, but iowait is normal now
- Slow DNS resolution: misleading — DNS works fine (Docker's internal DNS forwards), it's TCP that fails
- Database locks: misleading — the goroutines don't lock the DB; they lock on `wg.Wait()` for the slow HTTPS calls
- Go runtime deadlocks: misleading — all 23 OS threads are in `futex_wait_queue_me` (normal `sync.WaitGroup` behavior), not a real deadlock

**Files modified by this fix:**
- `/etc/iptables.rules` — was missing the MASQUERADE rule (rebuilt live, not saved to file because `iptables-restore.service` is intentionally disabled on this host)
- `/etc/systemd/system/bm-masquerade.service` — created for reboot persistence

---

## 7. MAILBOX CREATION TOOL

### create_100_mailboxes.py

**Purpose:** Automatically create 100 mailboxes with USA women's names for any domain

**Location:** `/opt/create_100_mailboxes.py` (also copied to `/opt/billionmail/`)

**Features:**
- Creates 100 unique mailboxes: `firstname.lastname@domain.com`
- Uses USA white women's names (100 first names + 100 last names)
- Display names in Camel Case: "Firstname Lastname"
- Generates random 12-character passwords with special chars
- Reads API token from `.env` file (`BM_API_TOKEN`)
- Saves results to `mailboxes/` folder

**Usage:**
```bash
# Interactive mode (asks for confirmation)
python3 create_100_mailboxes.py b2bgrowth.store

# Automated mode (no confirmation)
python3 create_100_mailboxes.py b2bgrowth.store --skip-confirm
```

**Output Files:**
- `mailboxes/mailboxes_<domain>.csv` - Email, Password, Full Name
- `mailboxes/failed_mailboxes_<domain>.log` - Any failures (if any)

**Integration with noez_setup.sh:**
When running `noez_setup.sh add <IP> <domain>`, the script now asks:
```
Create 100 mailboxes for <domain>? (y/n)
```
If yes, automatically creates mailboxes after domain setup.

**Prerequisites:**
1. API token must be set in `.env`:
   ```
   BM_API_TOKEN=eyJhbGciOiJIUzI1NiIs...
   BM_API_URL=https://mail.moescale.site
   ```
2. Python 3 with `requests` module

---

## 8. TROUBLESHOOTING DECISION TREES

### Email Not Sending

```
Email not sending?
│
├─ Check: docker ps | grep postfix
│  └─ Container not running?
│     └─ cd /opt/billionmail && docker compose up -d
│
├─ Check: tail -f logs/postfix/mail.log
│  ├─ "Connection timed out"?
│  │  └─ Network issue → Check connectivity tree
│  ├─ "SPF fail"?
│  │  └─ Wrong source IP → Check Bug #1 fix
│  └─ "relay=none"?
│     └─ DNS or routing issue
│
└─ Check: ping -I 5.230.168.X 8.8.8.8
   └─ Host can't ping?
      └─ Check GRE tunnel tree
```

### Wrong Source IP (Bug #1)

```
Email sent from wrong IP?
│
├─ Check: grep -A1 "smtp_bind_ip_5_230_168_X" conf/postfix/master.cf
│  ├─ Shows "-o smtp_bind_address=X.X.X.X"?
│  │  └─ Transport OK, check database
│  │     └─ SELECT * FROM bm_domain_smtp_transport WHERE domain='@yourdomain'
│  └─ Missing smtp_bind_address?
│     └─ Fix: sed -i '/^transport_name/a\  -o smtp_bind_address=IP' conf/postfix/master.cf
│         docker restart billionmail-postfix-billionmail-1
```

### No Reply Packets (Bug #2)

```
Container can't get replies?
│
├─ Check: ip route show table local | grep 5.230.168
│  ├─ Shows "local 5.230.168.X dev gre1"?
│  │  └─ BAD! Host intercepting packets
│  │     └─ Fix: ip route del table local 5.230.168.X dev gre1
│  │              ip route add 5.230.168.X dev br-XXX
│  └─ No local routes?
│     └─ Check: ip route | grep 5.230.168
│        ├─ Shows "dev br-"?
│        │  └─ Routing OK, check iptables
│        └─ No route?
│           └─ Fix: ip route add 5.230.168.X dev br-XXX
```

### GRE Tunnel Issues

```
GRE tunnel problems?
│
├─ Check: ip link show gre1
│  └─ "Device does not exist"?
│     └─ Create: ip tunnel add gre1 mode gre local HOST_IP remote NOEZ_GRE_REMOTE ttl 255
│
├─ Check: ip addr show gre1 | grep "inet "
│  └─ Missing Noez IP?
│     └─ Add: ip addr add NOEZ_IP/32 dev gre1
│
├─ Check: ping -I NOEZ_IP 8.8.8.8
│  └─ "Network unreachable"?
│     └─ Add route: ip route add default via GRE_REMOTE dev gre1 table 20
│         Add rule: ip rule add from NOEZ_IP table 20
│
└─ Check: ip rule | grep "from NOEZ_IP"
   └─ No rule?
      └─ Add: ip rule add from NOEZ_IP table 20
```

---

## 8. EMERGENCY RECOVERY PROCEDURES

### Complete Reset (Nuclear Option)

**Use when:** Everything broken, start fresh

```bash
#!/bin/bash
# EMERGENCY RESET - Run as root

cd /opt/billionmail

# 1. Stop services
systemctl stop noez-ips.service 2>/dev/null
docker stop billionmail-postfix-billionmail-1

# 2. Remove GRE tunnel
ip link del gre1 2>/dev/null || true

# 3. Clean up routes
for IP in 5.230.168.0 5.230.168.1 5.230.168.2 5.230.168.10 5.230.168.11 5.230.168.12; do
    ip route del $IP 2>/dev/null || true
    ip route del table local $IP 2>/dev/null || true
    ip rule del from $IP 2>/dev/null || true
done
ip route flush cache

# 4. Clean up iptables (carefully!)
iptables -L FORWARD -n --line-numbers | grep "5.230.168" | awk '{print $1}' | sort -rn | while read num; do
    iptables -D FORWARD $num 2>/dev/null
done

# 5. Remove Postfix transports from master.cf
# Backup first
cp conf/postfix/master.cf conf/postfix/master.cf.backup.$(date +%Y%m%d)
# Remove Noez transport lines
sed -i '/^# Noez IP/d' conf/postfix/master.cf
sed -i '/^smtp_bind_ip_5_230_/d' conf/postfix/master.cf
sed -i '/^-o smtp_bind_address=5\.230\./d' conf/postfix/master.cf

# 6. Restart container
docker start billionmail-postfix-billionmail-1

# 7. Re-run setup
sudo bash noez_setup.sh
```

### Quick Fix After Reboot

```bash
# If emails fail after VPS reboot:
sudo bash /opt/billionmail/setup_noez_ips.sh

# Or restart the systemd service:
sudo systemctl restart noez-ips.service
```

### Fix Single Domain

```bash
# If one domain not working:
sudo bash noez_setup.sh add 5.230.168.X domain.com
```

---

## 9. TESTING & VERIFICATION

### Complete Test Suite

```bash
#!/bin/bash
# Run all tests

ERRORS=0

echo "=== TEST 1: GRE Tunnel ==="
if ip link show gre1 &>/dev/null; then
    echo "✓ GRE tunnel exists"
else
    echo "✗ GRE tunnel missing"
    ERRORS=$((ERRORS+1))
fi

echo "=== TEST 2: GRE Tunnel IPs ==="
for IP in 5.230.168.0 5.230.168.1 5.230.168.2 5.230.168.10 5.230.168.11 5.230.168.12; do
    if ip addr show gre1 | grep -q "$IP"; then
        echo "✓ $IP on GRE tunnel"
    else
        echo "✗ $IP missing from GRE tunnel"
        ERRORS=$((ERRORS+1))
    fi
done

echo "=== TEST 3: Container Running ==="
if docker ps | grep -q "billionmail-postfix"; then
    echo "✓ Container running"
else
    echo "✗ Container not running"
    ERRORS=$((ERRORS+1))
fi

echo "=== TEST 4: Container IPs ==="
CONTAINER_PID=$(docker inspect -f '{{.State.Pid}}' billionmail-postfix-billionmail-1 2>/dev/null)
for IP in 5.230.168.0 5.230.168.1 5.230.168.2 5.230.168.10 5.230.168.11 5.230.168.12; do
    if nsenter -t $CONTAINER_PID -n ip addr show lo 2>/dev/null | grep -q "$IP"; then
        echo "✓ $IP in container"
    else
        echo "✗ $IP missing from container"
        ERRORS=$((ERRORS+1))
    fi
done

echo "=== TEST 5: Host Routes ==="
for IP in 5.230.168.0 5.230.168.1 5.230.168.2 5.230.168.10 5.230.168.11 5.230.168.12; do
    if ip route | grep -q "$IP.*dev br-"; then
        echo "✓ $IP routed via bridge"
    else
        echo "✗ $IP not routed correctly"
        ERRORS=$((ERRORS+1))
    fi
done

echo "=== TEST 6: No Local Routes ==="
for IP in 5.230.168.0 5.230.168.1 5.230.168.2 5.230.168.10 5.230.168.11 5.230.168.12; do
    if ip route show table local 2>/dev/null | grep -q "local $IP"; then
        echo "✗ $IP has local route (BAD!)"
        ERRORS=$((ERRORS+1))
    else
        echo "✓ $IP no local route"
    fi
done

echo "=== TEST 7: Connectivity ==="
CONTAINER_PID=$(docker inspect -f '{{.State.Pid}}' billionmail-postfix-billionmail-1 2>/dev/null)
if nsenter -t $CONTAINER_PID -n ping -c 2 -W 5 -I 5.230.168.10 8.8.8.8 &>/dev/null; then
    echo "✓ Container can reach internet from 5.230.168.10"
else
    echo "✗ Container connectivity failed"
    ERRORS=$((ERRORS+1))
fi

echo "=== TEST 8: Postfix Transports ==="
for IP in 5.230.168.0 5.230.168.1 5.230.168.2 5.230.168.10 5.230.168.11 5.230.168.12; do
    TRANSPORT="smtp_bind_ip_$(echo $IP | tr '.' '_')"
    if grep -q "^$TRANSPORT" conf/postfix/master.cf; then
        if grep -A1 "^$TRANSPORT" conf/postfix/master.cf | grep -q "smtp_bind_address=$IP"; then
            echo "✓ $IP transport has bind address"
        else
            echo "✗ $IP transport missing bind address"
            ERRORS=$((ERRORS+1))
        fi
    else
        echo "✗ $IP transport missing"
        ERRORS=$((ERRORS+1))
    fi
done

echo "=== TEST 9: Systemd Service ==="
if systemctl is-enabled noez-ips.service &>/dev/null; then
    echo "✓ Systemd service enabled"
else
    echo "✗ Systemd service not enabled"
    ERRORS=$((ERRORS+1))
fi

echo ""
echo "========================================="
if [ $ERRORS -eq 0 ]; then
    echo "✅ ALL TESTS PASSED!"
else
    echo "❌ $ERRORS TESTS FAILED"
    exit 1
fi
```

---

## 10. INTEGRATION POINTS

### BillionMail Database

**Table: `domain`**
- Stores domains for BillionMail UI
- Script adds entry during setup

**Table: `bm_domain_smtp_transport`**
- Maps domains to Postfix transports
- Columns: atype, domain, smtp_name
- Example: ('dedicated_ip', '@domain.com', 'smtp_bind_ip_5_230_168_0')

**Table: `bm_multi_ip_domain`**
- Shows Dedicated IP in UI
- Columns: domain, ip, in_use

### Postfix Integration

**master.cf transports:**
```
# Format:
smtp_bind_ip_X_X_X_X unix - - n - - smtp
  -o smtp_bind_address=X.X.X.X
```

**sender_dependent_default_transport_maps:**
- Configured in main.cf to use PostgreSQL
- Query: `SELECT CONCAT(smtp_name, ':') FROM bm_domain_smtp_transport WHERE domain = '%s'`

### Cloudflare API

**Required Permissions:**
- Zone:Read
- DNS:Edit

**Records Created:**
- A: mail.DOMAIN → HOST_IP
- TXT: DOMAIN → v=spf1 ip4:NOEZ_IP ~all
- TXT: _dmarc.DOMAIN → v=DMARC1; p=quarantine; rua=mailto:dmarc@DOMAIN

### Systemd Integration

**Service: `noez-ips.service`**
- Type: oneshot
- Runs: `/opt/billionmail/setup_noez_ips.sh`
- After: docker.service
- Enabled: multi-user.target

---

## 11. COMMAND REFERENCE

### Essential Commands

```bash
# Full setup
sudo bash noez_setup.sh

# Add new IP/domain
sudo bash noez_setup.sh add 5.230.168.X domain.com

# Check status
sudo bash noez_setup.sh status

# Fix after reboot
sudo bash /opt/billionmail/setup_noez_ips.sh

# Restart Postfix
docker restart billionmail-postfix-billionmail-1

# View mail logs
tail -f /opt/billionmail/logs/postfix/mail.log

# Check systemd service
systemctl status noez-ips.service
```

### Container Namespace Commands

```bash
# Get container PID
CONTAINER_PID=$(docker inspect -f '{{.State.Pid}}' billionmail-postfix-billionmail-1)

# Container shell
nsenter -t $CONTAINER_PID -n /bin/bash

# Container IP addresses
nsenter -t $CONTAINER_PID -n ip addr

# Container routing
nsenter -t $CONTAINER_PID -n ip route
nsenter -t $CONTAINER_PID -n ip rule

# Test from container
nsenter -t $CONTAINER_PID -n ping -I 5.230.168.10 8.8.8.8
nsenter -t $CONTAINER_PID -n nslookup google.com
```

### Network Debugging

```bash
# GRE tunnel
ip tunnel show
gre1: gre/ip remote 5.230.205.35 local 85.121.241.162 ttl 255

ip addr show gre1
ip route show table 20
ip rule | grep "from 5.230"

# Docker
ip route | grep 172.66
docker network ls
docker inspect billionmail-postfix-billionmail-1 --format='{{json .NetworkSettings.Networks}}'

# iptables
iptables -L FORWARD -n -v | head -20
iptables -t nat -L POSTROUTING -n -v
iptables -t mangle -L PREROUTING -n -v

# Routes
ip route show table local | grep 5.230
ip route | grep 5.230
```

### Database Queries

```bash
# List domains
docker exec -i billionmail-postfix-billionmail-1 psql -U billionmail -d billionmail -c "SELECT domain FROM domain;"

# Check transport mapping
docker exec -i billionmail-postfix-billionmail-1 psql -U billionmail -d billionmail -c "SELECT * FROM bm_domain_smtp_transport;"

# Check multi-IP domains
docker exec -i billionmail-postfix-billionmail-1 psql -U billionmail -d billionmail -c "SELECT * FROM bm_multi_ip_domain;"
```

---

## 12. COMMON PITFALLS

### Pitfall #1: Running Script Without sudo

**Problem:** Script fails with permission errors  
**Solution:** Always use `sudo bash noez_setup.sh`

### Pitfall #2: Wrong Container Name

**Problem:** Script can't find container  
**Check:** `docker ps | grep postfix`  
**Fix:** Update CONTAINER_NAME in noez_setup.env

### Pitfall #3: Missing ALL_NOEZ_IPS

**Problem:** After reboot, only some IPs work  
**Cause:** systemd service doesn't know about all IPs  
**Fix:** Update ALL_NOEZ_IPS in noez_setup.env with ALL IPs

### Pitfall #4: Not Including NOEZ_IP in ALL_NOEZ_IPS

**Problem:** Current IP not re-added on boot  
**Fix:** Ensure NOEZ_IP is listed in ALL_NOEZ_IPS

### Pitfall #5: Editing Auto-Generated Files

**Problem:** Changes lost when script runs again  
**Files not to edit:**
- `setup_noez_ips.sh` (auto-generated)
- `/etc/systemd/system/noez-ips.service` (auto-generated)

**Instead:** Edit `noez_setup.sh` to change generation logic

### Pitfall #6: Multiple Domains Same IP - SPF Record

**Problem:** Adding second domain to same IP overwrites SPF  
**Current Behavior:** Script deletes old SPF, creates new one  
**Fix Needed:** Should append IP to existing SPF, not replace  
**Workaround:** Manually edit SPF in Cloudflare to include all IPs

### Pitfall #7: Cloudflare API Token Permissions

**Problem:** DNS records not created  
**Check:** Token has Zone:Read + DNS:Edit permissions  
**Not Zone:Edit alone!**

### Pitfall #8: Postfix Reload vs Restart

**Problem:** New transports not recognized  
**Cause:** `postfix reload` doesn't pick up master.cf changes  
**Solution:** Must use `docker restart` or full postfix stop/start

### Pitfall #9: BillionMail v4.9.0 Schema Changes

**Problem:** Script fails silently, domains don't show IPs in dashboard  
**Cause:** BillionMail v4.9.0 changed `bm_multi_ip_domain` from 3 columns to 12 columns  
**Old SQL:** `INSERT INTO bm_multi_ip_domain (domain, ip, in_use)`  
**New SQL:** `INSERT INTO bm_multi_ip_domain (domain, outbound_ip, network_name, subnet, postfix_ip, aliases, smtp_server_name, active, create_time, update_time, status)`  
**Fix:** See Bug #9 for complete new SQL syntax  
**Detection:** Check if IPs appear in dashboard after running script

### Pitfall #10: Double DKIM Signatures

**Problem:** DKIM validation fails with "more than one DKIM signature"  
**Cause:** rspamd configured with both `default` and `short` selectors  
**Fix:** Remove `short` selector from `dkim_signing.conf`, keep only `default`  
**Detection:** Check mail-tester.com for multiple DKIM signatures

### Pitfall #11: Truncated DKIM Keys in DNS

**Problem:** DKIM validation fails even with correct selector  
**Cause:** DKIM extraction only got first line of multi-line key (253 chars instead of 392)  
**Fix:** Use Python-based extraction to concatenate all lines  
**Detection:** Count characters in DNS DKIM record - should be 392, not 253

### Pitfall #12: Not Cleaning DNS Records Before Update

**Problem:** Multiple/conflicting DNS records  
**Cause:** Script updates records in-place instead of deleting and recreating  
**Fix:** Delete ALL existing records of each type before creating new ones  
**Applies to:** A records, SPF, DMARC, DKIM

---

## APPENDIX A: File Modification History

| Date | File | Change | Author |
|------|------|--------|--------|
| 2026-03-28 | noez_setup.sh | Initial creation | AI Agent |
| 2026-03-30 | noez_setup.sh | Add smtp_bind_address fix | AI Agent |
| 2026-03-30 | noez_setup.sh | Add host routing fix | AI Agent |
| 2026-03-30 | setup_noez_ips.sh | Add auto-detection | AI Agent |
| 2026-03-31 | SKILLS.md | Create knowledge base | AI Agent |
| 2026-04-08 | noez_setup.sh | Fix SQL schema for v4.9.0 compatibility | AI Agent |
| 2026-04-08 | noez_setup.sh | Add proper DKIM handling | AI Agent |
| 2026-04-08 | SKILLS.md | Document Bugs #9-12 | AI Agent |

---

## APPENDIX B: Version Compatibility Matrix

| BillionMail Version | noez_setup.sh Version | Notes |
|---------------------|----------------------|-------|
| v4.8.x and earlier | Before 2026-04-08 | Uses 3-column bm_multi_ip_domain |
| v4.9.0+ | 2026-04-08+ | Uses 12-column bm_multi_ip_domain, proper DKIM handling |

**CRITICAL:** If upgrading BillionMail from v4.8.x to v4.9.0+, you MUST update noez_setup.sh to the latest version!

---

## APPENDIX C: External Dependencies

- Noez GRE tunnel service
- Cloudflare account (optional but recommended)
- BillionMail v5.x
- Docker 20.x+
- iproute2 (ip command)
- iptables
- nsenter (util-linux)
- PostgreSQL client (docker exec)

---

**Document Version:** 4.0 (v4.9.0 Compatible)  
**Last Updated:** 2026-04-08  
**Author:** AI Agent Knowledge Preservation  
**Purpose:** Enable any AI agent to understand and fix this system

---

**⚠️ FINAL NOTE FOR AI AGENTS:**

This system works when:
1. GRE tunnel carries Noez IPs
2. Container binds to those IPs
3. Postfix uses correct source IP
4. Host forwards replies to container (NOT local!)
5. **NEW:** SQL schema matches BillionMail version (12 columns for v4.9.0+)
6. **NEW:** DKIM keys are complete (392 chars) and single selector only

The #1 mistake is forgetting #4 - always check `ip route show table local` and ensure Noez IPs are NOT there!

The #2 mistake (v4.9.0+) is using old SQL schema - always check table structure before INSERT!

---

## 16. HOW TO REBUILD & REDEPLOY BACKEND CODE

BillionMail's core binary is written in Go and runs inside a Debian-based Docker container (`core-billionmail`). To compile and deploy backend changes, follow these steps:

### Rebuild Workflow
1.  **Do NOT compile directly on the host** if Go is not installed or version-mismatched.
2.  **Compile inside a Debian Docker container** to ensure dynamic linking compatibility (`glibc` vs `musl`):
    ```bash
    docker run --rm \
      -v /opt/billionmail/core:/app \
      -w /app \
      golang:1.22 \
      go build -ldflags="-s -w" -o billionmail-test main.go
    ```
    This compiles a compatible static binary named `billionmail-test` inside `/opt/billionmail/core/`.
3.  **Build the Docker Image:** Rebuild the container image using Docker Compose. This automatically copies `billionmail-test` to the correct internal path `/opt/billionmail/core/billionmail`:
    ```bash
    docker compose build core-billionmail
    ```
4.  **Restart the Container:** Apply the changes by recreating and starting the container:
    ```bash
    docker compose up -d core-billionmail
    ```
5.  **Verify Service Status:** Check the logs to ensure the service did not fail to spawn (Exit 127/ENOENT):
    ```bash
    docker compose logs core-billionmail --tail=30
    ```

---

## 17. HOW TO CREATE & SCHEDULE OUTBOUND CAMPAIGNS

This section outlines how to create, validate, and schedule outbound campaigns directly in the BillionMail database, ensuring safe delivery rates, personalization fallbacks, and spintax formatting.

### 1. Copywriting & Template Syntax Rules

To maximize deliverability and avoid spam filters, BillionMail templates use two layers of dynamic processing:

#### A. Go Template Personalization (with Fallbacks)
To prevent empty field errors (e.g. "Hi ," or "check out your  in tech"), you **must** use conditional statements. Never output a raw variable like `{{.Subscriber.first_name}}` without an `if` block.

*   **First Name Fallback:**
    ```html
    Hi {{if .Subscriber.first_name}}{{.Subscriber.first_name}}{{else}}there{{end}},
    ```
*   **Company Name Fallback:**
    ```html
    {{if .Subscriber.company_name}}{{.Subscriber.company_name}}{{else}}your company{{end}}
    ```
*   **Subject Line Personalization:** Ensure that subject alternatives are also safe from empty fields:
    ```text
    { {{if .Subscriber.first_name}}{{.Subscriber.first_name}}?{{else}}quick check?{{end}} | quick check for {{if .Subscriber.company_name}}{{.Subscriber.company_name}}{{else}}your company{{end}} }
    ```

#### B. Spintax Formatting
BillionMail rotates text options enclosed in curly braces separated by vertical bars `{option 1|option 2}`.
*   **Rule:** Ensure that single curly braces for spintax are perfectly balanced (`{` matches `}`) and do not interfere with Go template double braces (`{{` and `}}`).

---

### 2. Campaign Setup Parameters in `email_tasks`

When inserting a campaign into the `email_tasks` table, configure the following columns:

| Column | Recommended Value | Purpose |
| :--- | :--- | :--- |
| `threads` | `10` | Caps the sending rate to a safe **10 emails/minute** (setting to `0` defaults to 1000/min and gets blacklisted). |
| `rotate_senders` | `1` | Enables **warmup sender rotation** across all active mailboxes. |
| `track_open` | `1` | Enables open tracking. |
| `track_click` | `1` | Enables click tracking. |
| `unsubscribe` | `0` | **Deactivates the default unsubscribe link** at the bottom, allowing you to use a custom reply-to opt-out ("Reply STOP"). |
| `active` | `1` | Activates the task for processing. |
| `pause` | `0` | Set to 0 to keep the task ready for the scheduler daemon. |
| `task_process` | `0` | Represents "Ready/Waiting". |

---

### 3. Sequential Scheduling & Warmup

To schedule a weekly campaign sequence without overloading IPs:
1.  **Set `start_time`:** Assign the Unix timestamp for the start date and time (e.g. 9:00 AM local time). The Go engine only picks up tasks where `start_time <= CurrentTime`.
2.  **Enable Warmup Rotation:** Create a record in `bm_campaign_warmup` linking the task to `warmup_id = 1`:
    ```sql
    INSERT INTO bm_campaign_warmup (task_id, warmup_id) VALUES (task_id, 1);
    ```

---

### 4. Verification & Validation Script

Always run a pre-flight validation script to check Go template syntax and spintax before updating the database. The validator must check:
1.  `{{` count matches `}}` count.
2.  `{` count matches `}` count (after stripping double variables).
3.  No bare `.Subscriber` variables are used outside an `if` condition.

---

### 5. Mandatory Pre-Flight Test Email Verification

Before activating or scheduling any campaign in the Go engine, you **must** run a test send to verify rendering:
1.  **Queue Test Recipient:** Ensure `all_replies@moescale.site` is in the target `bm_contacts` group (it is pre-populated in all 110 segments with attributes `first_name: "Alex"`, `company_name: "Hormozi Corp"`).
2.  **Trigger Test Send:** Call the `SendTestEmail` API or execute `send_test_email.py` for the target template.
3.  **Verify local delivery rendering:** Read the received email file in `/opt/billionmail/vmail-data/moescale.site/all_replies/cur/` and confirm:
    - Spintax options are resolved.
    - Personalization tags (`first_name`, `company_name`) are correctly populated.
    - Subject line layout is correct.
    - *Note:* The test endpoint always appends an unsubscribe link at the bottom; ignore this if task `unsubscribe = 0` is set for the actual run.
4.  **Activate Campaign:** Only after verification, set the task's `start_time` or `active = 1` to allow the Go core engine to process the campaign.

---

## 18. DELIVERABILITY PROTECTION & DYNAMIC LIMITS

BillionMail has three layers of automated protection logic configured in `/opt/billionmail/.env`:

### A. Dynamic Bounce Protection (Campaign-Level)
* **Frequency:** Evaluates campaign stats every 2 minutes over a rolling 15-minute window.
* **Throttle Threshold:** If campaign bounce/deferral rate exceeds 5%, sending speed is halved (`BOUNCE_THROTTLE_FACTOR=0.50`).
* **Pause Threshold:** If campaign bounce/deferral rate exceeds 10%, the campaign automatically pauses for 1 hour.
* **Settings:**
  ```env
  BOUNCE_THROTTLE_THRESHOLD=0.05
  BOUNCE_PAUSE_THRESHOLD=0.10
  BOUNCE_THROTTLE_FACTOR=0.50
  ```

### B. IP Cooldown Isolation (IP-Level)
* **Trigger:** If an individual IP has >= 20 sends and its bounce rate is >= 10% in the last 15 minutes, it is placed on a **2-hour cooldown** in Redis.
* **Routing:** The worker pool automatically routes around cooled-down IPs, letting healthy IPs continue sending.

### C. Dynamic Daily Cap (Global Safety)
* **Config:** Managed by `DAILY_SEND_LIMIT` in `.env`.
* **Dynamic Mode (Blank):** Set `DAILY_SEND_LIMIT=`. The Go backend calculates the daily cap by summing the daily warmup capacity of all active IPs, throttled by their health scores.
* **Manual Override:** Set `DAILY_SEND_LIMIT=5000` to enforce a hard daily limit across the system.
* **Disabled:** Set `DAILY_SEND_LIMIT=disable` to bypass daily cap checks.

---

## 19. ADVANCED TEMPLATE SYNTAX & SPINTAX MANDATES

### A. Go Template Syntax Enforcement
* **Rule:** BillionMail strictly uses Go html/template parsing.
* **FORBIDDEN:** `{{#if .Subscriber.first_name}}` (Handlebars syntax). Using `#` causes the parser to fail or corrupt output.
* **REQUIRED:** `{{if .Subscriber.first_name}}` (Go template syntax).
* **Mass Fix SQL:**
  ```sql
  UPDATE email_templates SET content = REPLACE(content, '{{#if', '{{if') WHERE content LIKE '%{{#if%';
  ```

### B. Strict Spintax Flattening (No Nested Braces)
* **Rule:** Single curly brace spintax `{option1|option2}` MUST NOT be nested inside another spintax block.
* **FORBIDDEN:** `{Option A | Option B {Sub1|Sub2}}` or `{Every record has... {and|or}...}`
* **REQUIRED:** Flatten all nested blocks into explicit options (e.g. `{Option A|Option B Sub1|Option B Sub2}`).

---

## 20. TELEGRAM BOT DAEMON & DAILY CRON AUDITS

### A. Systemd Daemon Service (`telegram-bot.service`)
* **Path:** `/opt/billionmail/core-data/telegram_bot_service.py`
* **Service:** `/etc/systemd/system/telegram-bot.service`
* **Function:** Long-polls Telegram API, intercepts user prompts, executes queries against local database and proxies, and dispatches HTML-formatted updates.
* **Commands:**
  ```bash
  systemctl status telegram-bot
  systemctl restart telegram-bot
  journalctl -u telegram-bot -n 30
  ```

### B. Daily Health Audit Routine
* **Execution Script:** `/opt/billionmail/core-data/run_daily_audit.py`
* **Audit Engine:** `/opt/billionmail/core-data/verify_campaigns_deep.py`
* **Cron Schedule:** Runs every evening at 6:00 PM local time (`0 22 * * *` UTC).
* **Checks Performed:**
  1. Concurrency spikes (warns if >2 campaigns/day).
  2. Spintax balance and syntax integrity for all upcoming templates in next 48h.
  3. Warmup profile associations in `bm_campaign_warmup`.
  4. Automatic Telegram report delivery formatted in safe HTML chunks.

---

## 21. MAILBOX MIGRATION & REBUILD PROCEDURES

When changing catch-all or default reply mailboxes (e.g. from `all_replies@moescale.site` to `all_replies@b2bprosperity.com`):

### A. Database Relocation Steps
1. **Update Alias Routing:**
   ```sql
   UPDATE alias SET goto = 'new_mailbox@domain.com' WHERE goto = 'old_mailbox@domain.com';
   ```
2. **Migrate Roundcube Settings & Filters:**
   ```sql
   UPDATE users SET username = 'new_mailbox@domain.com' WHERE username = 'old_mailbox@domain.com';
   UPDATE identities SET email = 'new_mailbox@domain.com' WHERE email = 'old_mailbox@domain.com';
   ```

### B. File Ownership & Maildir Rebuild
1. **Move Maildir:** Relocate files preserving subdirectory structures (`.Sent`, `.Junk`, `.Warmup`, `.Trash`).
2. **Enforce Ownership:** Always run `chown -R 150:mail /opt/billionmail/vmail-data/<domain>/<user>/`.
3. **Index Mismatch Repair (Fix Loading Loop):** If Roundcube gets stuck loading infinitely due to corrupted Dovecot index counts:
   ```bash
   find /opt/billionmail/vmail-data/<domain>/<user>/ -name "dovecot.index*" -delete
   find /opt/billionmail/vmail-data/<domain>/<user>/ -name "dovecot-uidlist" -delete
   find /opt/billionmail/vmail-data/<domain>/<user>/ -name "dovecot-uidvalidity*" -delete
   ```
   Dovecot automatically regenerates clean indexes upon next login.

---

## 22. AUTOMATED DELIVERABILITY & AUTHENTICATION TESTING (`aboutmy.email`)

### Overview
`aboutmy.email` provides automated end-to-end analysis of email authentication, sending IP reputation, SPF/DKIM/DMARC alignment, and reverse DNS. Because it exposes a real-time polling API (`/s?c=`), AI agents can programmatically trigger test sends, wait for deep analysis, and verify deliverability health without browser automation.

### Architecture & Polling Mechanism
1. **Request Test Address:**
   HTTP GET `https://aboutmy.email/s?c=`
   Returns JSON payload with a unique session ID and temporary email:
   ```json
   [{"s": "<session_id>", "e": "<temporary_email>@aboutmy.email", "m": "Waiting...", "a": "n"}]
   ```
2. **Send Test Email via Local Postfix:**
   Inject a test message to `<temporary_email>@aboutmy.email` via local SMTP (`127.0.0.1:25`) with envelope sender `<mailbox>@<target_domain>`.
3. **Poll for Analysis Events:**
   HTTP GET `https://aboutmy.email/s?c=<session_id>`
   Poll every 3 seconds. The service streams event states: `Connect`, `TLS`, `SPF`, `dkim`, `DMARC`, `BIMI`, `DNS`.
4. **Completion Report:**
   When event `{"a": "c", "c": "/<report_id>"}` is received, the full web report is ready at:
   `https://aboutmy.email/<report_id>`

### Standalone CLI Tool
A dedicated test utility is located at `/opt/billionmail/test_deliverability_aboutmyemail.py`:
```bash
# Test deliverability and IP binding for any domain/mailbox:
python3 /opt/billionmail/test_deliverability_aboutmyemail.py alex@aibdr.shop
```

### Critical Checklist for 10/10 Score:
* **Connecting IP:** MUST match the dedicated assigned IP for that domain in `ip_assignments.csv`. If it shows `77.90.32.40` or the primary VPS IP, `bm_domain_smtp_transport` is missing the mapping.
* **HELO String:** MUST match `-o smtp_helo_name` in `master.cf` (e.g. `77-90-32-X.b2bprosperity.com`).
* **SPF Validation:** MUST return `pass`. If `softfail`, check that `+ip4:<outbound_ip>` is published on the domain's root `@` TXT record in Namecheap.
* **DKIM Validation:** MUST return `pass` with a single signature (`s=default`). If dual signatures (`s=short` and `s=default`) are detected, purge the `short` selector from `conf/rspamd/local.d/dkim_signing.conf`.
* **DMARC Record:** MUST return `pass` (`v=DMARC1; p=quarantine; rua=mailto:dmarc@<domain>`).
* **Reverse DNS (rDNS):** MUST return a valid PTR record matching the announced HELO hostname.

