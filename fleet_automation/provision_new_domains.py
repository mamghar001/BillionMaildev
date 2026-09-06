#!/usr/bin/env python3
"""
BillionMail Turnkey Domain Provisioning & Fleet Expansion Tool
1. Vacant IP auto-detection (77.90.32.2 - 77.90.32.254).
2. Domain registration in BillionMail DB.
3. 1024-bit RSA DKIM keypair generation for Namecheap BasicDNS compatibility.
4. Rspamd dkim_signing.conf selector injection.
5. Mailbox generation: 4 random female White USA names (firstName.lastName@domain).
6. Outbound IP mapping in bm_multi_ip_domain.
7. Dedicated Postfix transport in master.cf (smtp_bind_address + smtp_helo_name=mail.<domain>).
8. Full DNS provisioning via Namecheap API (A, MX, SPF, DMARC, DKIM).
9. Postfix & Rspamd safe reload.
10. Update ip_assignments.csv, ptr_records_plain.txt, and ptr_records_to_set.csv.
11. Live DNS verification (Cloudflare 1.1.1.1).
"""

import os
import sys
import re
import csv
import time
import json
import random
import shutil
import hashlib
import base64
import binascii
import secrets
import string
import urllib.request
import urllib.parse
import subprocess
from pathlib import Path

# Credentials & Paths
NC_API_USER = os.environ.get("NC_API_USER", "")
NC_API_KEY = os.environ.get("NC_API_KEY", "")
NC_CLIENT_IP = os.environ.get("NC_CLIENT_IP", "5.230.29.58")
NC_ENDPOINT = "https://api.namecheap.com/xml.response"

DKIM_BASE_DIR = "/opt/billionmail/rspamd-data/dkim"
RSPAMD_SIGN_CONF = "/opt/billionmail/conf/rspamd/local.d/dkim_signing.conf"
MASTER_CF = "/opt/billionmail/conf/postfix/master.cf"
CSV_PATH = os.environ.get("CSV_PATH", "/root/ip_assignments.csv")

# Curated pool of female USA first names and common USA surnames
FEMALE_FIRST_NAMES = [
    "emma", "olivia", "sophia", "charlotte", "amelia", "harper", "evelyn", "abigail",
    "emily", "elizabeth", "ella", "avery", "scarlett", "grace", "chloe", "victoria",
    "riley", "aubrey", "zoey", "hannah", "lillian", "addison", "eleanor", "natalie",
    "brooklyn", "leah", "audrey", "claire", "skylar", "lucy", "paisley", "everly",
    "anna", "caroline", "nova", "kennedy", "samantha", "maya", "sarah", "madelyn",
    "allison", "hailey", "kaylee", "autumn", "piper", "ruby", "serenity", "eva",
    "alice", "ivy", "sadie", "sophie", "clara", "hadley", "delilah", "isabelle",
    "quinn", "reagan", "madison", "harley", "georgia", "penelope", "faith", "amber",
    "paige", "sydney", "morgan", "bailey", "lauren", "molly", "brooke", "peyton",
    "shelby", "holly", "destiny", "kendall", "summer", "kelsey", "bethany", "bridget",
    "heather", "jessica", "ashley", "brittany", "amanda", "megan", "rachel", "kayla"
]

USA_LAST_NAMES = [
    "smith", "johnson", "williams", "brown", "jones", "miller", "davis", "wilson",
    "anderson", "taylor", "thomas", "moore", "martin", "jackson", "thompson", "white",
    "harris", "clark", "lewis", "robinson", "walker", "young", "allen", "king",
    "wright", "scott", "green", "baker", "adams", "nelson", "hill", "campbell",
    "mitchell", "roberts", "carter", "phillips", "evans", "turner", "collins", "parker",
    "edwards", "stewart", "morris", "murphy", "cook", "rogers", "cooper", "peterson",
    "reed", "bailey", "bell", "kelly", "howard", "ward", "cox", "richardson",
    "watson", "brooks", "wood", "james", "bennett", "gray", "hughes", "price",
    "sanders", "myers", "long", "ross", "foster", "powell", "jenkins", "perry",
    "russell", "sullivan", "butler", "henderson", "barnes", "fisher", "simmons", "patterson",
    "jordan", "reynolds", "hamilton", "graham", "griffin", "wallace", "west", "cole",
    "hayes", "bryant", "gibson", "ellis", "stevens", "murray", "ford", "marshall"
]

