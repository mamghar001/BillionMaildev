# Noez IP Blacklist Check Fix (v4.9.2)

> **What this doc covers:** How we made BillionMail's "Check Blacklist" feature work when `domain.a_record` contains a Noez IP address instead of a hostname.

---

## The Problem

When using Noez GRE tunnels, each domain's `a_record` field in the `domain` table must store the dedicated Noez IP so that blacklist checks verify the correct outbound IP reputation. However, BillionMail's code assumed `a_record` would always be a domain name, causing three cascading failures:

1. **Validation Error** — The `/domain_blocklist/check` API rejected the request with:  
   `The ARecord value 5.230.168.43 is not a valid domain format`
2. **DNS Resolve Failure** — Even after bypassing validation, `CheckBlacklist()` called `ResolveA()` on the IP string, which immediately returned `resolve failed`.
3. **DNS UI Pollution** — `FormatMX()` used the raw IP from `a_record` as the hostname in DNS record suggestions, showing the Noez IP as the MX/A record target instead of `mail.domain.com`.

Additionally, every `docker restart` of the Postfix container wiped the `nsenter`-added loopback IPs, breaking mail flow until they were manually restored.

---

## Files Changed

| File | Change |
|------|--------|
| `core/api/domains/v1/domain_blocklist.go` | Removed `\|domain` from the `v:` struct tag so `a_record` accepts IPs |
| `core/internal/controller/domains/domains_v1_check_blacklist.go` | Added `net.ParseIP()` guard: skip DNS resolution when `a_record` is already an IP |
| `core/internal/service/public/common.go` | Patched `FormatMX()` to ignore IP values in `a_record`, falling back to `mail.<domain>` |
| `noez_setup.sh` | Added auto-restoration of all Noez IPs via `setup_noez_ips.sh` after every Postfix restart |
| `core/billionmail` | Rebuilt Go binary with all patches above |

---

## Detailed Explanations

### 1. API Validation Fix

**Before:**
```go
type CheckBlacklistReq struct {
    ARecord string `json:"a_record" v:"required|domain"`
}
```

GoFrame's validation rules use pipe (`|`) as **AND**. `required|domain` meant "must be non-empty AND must be a valid domain". IP addresses failed the second rule.

**After:**
```go
type CheckBlacklistReq struct {
    ARecord string `json:"a_record" v:"required"`
}
```

Now it accepts domain names *or* IP addresses.

---

### 2. Controller Logic Fix

**Before:**
```go
ip, err := domains.ResolveA(req.ARecord, nil)
if err != nil {
    return nil, err
}
```

`ResolveA` sends a DNS A-query. Passing an IP literal like `5.230.168.43` to a DNS resolver always fails.

**After:**
```go
ip := req.ARecord
if net.ParseIP(ip) == nil {
    ip, err = domains.ResolveA(req.ARecord, nil)
    if err != nil {
        return nil, err
    }
}
```

If `a_record` is already an IP, we use it directly. If it's a hostname (e.g. `mail.domain.com`), we resolve it via DNS as before.

---

### 3. FormatMX Fix (DNS Records UI)

**Before:**
```go
func FormatMX(domain string) string {
    val, err := g.DB().Model("domain").Where("domain", domain).WhereOr("a_record", domain).Value("a_record")
    if err == nil && !val.IsEmpty() {
        return val.String()
    }
    return "mail." + strings.TrimPrefix(domain, "mail.")
}
```

When `a_record` contained `5.230.168.43`, this function returned the IP as the MX hostname, which is invalid.

**After:**
```go
func FormatMX(domain string) string {
    val, err := g.DB().Model("domain").Where("domain", domain).WhereOr("a_record", domain).Value("a_record")
    if err == nil && !val.IsEmpty() {
        if net.ParseIP(val.String()) == nil {
            return val.String()
        }
    }
    return "mail." + strings.TrimPrefix(domain, "mail.")
}
```

If `a_record` is an IP, we ignore it and return `mail.domain`.

---

### 4. Postfix Restart IP Restoration

Docker restarts clear all ephemeral network changes made with `nsenter` inside a container (including the loopback aliases for Noez IPs). `noez_setup.sh` now calls `bash /opt/billionmail/setup_noez_ips.sh` immediately after every `docker restart` of the Postfix container:

```bash
docker restart $CONTAINER_NAME && sleep 3
bash /opt/billionmail/setup_noez_ips.sh >/dev/null 2>&1
```

This ensures all 32 Noez IPs are rebound to the container's loopback interface automatically.

---

## Verification

After applying the patches and rebuilding the core container:

1. Go to **Domains → Check Blacklist** on a domain with a Noez IP in `a_record`.
2. The UI should show a success toast: *"The test will take two minutes, so please be patient"*
3. After ~2 minutes, check logs or the blocklist logs page — you should see results similar to:

```
Results for 5.230.168.43:
Ip: 5.230.168.43
Tested: 144
Passed: 141
Invalid: 3
Blacklisted: 0
```

---

## Rebuilding the Core Container

If you ever need to rebuild from source after pulling `v4.9.2`:

```bash
cd /opt/billionmail/core
docker run --rm -v "$(pwd):/app" -w /app golang:1.23-alpine sh -c "go build -o billionmail-test ./main.go"
cp billionmail-test billionmail
cd /opt/billionmail
docker compose build core-billionmail
docker compose up -d core-billionmail
```

The `v4.9.2` tag already ships with the rebuilt `core/billionmail` binary, so fresh installs do not need to compile it manually.

---

## Related Docs

- [`NOEZ_SETUP.md`](./NOEZ_SETUP.md) — Full GRE tunnel setup script usage
- [`SKILLS.md`](./SKILLS.md) — Complete agent knowledge base for this integration
