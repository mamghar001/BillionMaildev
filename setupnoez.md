# Noez IP Setup — Issue Log & Fixes

> Document created: 2026-05-31  
> Related scripts: `setup_noez_ips.sh`, `noez_setup.sh`, `noez-ips.service`

---

## 1. Symptom: Emails Sending from Wrong IP (`82.38.44.130`)

**Reported by user:** Campaign emails appeared to be sending from the host's main IP (`82.38.44.130`) instead of the assigned Noez IPs (`5.230.x.x`).

**Evidence found in logs:**

```
warning: smtp_connect_addr: bind 5.230.228.118: Cannot assign requested address
warning: smtp_connect_addr: bind 5.230.229.165: Cannot assign requested address
warning: smtp_connect_addr: bind 5.230.122.4: Cannot assign requested address
...
```

Remote servers also confirmed the source IP in reject messages:

```
554 For explanation visit https://postmaster.1und1.de/en/case?c=r0602&i=ip&v=82.38.44.130
450 4.7.1 Client host rejected: cannot find your reverse hostname, [82.38.44.130]
```

---

## 2. Root Cause: Container Restart Wiped Noez IPs

### How the Noez IP architecture works

1. **GRE Tunnel** (`gre1`) on the host carries all Noez IPs (`5.230.x.x`).
2. **Host routing** (`ip rule` + table 20) directs traffic from each Noez IP out via `gre1`.
3. **Container injection** (`setup_noez_ips.sh`) uses `nsenter` to add the Noez IPs to the Postfix container's **loopback** (`lo`) interface.
4. **Postfix binding**: `master.cf` defines per-domain transports with `smtp_bind_address=5.230.x.x`.
5. **Traffic flow**:
   - Postfix binds to `5.230.x.x` inside the container
   - Container routing (`ip rule` + table 100) sends it to the Docker bridge
   - Host routing (`ip rule` + table 20) sends it out `gre1`
   - Remote server sees the Noez IP as the source

### What broke

The Postfix container was restarted on **2026-05-29 13:43 UTC** (either manually or by Docker).  
When a container restarts, its network namespace is recreated. All IPs that were injected via `nsenter` are **lost**.

The `noez-ips.service` only runs **once at boot time**. It does **not** detect container restarts.