def make_ssha512(password):
    salt = os.urandom(8)
    h = hashlib.sha512()
    h.update(password.encode("utf-8"))
    h.update(salt)
    digest = h.digest()
    return "{SSHA512}" + base64.b64encode(digest + salt).decode("ascii")

def generate_secure_password(length=14):
    chars = string.ascii_letters + string.digits + "!@#$%*"
    while True:
        pwd = ''.join(secrets.choice(chars) for _ in range(length))
        if (any(c.isupper() for c in pwd) and
            any(c.islower() for c in pwd) and
            any(c.isdigit() for c in pwd) and
            any(c in "!@#$%*" for c in pwd)):
            return pwd

def encode_password_for_bm(password):
    return binascii.hexlify(base64.b64encode(password.encode())).decode()

def run_db_query(sql):
    res = subprocess.run([
        "docker", "exec", "billionmail-pgsql-billionmail-1",
        "psql", "-U", "billionmail", "-d", "billionmail", "-t", "-c", sql
    ], capture_output=True, text=True)
    return res.stdout

def get_vacant_ips():
    out = run_db_query("SELECT outbound_ip FROM bm_multi_ip_domain WHERE active=1;")
    active_ips = set(line.strip() for line in out.splitlines() if line.strip())
    vacant = []
    for i in range(2, 255):
        ip = f"77.90.32.{i}"
        if ip not in active_ips:
            vacant.append(ip)
    return vacant

def generate_random_female_names(count=4):
    firsts = random.sample(FEMALE_FIRST_NAMES, count)
    lasts = random.sample(USA_LAST_NAMES, count)
    return list(zip(firsts, lasts))

def generate_1024_dkim(domain):
    cmd = f"docker exec billionmail-rspamd-billionmail-1 rspamadm dkim_keygen -b 1024 -s default -d {domain}"
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if res.returncode != 0:
        raise RuntimeError(f"Failed to generate DKIM for {domain}: {res.stderr}")

    output = res.stdout
    priv_m = re.search(r"(-----BEGIN PRIVATE KEY-----.*?-----END PRIVATE KEY-----)", output, re.DOTALL)
    if not priv_m:
        raise RuntimeError(f"Could not parse private key for {domain}")
    priv_key = priv_m.group(1).strip() + "\n"

    p_m = re.search(r"p=([A-Za-z0-9+/=]+)", output)
    if not p_m:
        raise RuntimeError(f"Could not parse public key for {domain}")
    pub_p = p_m.group(1)
    dkim_txt = f"v=DKIM1; k=rsa; p={pub_p}"

    target_dir = os.path.join(DKIM_BASE_DIR, domain)
    os.makedirs(target_dir, exist_ok=True)
    
    priv_path = os.path.join(target_dir, "default.private")
    pub_path = os.path.join(target_dir, "default.pub")
    
    with open(priv_path, "w") as f:
        f.write(priv_key)
    with open(pub_path, "w") as f:
        f.write(f'default._domainkey IN TXT ( "v=DKIM1; k=rsa;" "p={pub_p}" ) ;\n')

    os.system(f"chown -R 102:104 {target_dir}")
    os.system(f"chmod 644 {priv_path}")
    os.system(f"chmod 644 {pub_path}")

    inject_rspamd_signing_conf(domain)
    return dkim_txt

def inject_rspamd_signing_conf(domain):
    if not os.path.exists(RSPAMD_SIGN_CONF):
        return
    with open(RSPAMD_SIGN_CONF, "r") as f:
        content = f.read()

    block_begin = f"#{domain}_DKIM_BEGIN"
    if block_begin in content:
        return

    sign_block = f"""
#{domain}_DKIM_BEGIN
{domain} {{
   selectors [
    {{
      path: "/var/lib/rspamd/dkim/{domain}/default.private";
      selector: "default";
    }}
  ]
}}
#{domain}_DKIM_END
"""
    if "#BT_DOMAIN_DKIM_END" in content:
        new_content = content.replace("#BT_DOMAIN_DKIM_END", sign_block.strip() + "\n#BT_DOMAIN_DKIM_END")
    else:
        new_content = content + "\n" + sign_block

    with open(RSPAMD_SIGN_CONF, "w") as f:
        f.write(new_content)

