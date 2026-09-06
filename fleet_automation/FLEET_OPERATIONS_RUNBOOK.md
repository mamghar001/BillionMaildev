---
name: billionmail-fleet-operations
description: Master knowledge base and operational runbook for managing the 254-IP BillionMail multi-IP outbound email fleet, Namecheap automated DNS provisioning, Postfix transport mapping, and FCrDNS compliance.
---

# BillionMail Fleet Operations & Domain Provisioning Master Runbook

This runbook is the definitive operational reference for managing the BillionMail multi-IP email fleet on this server. Any AI agent or systems operator executing commands on this server must follow the architectural patterns and automated scripts detailed below.

---

## 1. Fleet Architecture Overview

| Component | Network / Location | Role & Constraints |
| :--- | :--- | :--- |
| **Primary VPS Host** | `5.230.29.58` | Administrative only. Runs BillionMail Web UI, Core Go API, PostgreSQL, and `b2bprosperity.com`. **NEVER send cold outreach emails from this IP.** |
| **Outbound IP Subnet** | `77.90.32.0/24` | Dedicated outbound sending pool. |
| **Subnet Gateway** | `77.90.32.1` | Network routing gateway (reserved, non-sending). |
| **Usable Sending IPs** | `77.90.32.2` – `77.90.32.254` | **253 total usable outbound IPs**. |
| **Subnet Broadcast** | `77.90.32.255` | Broadcast address (non-sending). |
| **IP-to-Domain Mapping** | 1 IP = 1 Domain | Strict 1-to-1 isolation for reputation protection and Forward-Confirmed Reverse DNS (FCrDNS). |

### Current Domain Fleet Breakdown
- **Active Campaign Domains (Namecheap):** 234 domains (mapped to `77.90.32.13`, `14`, `16`–`24`, `26`–`34`, `41`–`254`).
- **Active Cloudflare Sending Domains:** 19 domains (mapped to `77.90.32.2`–`12`, `15`, `25`, `35`–`40`).
- **Administrative Server Domain:** `b2bprosperity.com` on `5.230.29.58`.
- **Total Outbound IPs in Operation:** **253 / 253 IPs (100% capacity, 0 vacant IPs)**.

---

## 2. Strict DNS & Mail Standards (FCrDNS)

To achieve maximum inbox placement and pass DMARC/SPF/DKIM filters (Gmail, Yahoo, Microsoft 365), every sending domain must strictly adhere to the following 6 DNS records:

1. **Forward A Record (`mail.<domain>`):** Points directly to the domain's assigned outbound IP (`77.90.32.X`).
2. **Apex A Record (`@`):** Points directly to the domain's assigned outbound IP (`77.90.32.X`).
3. **MX Record (`@`):** Points to `mail.<domain>` with priority `10`.
4. **SPF TXT Record (`@`):** `v=spf1 +a +mx +ip4:<outbound_ip> ~all`
5. **DMARC TXT Record (`_dmarc`):** `v=DMARC1; p=quarantine; rua=mailto:dmarc@<domain>`
6. **DKIM TXT Record (`default._domainkey`):** **Must be a 1024-bit RSA key.**
   > **CRITICAL RULE:** Namecheap BasicDNS has a strict 255-character maximum string limit for TXT records. Standard 2048-bit DKIM keys (~450 chars) will fail to upload via the API. Always use 1024-bit keys for Namecheap domains.

### Reverse DNS (PTR) Alignment
- The PTR record on the ISP side (Noez control panel) for `77.90.32.X` must resolve to `mail.<domain>`.
- Forward-Confirmed Reverse DNS (FCrDNS) is satisfied because:
  `77.90.32.X` &rarr; PTR &rarr; `mail.<domain>` &rarr; A &rarr; `77.90.32.X`.

---

## 3. Automated Provisioning Script (`/root/provision_new_domains.py`)

