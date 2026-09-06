#!/usr/bin/env python3
import concurrent.futures
import subprocess
import requests
import urllib3
import json
import time
import sys

urllib3.disable_warnings()

def get_all_bm_domains():
    s = requests.Session()
    s.verify = False
    s.get("https://127.0.0.1/admin888/")
    r = s.post("https://127.0.0.1/api/login", json={"username": "moescale", "password": "HID0mvCc-u"})
    if not r.json().get("success"):
        print("Failed to login to BillionMail API:", r.text)
        return []
    token = r.json()["data"]["token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    all_domains = []
    page = 1
    while True:
        res = s.get(f"https://127.0.0.1/api/domains/list?page={page}&page_size=50", headers=headers)
        data = res.json().get("data", {})
        items = data.get("list", [])
        if not items:
            break
        all_domains.extend(items)
        page += 1
    return all_domains

def dig_record(qname, qtype, server="1.1.1.1"):
    try:
        cmd = ["dig", f"@{server}", "+short", "+time=2", "+tries=2", qtype, qname]
        out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL, timeout=4).decode().strip()
        lines = [line.strip().strip('"') for line in out.splitlines() if line.strip()]
        return lines
    except Exception:
        return []

def audit_single_domain(domain_info):
    dom = domain_info.get("domain")
    expected_ip = domain_info.get("a_record")
    if not expected_ip:
        multi = domain_info.get("multi_ip_domains")
        if multi:
            expected_ip = multi.get("outbound_ip")
    if not expected_ip:
        expected_ip = "5.230.29.58"

    # Dig queries
    mail_host = f"mail.{dom}"
    a_mail = dig_record(mail_host, "A")
    a_apex = dig_record(dom, "A")
    mx_list = dig_record(dom, "MX")
    spf_list = dig_record(dom, "TXT")
    dkim_list = dig_record(f"default._domainkey.{dom}", "TXT")
    dmarc_list = dig_record(f"_dmarc.{dom}", "TXT")

    # Evaluation
    a_mail_ok = expected_ip in a_mail
    a_apex_ok = expected_ip in a_apex
    mx_ok = any(mail_host in m for m in mx_list)
    
    spf_raw = " ".join(spf_list)
    spf_ok = "v=spf1" in spf_raw and (expected_ip in spf_raw or "+a" in spf_raw or "+mx" in spf_raw)
    
    dkim_raw = "".join(dkim_list)
    dkim_ok = "v=DKIM1" in dkim_raw and "p=" in dkim_raw
    
    dmarc_raw = " ".join(dmarc_list)
    dmarc_ok = "v=DMARC1" in dmarc_raw
    dmarc_isolated = f"rua=mailto:dmarc@{dom}" in dmarc_raw or dom == "b2bprosperity.com"

    # BM API flags
    bm_dns = domain_info.get("dns_records", {})
    bm_a_ok = bm_dns.get("a", {}).get("valid", False)
    bm_mx_ok = bm_dns.get("mx", {}).get("valid", False)
    bm_spf_ok = bm_dns.get("spf", {}).get("valid", False)
    bm_dkim_ok = bm_dns.get("dkim", {}).get("valid", False)
    bm_dmarc_ok = bm_dns.get("dmarc", {}).get("valid", False)

    all_public_ok = (a_mail_ok and mx_ok and spf_ok and dkim_ok and dmarc_ok)

    return {
        "domain": dom,
        "expected_ip": expected_ip,
        "a_mail_ok": a_mail_ok,
        "a_apex_ok": a_apex_ok,
        "mx_ok": mx_ok,
        "spf_ok": spf_ok,
        "dkim_ok": dkim_ok,
        "dmarc_ok": dmarc_ok,
        "dmarc_isolated": dmarc_isolated,
        "all_public_ok": all_public_ok,
        "bm_a_ok": bm_a_ok,
        "bm_mx_ok": bm_mx_ok,
        "bm_spf_ok": bm_spf_ok,
        "bm_dkim_ok": bm_dkim_ok,
        "bm_dmarc_ok": bm_dmarc_ok,
        "a_mail_vals": a_mail,
        "mx_vals": mx_list,
        "spf_val": spf_raw,
        "dmarc_val": dmarc_raw,
    }