def sync_namecheap_dns(domain, ip, dkim_txt):
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
        "HostName6": "default._domainkey", "RecordType6": "TXT", "Address6": dkim_txt, "TTL6": "300",
    }

    url = NC_ENDPOINT + "?" + urllib.parse.urlencode(params)
    for attempt in range(3):
        try:
            req = urllib.request.Request(url)
            with urllib.request.urlopen(req, timeout=30) as r:
                body = r.read().decode("utf-8", errors="ignore")

            if '<ApiResponse Status="OK"' in body:
                return True, "OK"
            errors = re.findall(r'<Error[^>]*>(.*?)</Error>', body)
            err_msg = errors[0] if errors else body[:100]
            time.sleep(2)
        except Exception as e:
            err_msg = str(e)[:100]
            time.sleep(2)

    return False, err_msg

def provision_domain(domain, ip, num_mailboxes=4, dry_run=False):
    print(f"\n[+] Provisioning {domain} -> {ip}...")
    names = generate_random_female_names(num_mailboxes)
    mailboxes_preview = [f"{fn}.{ln}@{domain}" for fn, ln in names]
    
    if dry_run:
        print(f"    [DRY RUN] Domain: {domain}")
        print(f"    [DRY RUN] Outbound IP: {ip}")
        print(f"    [DRY RUN] HELO: mail.{domain}")
        print(f"    [DRY RUN] Mailboxes ({num_mailboxes}): {', '.join(mailboxes_preview)}")
        print(f"    [DRY RUN] DKIM: 1024-bit RSA key for Namecheap BasicDNS")
        return True

    # 1. DB Domain Table
    sql_domain = f"""INSERT INTO domain (domain, a_record, mailboxes, mailbox_quota, quota, rate_limit, create_time, active, urls, hasbrandinfo, current_usage)
VALUES ('{domain}', '{ip}', 50, 5368709120, 10737418240, 12, EXTRACT(EPOCH FROM NOW())::INT, 1, '{{}}', 0, 0)
ON CONFLICT (domain) DO UPDATE SET active=1, a_record='{ip}';"""
    run_db_query(sql_domain)
    
    # 2. DKIM Keypair & Rspamd config
    dkim_txt = generate_1024_dkim(domain)
    print(f"    - Generated 1024-bit DKIM & configured Rspamd")

    # 3. Create Mailboxes (4 random female names)
    created_mailboxes = []
    for first, last in names:
        local_part = f"{first}.{last}"
        username = f"{local_part}@{domain}"
        full_name = f"{first.title()} {last.title()}"
        maildir = f"/var/vmail/{domain}/{local_part}/"
        password = generate_secure_password(14)
        pwd_hash = make_ssha512(password)
        pwd_enc = encode_password_for_bm(password)
        now = int(time.time())
        sql_mb = f"""INSERT INTO mailbox (username, password, password_encode, full_name, is_admin, maildir, quota, local_part, domain, create_time, update_time, active, used_quota, quota_active)
VALUES ('{username}', '{pwd_hash}', '{pwd_enc}', '{full_name}', 0, '{maildir}', 0, '{local_part}', '{domain}', {now}, {now}, 1, 0, 1)
ON CONFLICT (username) DO UPDATE SET active=1, password='{pwd_hash}', password_encode='{pwd_enc}';"""
        run_db_query(sql_mb)

        # Mailbox forwarding alias to all_replies@b2bprosperity.com
        sql_alias = f"""INSERT INTO alias (address, goto, domain, create_time, update_time, active)
VALUES ('{username}', 'all_replies@b2bprosperity.com', '{domain}', {now}, {now}, 1)
ON CONFLICT (address) DO UPDATE SET goto='all_replies@b2bprosperity.com', active=1;"""
        run_db_query(sql_alias)

        created_mailboxes.append((username, password, full_name))

    # Domain catch-all forwarding alias to all_replies@b2bprosperity.com
    now_ts = int(time.time())
    sql_catchall = f"""INSERT INTO alias (address, goto, domain, create_time, update_time, active)
VALUES ('@{domain}', 'all_replies@b2bprosperity.com', '{domain}', {now_ts}, {now_ts}, 1)
ON CONFLICT (address) DO UPDATE SET goto='all_replies@b2bprosperity.com', active=1;"""
    run_db_query(sql_catchall)

    # Save domain CSV to /opt/billionmail/mailboxes/
    mb_dir = "/opt/billionmail/mailboxes"
    os.makedirs(mb_dir, exist_ok=True)
    clean_d = domain.replace(".", "_")
    csv_file = os.path.join(mb_dir, f"mailboxes_{clean_d}.csv")
    with open(csv_file, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["Email", "Password", "Full Name"])
        for em, pw, fn in created_mailboxes:
            w.writerow([em, pw, fn])
    os.chmod(csv_file, 0o644)
    shutil.chown(csv_file, user=1000, group=1000)

    print(f"    - Created {num_mailboxes} active female mailboxes with automatic forwarding to all_replies@b2bprosperity.com")
    print(f"    - Saved credentials CSV: {csv_file}")

    # 4. Multi IP DB Mapping
    clean_domain = domain.replace(".", "_")
    clean_ip = ip.replace(".", "_")
    transport_name = f"smtp_bind_ip_{clean_ip}_{clean_domain}"
    now_multi = int(time.time())

    sql_multi_ip = f"""INSERT INTO bm_multi_ip_domain (domain, outbound_ip, network_name, subnet, postfix_ip, aliases, smtp_server_name, active, create_time, update_time, status)
VALUES ('{domain}', '{ip}', 'noez', '127.0.0.2/32', '{ip}', '', '{transport_name}', 1, {now_multi}, {now_multi}, 'active')
ON CONFLICT (domain, outbound_ip) DO UPDATE SET outbound_ip='{ip}', active=1, status='active', smtp_server_name='{transport_name}';"""
    run_db_query(sql_multi_ip)
    print(f"    - Mapped {domain} -> {ip} in bm_multi_ip_domain")

    # 5. Postfix SMTP transport DB
    sql_transport = f"""INSERT INTO bm_domain_smtp_transport (atype, domain, smtp_name)
VALUES ('relay', '@{domain}', '{transport_name}')
ON CONFLICT (domain) DO UPDATE SET smtp_name='{transport_name}', atype='relay';"""
    run_db_query(sql_transport)

    # 6. Postfix master.cf transport block
    block = f"""
{transport_name} unix - - n - - smtp
    -o smtp_bind_address={ip}
    -o smtp_helo_name=mail.{domain}
    -o syslog_name=postfix-{ip.replace(".", "-")}
"""
    with open(MASTER_CF, "r") as f:
        master_content = f.read()
    if transport_name not in master_content:
        with open(MASTER_CF, "a") as f:
            f.write(block)
        print(f"    - Added transport {transport_name} (helo: mail.{domain}) to master.cf")

    # 7. Namecheap DNS API
    ok, msg = sync_namecheap_dns(domain, ip, dkim_txt)
    if ok:
        print(f"    - Namecheap DNS: Successfully applied all 6 records (A, MX, SPF, DKIM, DMARC)!")
    else:
        print(f"    - [WARNING] Namecheap DNS API returned: {msg}")

    # 8. Append to ip_assignments.csv
    with open(CSV_PATH, "a", newline="") as f:
        writer = csv.writer(f)
        writer.writerow([f"task_{domain}", "namecheap", domain, ip])

    return ok

