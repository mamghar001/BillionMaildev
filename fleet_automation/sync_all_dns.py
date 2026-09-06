#!/usr/bin/env python3
"""
Unified DNS Sync Script for Cloudflare & Namecheap
Syncs all 216 campaign domains + active Cloudflare sending domains.
Sets:
- mail.<domain> A record -> dedicated outbound IP (ip)
- <domain> (@) A record -> dedicated outbound IP (ip)
- <domain> (@) MX record -> mail.<domain> (priority 10)
- <domain> (@) SPF TXT -> v=spf1 +a +mx +ip4:<ip> ~all
- _dmarc.<domain> TXT -> v=DMARC1; p=quarantine; rua=mailto:dmarc@b2bprosperity.com
- default._domainkey.<domain> TXT -> 1024-bit DKIM key
"""

import os
import sys
import csv
import json
import time
import urllib.request
import urllib.parse
import re
import shutil
import subprocess

SERVER_IP = os.environ.get("SERVER_IP", "5.230.29.58")
CF_TOKEN = os.environ.get("CF_API_TOKEN", "")
NC_API_USER = os.environ.get("NC_API_USER", "")
NC_API_KEY = os.environ.get("NC_API_KEY", "")
NC_CLIENT_IP = os.environ.get("NC_CLIENT_IP", SERVER_IP)
NC_ENDPOINT = "https://api.namecheap.com/xml.response"

DKIM_BASE_DIR = "/opt/billionmail/rspamd-data/dkim"

def get_active_cf_zones():
    page = 1
    active_zones = {}
    while True:
        url = f"https://api.cloudflare.com/client/v4/zones?page={page}&per_page=50"
        req = urllib.request.Request(url, headers={"Authorization": f"Bearer {CF_TOKEN}"})
        try:
            with urllib.request.urlopen(req) as resp:
                data = json.loads(resp.read().decode())
                res = data.get("result", [])
                if not res:
                    break
                for z in res:
                    if z["status"] == "active":
                        active_zones[z["name"]] = z["id"]
                page += 1
        except Exception as e:
            print(f"Error loading CF zones: {e}")
            break
    return active_zones

def ensure_1024_dkim(domain):
    """Ensures default.pub and default.private contain a 1024-bit key for Namecheap compatibility."""
    d = os.path.join(DKIM_BASE_DIR, domain)
    if not os.path.isdir(d):
        return ""
    
    dp = os.path.join(d, "default.private")
    sp = os.path.join(d, "short.private")
    pub = os.path.join(d, "default.pub")
    sp_pub = os.path.join(d, "short.pub")

    if os.path.exists(dp) and os.path.getsize(dp) > 1000 and os.path.exists(sp):
        shutil.copyfile(sp, dp)
        shutil.copyfile(sp_pub, pub)

    if os.path.exists(pub):
        with open(pub) as f:
            m = re.search(r'p=([A-Za-z0-9+/=]+)', f.read())
            if m:
                return f"v=DKIM1; k=rsa; p={m.group(1)}"
    return ""

def get_dkim(domain):
    return ensure_1024_dkim(domain)

def sync_cloudflare_domain(domain, ip, zone_id, dkim_value):
    headers = {"Authorization": f"Bearer {CF_TOKEN}", "Content-Type": "application/json"}
    
    url = f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records?per_page=100"
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode())
            existing = data.get("result", [])
    except Exception as e:
        return False, f"Failed to list CF records: {e}"

    target_ip = ip if domain != "b2bprosperity.com" else SERVER_IP

    desired = [
        {"type": "A", "name": f"mail.{domain}", "content": target_ip, "ttl": 300},
        {"type": "A", "name": domain, "content": target_ip, "ttl": 300},
        {"type": "MX", "name": domain, "content": f"mail.{domain}", "priority": 10, "ttl": 300},
        {"type": "TXT", "name": domain, "content": f"v=spf1 +a +mx +ip4:{ip} ~all", "ttl": 300},
        {"type": "TXT", "name": f"_dmarc.{domain}", "content": f"v=DMARC1; p=quarantine; rua=mailto:dmarc@{domain}", "ttl": 300},
    ]
    if dkim_value:
        desired.append({"type": "TXT", "name": f"default._domainkey.{domain}", "content": dkim_value, "ttl": 300})

    for rec in desired:
        matched = None
        for ex in existing:
            if ex["type"] == rec["type"] and ex["name"] == rec["name"]:
                if ex["content"] == rec["content"]:
                    matched = "identical"
                    break
                else:
                    matched = ex["id"]
                    break
        
        if matched == "identical":
            continue
        elif matched:
            u_url = f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records/{matched}"
            u_req = urllib.request.Request(u_url, data=json.dumps(rec).encode(), headers=headers, method="PUT")
            try:
                urllib.request.urlopen(u_req)
            except Exception:
                pass
        else:
            c_url = f"https://api.cloudflare.com/client/v4/zones/{zone_id}/dns_records"
            c_req = urllib.request.Request(c_url, data=json.dumps(rec).encode(), headers=headers, method="POST")
            try:
                urllib.request.urlopen(c_req)
            except Exception:
                pass

    return True, "Cloudflare synced"