The turnkey script [`/root/provision_new_domains.py`](file:///root/provision_new_domains.py) handles the entire end-to-end lifecycle when adding new domains to the fleet.

### What the Script Does Automatically:
1. **Vacant IP Discovery:** Queries PostgreSQL (`bm_multi_ip_domain`) and identifies all unassigned IPs in `77.90.32.2`–`77.90.32.254`.
2. **Domain DB Registration:** Inserts domain into the `domain` table with `active=1`.
3. **1024-bit DKIM Key Generation:** Invokes `rspamadm dkim_keygen -b 1024 -s default -d <domain>` inside the Rspamd container, saves `default.private` and `default.pub` to `/opt/billionmail/rspamd-data/dkim/<domain>/` with permissions `102:104` (mode `0644`).
4. **Rspamd Signing Config Injection:** Injects domain DKIM selector block into `/opt/billionmail/conf/rspamd/local.d/dkim_signing.conf`.
5. **Mailbox Creation:** Creates 4 sender mailboxes per domain using real-looking female White USA names (firstName.lastName@domain) (`avery.cox`, `jordan.lee`, `taylor.morgan`) with salted SSHA512 password hashing.
6. **Multi-IP Route Assignment:** Inserts domain and outbound IP into `bm_multi_ip_domain`.
7. **Postfix Transport Registration:**
   - Adds route into `bm_domain_smtp_transport` (`relay` &rarr; `smtp_bind_ip_<clean_ip>_<clean_domain>`).
   - Appends dedicated transport definition to `/opt/billionmail/conf/postfix/master.cf`:
     ```text
     smtp_bind_ip_77_90_32_13_domain_shop unix - - n - - smtp
         -o smtp_bind_address=77.90.32.13
         -o smtp_helo_name=mail.domain.shop
         -o syslog_name=postfix-77-90-32-13
     ```
8. **Automated Namecheap DNS Configuration:** Calls the Namecheap API (`namecheap.domains.dns.setHosts`) and provisions all 6 DNS records (`mail` A, `@` A, `@` MX, `@` SPF, `_dmarc` TXT, `default._domainkey` 1024-bit DKIM).
9. **Service Reloads:** Safely reloads Postfix (`postfix reload`) and Rspamd (`pkill -HUP rspamd`).
10. **Fleet File Tracking:** Appends entries to `/root/ip_assignments.csv` and regenerates `/root/ptr_records_plain.txt` & `/root/ptr_records_to_set.csv`.
11. **Live Propagation Check:** Performs a live DNS query to Cloudflare `1.1.1.1` to verify resolution.

---

## 4. Script Usage Instructions

### Check Available Vacant IPs
```bash
python3 /root/provision_new_domains.py --status
```

### Dry Run (Preview without making any changes)
```bash
python3 /root/provision_new_domains.py --dry-run domain1.shop domain2.shop
```

### Provision Domains Directly from Command Line
```bash
python3 /root/provision_new_domains.py domain1.shop domain2.shop domain3.shop
```

### Provision Domains from a Text File
Create a file `/root/new_domains.txt` with one domain per line:
```text
domain1.shop
domain2.shop
domain3.shop
```
Then run:
```bash
python3 /root/provision_new_domains.py --file /root/new_domains.txt
```

---

## 5. System Components & Key File Locations

| File / Service | Path / Command | Purpose |
| :--- | :--- | :--- |
| **Namecheap API Config** | `/root/.namecheap.env` | API User, Key, and Whitelisted Client IP (`5.230.29.58`). |
| **IP Fleet Assignments** | [`/root/ip_assignments.csv`](file:///root/ip_assignments.csv) | Master CSV of domain &rarr; IP mappings. |
| **PTR Records Export** | [`/root/ptr_records_plain.txt`](file:///root/ptr_records_plain.txt) | Plaintext list of IP &rarr; `mail.<domain>` for ISP ticket. |
| **PTR Records CSV** | [`/root/ptr_records_to_set.csv`](file:///root/ptr_records_to_set.csv) | CSV export of IP &rarr; PTR values. |
| **Postfix Transports** | [`/opt/billionmail/conf/postfix/master.cf`](file:///opt/billionmail/conf/postfix/master.cf) | Transport definitions with bound IPs & HELO hostnames. |
| **Postfix Sender Maps** | [`/opt/billionmail/conf/postfix/sql/pgsql_sender_transport_maps.cf`](file:///opt/billionmail/conf/postfix/sql/pgsql_sender_transport_maps.cf) | SQL lookup for sender-dependent default transport. |
| **Rspamd DKIM Keys** | `/opt/billionmail/rspamd-data/dkim/<domain>/` | Private key (`default.private`) and public key (`default.pub`). |
| **Rspamd Signing Conf** | `/opt/billionmail/conf/rspamd/local.d/dkim_signing.conf` | Per-domain selector mappings for outbound DKIM signing. |
| **Fleet DNS Verifier** | [`/root/verify_full_fleet_dns.py`](file:///root/verify_full_fleet_dns.py) | High-speed concurrent public DNS auditor (audits all 254 domains in ~10s). |
| **PostgreSQL Database** | Container: `billionmail-pgsql-billionmail-1` | Stores `domain`, `mailbox`, `bm_multi_ip_domain`, `bm_domain_smtp_transport`. |

---

## 6. PostgreSQL Diagnostic Queries

To check fleet health via PostgreSQL inside Docker:

```bash
# 1. Count active vs inactive multi-IP domains
docker exec billionmail-pgsql-billionmail-1 psql -U billionmail -d billionmail -c "
SELECT COUNT(*) as total,
       COUNT(*) FILTER (WHERE active=1) as active,
       COUNT(*) FILTER (WHERE active=0) as inactive
FROM bm_multi_ip_domain;
"

# 2. View all active IP assignments
docker exec billionmail-pgsql-billionmail-1 psql -U billionmail -d billionmail -c "
SELECT domain, outbound_ip, active FROM bm_multi_ip_domain WHERE active=1 ORDER BY outbound_ip;
"

# 3. Check transport routing for a specific domain
docker exec billionmail-pgsql-billionmail-1 psql -U billionmail -d billionmail -c "
SELECT * FROM bm_domain_smtp_transport WHERE domain = '@example.shop';
"
```

---

## 7. Operational Runbook & Troubleshooting

### Scenario A: Verifying Full Fleet DNS Status (High-Speed Concurrent Auditor)
To verify live public DNS records across all 254 domains in ~10 seconds:
```bash
python3 /root/verify_full_fleet_dns.py
```

#### What the Script Audits:
1. **Pulls Fleet List:** Authenticates with BillionMail Core API (`/api/login`) and fetches the full domain catalog.
2. **25 Concurrent Threads:** Uses `concurrent.futures.ThreadPoolExecutor` to query Cloudflare DNS (`1.1.1.1`) in parallel without blocking.
3. **Validates All 6 Parameters Per Domain:**
   - **Forward A (`mail.<domain>`):** Confirms it matches the domain's dedicated outbound IP (`77.90.32.X`) for FCrDNS.
   - **Apex A (`@`):** Confirms resolving to the dedicated IP.
   - **MX Record (`@`):** Confirms priority pointing to `mail.<domain>`.
   - **SPF Record (`@`):** Confirms `v=spf1 +a +mx +ip4:<outbound_ip> ~all`.
   - **DKIM Record (`default._domainkey`):** Confirms public RSA key exists and matches local Rspamd keys.
   - **DMARC Record (`_dmarc`):** Confirms `v=DMARC1; p=quarantine; rua=mailto:dmarc@<domain>` (strict isolated per-domain policy with no footprint leaks).
4. **BillionMail Engine Cross-Check:** Simultaneously audits BillionMail's internal validation flags.
5. **Actionable Failure Output:** If any record fails or doesn't match the expected IP, it immediately prints the offending domain and the exact discrepancy.

### Scenario B: Restarting Mail Services
If configuration files or keys are updated manually:
```bash
# Reload Postfix configuration without dropping connections
docker exec billionmail-postfix-billionmail-1 postfix reload

# Reload Rspamd signing tables
docker exec billionmail-rspamd-billionmail-1 pkill -HUP rspamd

# Restart Core BillionMail binary (if code or database hooks modified)
systemctl restart billionmail-core || supervisorctl restart billionmail || pkill -f /opt/billionmail/core/billionmail && /opt/billionmail/core/billionmail &
```

### Scenario C: FCrDNS Testing
To verify that an outbound IP satisfies Forward-Confirmed Reverse DNS:
```bash
# 1. Check Reverse DNS (PTR)
dig -x <OUTBOUND_IP> +short

# 2. Check Forward DNS (A) of the returned hostname
dig <RETURNED_HOSTNAME> +short @1.1.1.1
```
The returned IP from step 2 must match `<OUTBOUND_IP>` exactly.