def verify_domain_dns(domain, expected_ip):
    try:
        res = subprocess.check_output(["dig", "+short", f"mail.{domain}", "@1.1.1.1"], timeout=5).decode().strip().splitlines()
        if expected_ip in res:
            return True, "Verified (A record resolving)"
        return False, f"Not resolving yet (got {res})"
    except Exception as e:
        return False, str(e)

def main():
    if len(sys.argv) < 2:
        print("\nUsage:")
        print("  python3 /root/provision_new_domains.py domain1.shop domain2.shop ...")
        print("  python3 /root/provision_new_domains.py --file list_of_domains.txt")
        print("  python3 /root/provision_new_domains.py --dry-run domain1.shop ...")
        print("  python3 /root/provision_new_domains.py --status (show vacant IPs)")
        return

    dry_run = "--dry-run" in sys.argv
    args = [a for a in sys.argv[1:] if a != "--dry-run"]

    if "--status" in args:
        vacant = get_vacant_ips()
        print(f"Total vacant IPs available: {len(vacant)}")
        for idx, ip in enumerate(vacant, 1):
            print(f"  {idx:2d}. {ip}")
        return

    domains = []
    if args and args[0] == "--file":
        with open(args[1]) as f:
            for line in f:
                d = line.strip().lower()
                if d and not d.startswith("#"):
                    domains.append(d)
    else:
        for arg in args:
            d = arg.strip().lower()
            if d:
                domains.append(d)

    vacant_ips = get_vacant_ips()
    print(f"Found {len(vacant_ips)} vacant IPs available.")
    print(f"Domains to provision ({len(domains)}): {domains}")

    if len(domains) > len(vacant_ips):
        print(f"\n[ERROR] Requested {len(domains)} domains, but only {len(vacant_ips)} vacant IPs exist!")
        return

    results = []
    for idx, domain in enumerate(domains):
        ip = vacant_ips[idx]
        ok = provision_domain(domain, ip, num_mailboxes=4, dry_run=dry_run)
        results.append((domain, ip, ok))
        if not dry_run:
            time.sleep(1.0)

    if dry_run:
        print("\n[DRY RUN COMPLETE] No system files or DNS records were modified.")
        return

    # Reload Postfix & Rspamd
    print("\n[+] Reloading Postfix and Rspamd services...")
    subprocess.run(["docker", "exec", "billionmail-postfix-billionmail-1", "postfix", "reload"])
    subprocess.run(["docker", "exec", "billionmail-rspamd-billionmail-1", "pkill", "-HUP", "rspamd"])

    # Regenerate PTR files
    print("[+] Updating PTR files...")
    subprocess.run(["python3", "-c", """
import subprocess, csv
db_out = subprocess.check_output([
    'docker', 'exec', 'billionmail-pgsql-billionmail-1',
    'psql', '-U', 'billionmail', '-d', 'billionmail', '-t',
    '-c', 'SELECT outbound_ip, domain FROM bm_multi_ip_domain WHERE active=1;'
]).decode()
entries = []
for line in db_out.splitlines():
    parts = line.strip().split('|')
    if len(parts) == 2:
        ip, dom = parts[0].strip(), parts[1].strip()
        if ip and dom:
            entries.append((ip, dom, f'mail.{dom}'))
entries.sort(key=lambda x: [int(o) for o in x[0].split('.')])
with open('/root/ptr_records_to_set.csv', 'w', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['IP_Address', 'Domain', 'PTR_Record_To_Set'])
    for ip, dom, ptr in entries:
        writer.writerow([ip, dom, ptr])
with open('/root/ptr_records_plain.txt', 'w') as f:
    for ip, dom, ptr in entries:
        f.write(f'{ip} -> {ptr}\n')
print(f'Done! Total active PTRs now: {len(entries)}')
"""])

    # DNS verification check
    print("\n[+] Verifying DNS Propagation (Cloudflare 1.1.1.1):")
    for domain, ip, _ in results:
        v_ok, v_msg = verify_domain_dns(domain, ip)
        status = "PASS" if v_ok else "PENDING"
        print(f"  [{status}] {domain:30} -> {ip} ({v_msg})")

    print("\n==========================================")
    print(f"SUCCESS: {len(domains)} DOMAINS PROVISIONED WITH 4 MAILBOXES EACH!")
    print("==========================================")

if __name__ == "__main__":
    main()