**Result:** Postfix could not bind to any Noez IP, fell back to the default `smtp` transport (using the container's Docker IP `172.66.2.100`), and Docker's `MASQUERADE` rule NATted that to the host's default IP `82.38.44.130`.

---

## 3. Diagnosis Steps

| Step | Command / Check | Result |
|------|-----------------|--------|
| 1 | Check host IPs | `gre1` had all 16 Noez IPs |
| 2 | Check container IPs | Container only had `172.66.1.100` and `172.66.2.100` — **Noez IPs missing** |
| 3 | Check Postfix logs | Hundreds of `Cannot assign requested address` errors |
| 4 | Check `master.cf` | 47 custom transports existed with correct `smtp_bind_address` and `smtp_helo_name` |
| 5 | Check DB mappings | `bm_domain_smtp_transport` pointed to correct transports |
| 6 | Check queue | ~4,880 deferred messages, growing daily |
| 7 | Verify routing | Host routing (`ip route get 8.8.8.8 from 5.230.x.x`) correctly pointed to `gre1` |
| 8 | Verify iptables | SNAT rules existed but were for `127.0.0.2` (disabled by design via `noez_setup.sh`) |

**Key finding:** `nsenter -t <PID> -n ip addr show lo` showed **zero** Noez IPs on the container's loopback.

---

## 4. Fix Applied

### 4.1 Immediate fix: Re-run `setup_noez_ips.sh`

```bash
bash /opt/billionmail/setup_noez_ips.sh
```

This script:
- Verified the GRE tunnel was up
- Re-added all 16 Noez IPs to the host's `gre1`
- Re-added all 16 Noez IPs to the container's `lo` via `nsenter`
- Re-applied host routing rules (`ip route` via Docker bridge)
- Re-applied container routing rules (`ip rule` + table 100)
- Re-applied iptables FORWARD rules

**Result after running:**
- Container loopback now shows all 16 Noez IPs
- Ping from `5.230.228.118` → `8.8.8.8` works (81ms)
- Ping from `5.230.122.4` → `8.8.8.8` works (81ms)
- Postfix queue dropped from ~4,880 to **4 messages** within minutes
- No new `Cannot assign requested address` errors

### 4.2 Postfix `myhostname` cleanup

During investigation, `main.cf` was found to contain:

```
myhostname = macbookpro.lan
```

This was added recently (2026-05-26) and was breaking the SMTP banner for inbound connections. It was corrected to:

```
myhostname = mail.moescale.site
```

> **Note:** This does **not** affect the per-IP HELO setup. The 47 custom transports in `master.cf` each explicitly override `smtp_helo_name` (e.g., `node-5-230-228-118.b2bprosperity.com`). The global `myhostname` only affects the default/fallback behavior.

### 4.3 PostgreSQL connection limit

The core logs showed repeated `pq: sorry, too many clients already` during the backlog.  
`max_connections` was increased from **100 → 300** and PostgreSQL was restarted.

### 4.4 IPv6 disabled in Postfix

Many deferred logs showed:

```
Network is unreachable (connect to smtp.google.com[2607:f8b0:...]:25)
```

`inet_protocols` was set to `ipv4` in `main.cf` to eliminate IPv6 unreachable errors.

---

## 5. Permanent Fix: Auto-Recovery Timer

To prevent this from happening again when the Postfix container restarts, a systemd timer was created:

### Files created

**`/etc/systemd/system/noez-ips-check.service`**
```ini
[Unit]
Description=Check and reapply Noez IPs to postfix container

[Service]
Type=oneshot
ExecStart=/bin/bash /opt/billionmail/setup_noez_ips.sh
```

**`/etc/systemd/system/noez-ips-check.timer`**
```ini
[Unit]
Description=Run Noez IP check every 5 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
```

### Enabled and started

```bash
systemctl daemon-reload
systemctl enable noez-ips-check.timer
systemctl start noez-ips-check.timer
```

**Behavior:** Every 5 minutes, the script checks if the Noez IPs are present on the container's loopback. If the container was restarted and the IPs are missing, they are re-added automatically.

> The script is idempotent — safe to run multiple times. It skips IPs that already exist.

---

## 6. Current Status

| Component | Status |
|-----------|--------|
| GRE tunnel | ✅ UP, endpoint reachable |
| Host Noez IPs (gre1) | ✅ 16 IPs present |
| Container Noez IPs (lo) | ✅ 16 IPs present |
| Postfix transports | ✅ 47 transports in `master.cf` |
| DB domain mappings | ✅ Correct |
| Queue backlog | ✅ Cleared (4,876 messages delivered) |
| Bind errors | ✅ None since fix |
| Auto-recovery timer | ✅ Active, triggers every 5 min |

---

## 7. Remaining Issues (Not Related to IP Routing)

The 4 messages still in the queue are stuck for **recipient-side** reasons, not source IP:

| Queue ID | Domain | Issue |
|----------|--------|-------|
| `993E4E0CDB` | `b2baioutbound.shop` | Ionos greylisting + PTR record rejection |
| `667D2E0CB9` | `moescale.store` | Ionos greylisting + PTR record rejection |
| `6CC90E0CB8` | `salesreferral.shop` | Connection timeout to `jpm-investment.co.uk` |
| `9CF8EE0CC6` | `growthwithai.store` | Greylisted by `restoimpact.com` |

### Separate deliverability issues to address:

1. **Missing reverse DNS (PTR)** for `82.38.44.130` — must be configured in Noez panel
2. **IP reputation / blocklists** — some Noez IPs appear on abusix and Proofpoint blocklists
3. **Sender domain reputation** — some domains flagged as blocklisted by Titan.email

These are **not** fixable from the server alone and require action at the VPS provider / DNS level.

---

## 8. Quick Reference

### Manual re-run (if timer is not enough)
```bash
bash /opt/billionmail/setup_noez_ips.sh
```

### Check if container has Noez IPs
```bash
CONTAINER_PID=$(docker inspect -f '{{.State.Pid}}' billionmail-postfix-billionmail-1)
nsenter -t "$CONTAINER_PID" -n ip addr show lo | grep "inet 5.230"
```

### Check Postfix for bind errors
```bash
docker exec billionmail-postfix-billionmail-1 grep "Cannot assign requested address" /var/log/mail/mail.log
```

### Check timer status
```bash
systemctl status noez-ips-check.timer
```

### Check queue
```bash
docker exec billionmail-postfix-billionmail-1 postqueue -p
```

---

## 9. Why This Architecture Exists

The `noez_setup.sh` approach intentionally **bypasses** BillionMail's built-in multi-IP Docker network + iptables SNAT mechanism. The built-in system was designed to:

1. Create a custom Docker bridge per IP
2. Assign the Postfix container a local IP in each bridge
3. Use iptables SNAT (`-s 127.0.0.2 --to-source 5.230.x.x`) to map local traffic to Noez IPs

This was disabled because:
- It requires 47 custom Docker networks
- It adds complexity and fragility
- The GRE tunnel + direct container injection is simpler and more reliable

The trade-off is that the IPs are **ephemeral** (lost on container restart), which is why the auto-recovery timer is necessary.