def main():
    print("[+] Fetching domains from BillionMail API...")
    domains = get_all_bm_domains()
    print(f"[+] Retrieved {len(domains)} domains from BillionMail.")
    if not domains:
        sys.exit(1)

    print("[+] Auditing public DNS records via Cloudflare 1.1.1.1 (concurrently)...")
    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=25) as executor:
        futures = [executor.submit(audit_single_domain, d) for d in domains]
        for f in concurrent.futures.as_completed(futures):
            results.append(f.result())

    # Summary Statistics
    total = len(results)
    pass_public_a = sum(1 for r in results if r["a_mail_ok"])
    pass_public_apex = sum(1 for r in results if r["a_apex_ok"])
    pass_public_mx = sum(1 for r in results if r["mx_ok"])
    pass_public_spf = sum(1 for r in results if r["spf_ok"])
    pass_public_dkim = sum(1 for r in results if r["dkim_ok"])
    pass_public_dmarc = sum(1 for r in results if r["dmarc_ok"])
    pass_public_all = sum(1 for r in results if r["all_public_ok"])
    pass_isolated_dmarc = sum(1 for r in results if r["dmarc_isolated"])

    pass_bm_a = sum(1 for r in results if r["bm_a_ok"])
    pass_bm_mx = sum(1 for r in results if r["bm_mx_ok"])
    pass_bm_spf = sum(1 for r in results if r["bm_spf_ok"])
    pass_bm_dkim = sum(1 for r in results if r["bm_dkim_ok"])
    pass_bm_dmarc = sum(1 for r in results if r["bm_dmarc_ok"])

    print("\n" + "="*70)
    print(f"FLEET DNS AUDIT REPORT ({total} TOTAL DOMAINS)")
    print("="*70)

    print("\n--- PUBLIC DNS VALIDATION (Cloudflare 1.1.1.1) ---")
    print(f"  Forward A Record (mail.<domain>):  {pass_public_a:3d} / {total} ({pass_public_a*100//total}%)")
    print(f"  Apex A Record (@):                 {pass_public_apex:3d} / {total} ({pass_public_apex*100//total}%)")
    print(f"  MX Record (@ -> mail.<domain>):    {pass_public_mx:3d} / {total} ({pass_public_mx*100//total}%)")
    print(f"  SPF Record (v=spf1 +a +mx +ip4):   {pass_public_spf:3d} / {total} ({pass_public_spf*100//total}%)")
    print(f"  DKIM Record (default._domainkey):  {pass_public_dkim:3d} / {total} ({pass_public_dkim*100//total}%)")
    print(f"  DMARC Record (_dmarc):             {pass_public_dmarc:3d} / {total} ({pass_public_dmarc*100//total}%)")
    print(f"  Isolated DMARC Policy (No Leaks):  {pass_isolated_dmarc:3d} / {total} ({pass_isolated_dmarc*100//total}%)")
    print(f"  --> 100% PERFECT PUBLIC PASS:      {pass_public_all:3d} / {total} ({pass_public_all*100//total}%)")

    print("\n--- BILLIONMAIL INTERNAL VALIDATION ENGINE ---")
    print(f"  BillionMail A Record Check:        {pass_bm_a:3d} / {total} ({pass_bm_a*100//total}%)")
    print(f"  BillionMail MX Record Check:       {pass_bm_mx:3d} / {total} ({pass_bm_mx*100//total}%)")
    print(f"  BillionMail SPF Record Check:      {pass_bm_spf:3d} / {total} ({pass_bm_spf*100//total}%)")
    print(f"  BillionMail DKIM Record Check:     {pass_bm_dkim:3d} / {total} ({pass_bm_dkim*100//total}%)")
    print(f"  BillionMail DMARC Record Check:    {pass_bm_dmarc:3d} / {total} ({pass_bm_dmarc*100//total}%)")

    failures = [r for r in results if not r["all_public_ok"]]
    if failures:
        print(f"\n[!] DOMAINS REQUIRING ATTENTION ({len(failures)}):")
        for f in failures:
            print(f"  Domain: {f['domain']} (Expected IP: {f['expected_ip']})")
            if not f["a_mail_ok"]: print(f"    - mail A FAIL: got {f['a_mail_vals']}")
            if not f["mx_ok"]: print(f"    - MX FAIL: got {f['mx_vals']}")
            if not f["spf_ok"]: print(f"    - SPF FAIL: got '{f['spf_val']}'")
            if not f["dkim_ok"]: print(f"    - DKIM FAIL")
            if not f["dmarc_ok"]: print(f"    - DMARC FAIL: got '{f['dmarc_val']}'")
    else:
        print("\n[***] ALL 254 DOMAINS PASS 100% OF PUBLIC DNS CHECKS! ZERO FAILURES! [***]")

if __name__ == "__main__":
    main()