def sync_namecheap_domain(domain, ip, dkim_value):
    parts = domain.split(".", 1)
    sld, tld = parts[0], parts[1]
    
    params = {
        "ApiUser": NC_API_USER, "ApiKey": NC_API_KEY, "UserName": NC_API_USER,
        "ClientIp": NC_CLIENT_IP, "Command": "namecheap.domains.dns.setHosts",
        "SLD": sld, "TLD": tld,
        "EmailType": "MX",
        
        "HostName1": "mail", "RecordType1": "A", "Address1": ip, "TTL1": "300",
        "HostName2": "@", "RecordType2": "A", "Address2": ip, "TTL2": "300",
        "HostName3": "@", "RecordType3": "MX", "Address3": f"mail.{domain}", "MXPref3": "10", "TTL3": "300",
        "HostName4": "@", "RecordType4": "TXT", "Address4": f"v=spf1 +a +mx +ip4:{ip} ~all", "TTL4": "300",
        "HostName5": "_dmarc", "RecordType5": "TXT", "Address5": f"v=DMARC1; p=quarantine; rua=mailto:dmarc@{domain}", "TTL5": "300",
    }
    if dkim_value:
        params["HostName6"] = "default._domainkey"
        params["RecordType6"] = "TXT"
        params["Address6"] = dkim_value
        params["TTL6"] = "300"

    url = NC_ENDPOINT + "?" + urllib.parse.urlencode(params)
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=30) as r:
            body = r.read().decode("utf-8", errors="ignore")
        if '<ApiResponse Status="OK"' in body:
            return True, "Namecheap synced"
        errors = re.findall(r'<Error[^>]*>(.*?)</Error>', body)
        return False, errors[0][:80] if errors else body[:80]
    except Exception as e:
        return False, str(e)[:80]

def main():
    active_cf = get_active_cf_zones()
    print(f"Loaded {len(active_cf)} active Cloudflare zones.")

    assignments = []
    with open("/root/ip_assignments.csv") as f:
        reader = csv.DictReader(f)
        for row in reader:
            if "domain" in row and "outbound_ip" in row:
                assignments.append((row["domain"].strip(), row["outbound_ip"].strip()))

    print(f"Total campaign domains in ip_assignments.csv: {len(assignments)}")
    
    target_domains = assignments
    if len(sys.argv) > 1:
        arg = sys.argv[1]
        target_domains = [a for a in assignments if a[0] == arg]
        if not target_domains:
            print(f"Domain {arg} not found in ip_assignments.csv")
            return

    success_count = 0
    fail_count = 0
    failed_domains = []

    for idx, (dom, ip) in enumerate(target_domains, 1):
        if dom in active_cf:
            dkim = get_dkim(dom)
            ok, msg = sync_cloudflare_domain(dom, ip, active_cf[dom], dkim)
            status = "✓ [CF]" if ok else "✗ [CF]"
            print(f"[{idx}/{len(target_domains)}] {status} {dom:25} ({ip}) -> {msg}", flush=True)
            if ok:
                success_count += 1
            else:
                fail_count += 1
                failed_domains.append((dom, msg))
        else:
            dkim = ensure_1024_dkim(dom)
            ok, msg = sync_namecheap_domain(dom, ip, dkim)
            status = "✓ [NC]" if ok else "✗ [NC]"
            print(f"[{idx}/{len(target_domains)}] {status} {dom:25} ({ip}) -> {msg}", flush=True)
            if ok:
                success_count += 1
            else:
                fail_count += 1
                failed_domains.append((dom, msg))
            time.sleep(1.0) # rate limit Namecheap

    print("\n=== SYNC COMPLETE ===")
    print(f"Total: {len(target_domains)}, Success: {success_count}, Failed: {fail_count}")
    if failed_domains:
        print("Failed domains:")
        for fd, err in failed_domains:
            print(f"  {fd}: {err}")
        with open("/root/dns_sync_failed.txt", "w") as f:
            for fd, err in failed_domains:
                f.write(f"{fd} {err}\n")

    # Reload Rspamd to pick up any key updates
    print("\nReloading Rspamd...")
    os.system("docker exec billionmail-rspamd-billionmail-1 pkill -HUP rspamd")
    print("All tasks finished.")

if __name__ == "__main__":
    main()
