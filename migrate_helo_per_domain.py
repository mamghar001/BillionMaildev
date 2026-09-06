#!/usr/bin/env python3
"""
Migration script: Convert per-IP transports to per-domain transports with HELO.

This script:
1. Reads all active multi-IP domains from bm_multi_ip_domain
2. Generates per-domain Postfix transports in master.cf with smtp_helo_name
3. Updates bm_domain_smtp_transport to point each domain to its unique transport
4. Updates bm_multi_ip_domain.smtp_server_name for consistency
"""

import subprocess
import sys
import os
import re
import shutil
from datetime import datetime

# Config
DBUSER = os.environ.get("DBUSER", "billionmail")
DBPASS = os.environ.get("DBPASS", "")
DBNAME = os.environ.get("DBNAME", "billionmail")
PGSQL_CONTAINER = "billionmail-pgsql-billionmail-1"
POSTFIX_CONTAINER = "billionmail-postfix-billionmail-1"
MASTER_CF = "/opt/billionmail/conf/postfix/master.cf"

def psql(cmd):
    """Run a psql command and return stdout."""
    full_cmd = [
        "docker", "exec", "-i", PGSQL_CONTAINER,
        "psql", "-U", DBUSER, "-d", DBNAME, "-t", "-A", "-F", "|",
        "-c", cmd
    ]
    result = subprocess.run(full_cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"PSQL ERROR: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    return result.stdout

def get_domains():
    """Get list of (domain, outbound_ip) tuples."""
    out = psql("SELECT domain, outbound_ip FROM bm_multi_ip_domain WHERE active=1 ORDER BY domain;")
    domains = []
    for line in out.strip().split("\n"):
        if not line.strip():
            continue
        parts = line.split("|")
        if len(parts) == 2:
            domains.append((parts[0].strip(), parts[1].strip()))
    return domains

def make_transport_name(domain, ip):
    """Generate a unique transport name for a domain."""
    domain_slug = domain.replace(".", "_")
    ip_slug = ip.replace(".", "_")
    return f"smtp_bind_ip_{ip_slug}_{domain_slug}"

def remove_old_transports(content):
    """Remove old # Noez IP comments and smtp_bind_ip_* transports from master.cf content."""
    lines = content.split("\n")
    new_lines = []
    i = 0
    while i < len(lines):
        line = lines[i]
        # Check if this is a Noez IP comment
        if re.match(r'^#\s*Noez IP for', line):
            # Skip this comment line and any following blank lines
            i += 1
            while i < len(lines) and lines[i].strip() == "":
                i += 1
            continue
        # Check if this is an old smtp_bind_ip transport line
        if re.match(r'^smtp_bind_ip_\d+_\d+_\d+_\d+\s+unix', line):
            # Skip this line and the next line (smtp_bind_address) and following blank lines
            i += 1
            # Skip the -o smtp_bind_address line if present
            if i < len(lines) and "smtp_bind_address" in lines[i]:
                i += 1
            while i < len(lines) and lines[i].strip() == "":
                i += 1
            continue
        new_lines.append(line)
        i += 1
    return "\n".join(new_lines)

def generate_new_block(domains):
    """Generate the new master.cf transport block."""
    lines = []
    lines.append("")
    lines.append("# BEGIN BILLIONMAIL multi-ip services")
    lines.append("")
    for domain, ip in domains:
        transport = make_transport_name(domain, ip)
        lines.append(f"{transport} unix  -       -       n       -       -       smtp")
        lines.append(f"    -o smtp_bind_address={ip}")
        lines.append(f"    -o smtp_helo_name={domain}")
        lines.append("")
    lines.append("# END BILLIONMAIL multi-ip services")
    lines.append("")
    return "\n".join(lines)

def update_master_cf(domains):
    """Rewrite master.cf with per-domain transports."""
    # Backup
    backup = MASTER_CF + ".helo-migrate-backup-" + datetime.now().strftime("%Y%m%d%H%M%S")
    shutil.copy2(MASTER_CF, backup)
    print(f"Backed up master.cf to {backup}")

    with open(MASTER_CF, "r") as f:
        content = f.read()

    # Remove old transports
    content = remove_old_transports(content)

    # Remove any existing BILLIONMAIL block
    content = re.sub(
        r'\n?# BEGIN BILLIONMAIL multi-ip services.*?# END BILLIONMAIL multi-ip services\n?',
        '\n',
        content,
        flags=re.DOTALL
    )

    # Generate and append new block
    new_block = generate_new_block(domains)
    content = content.rstrip() + "\n" + new_block + "\n"

    with open(MASTER_CF, "w") as f:
        f.write(content)

    print(f"Updated {MASTER_CF} with {len(domains)} per-domain transports")

def update_db(domains):
    """Update bm_domain_smtp_transport and bm_multi_ip_domain."""
    # Clear existing dedicated_ip transport mappings
    psql("DELETE FROM bm_domain_smtp_transport WHERE atype = 'dedicated_ip';")
    print("Cleared old bm_domain_smtp_transport dedicated_ip entries")

    # Build INSERT values
    transport_values = []
    server_name_updates = []
    for domain, ip in domains:
        transport = make_transport_name(domain, ip)
        transport_values.append(f"('dedicated_ip', '@{domain}', '{transport}')")
        server_name_updates.append((domain, transport))

    # Batch insert into bm_domain_smtp_transport
    batch_size = 25
    for i in range(0, len(transport_values), batch_size):
        batch = ", ".join(transport_values[i:i+batch_size])
        psql(f"INSERT INTO bm_domain_smtp_transport (atype, domain, smtp_name) VALUES {batch};")
    print(f"Inserted {len(transport_values)} rows into bm_domain_smtp_transport")

    # Update bm_multi_ip_domain.smtp_server_name
    for domain, transport in server_name_updates:
        psql(f"UPDATE bm_multi_ip_domain SET smtp_server_name = '{transport}' WHERE domain = '{domain}';")
    print(f"Updated {len(server_name_updates)} rows in bm_multi_ip_domain")

def reload_postfix():
    """Reload Postfix to pick up new master.cf."""
    result = subprocess.run(
        ["docker", "exec", POSTFIX_CONTAINER, "postfix", "reload"],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print(f"Postfix reload stderr: {result.stderr}", file=sys.stderr)
    print(f"Postfix reload: {result.stdout.strip()}")

def verify(domains):
    """Verify the transports are in master.cf."""
    with open(MASTER_CF, "r") as f:
        content = f.read()

    missing = []
    for domain, ip in domains:
        transport = make_transport_name(domain, ip)
        if transport not in content:
            missing.append(transport)
        if f"smtp_helo_name={domain}" not in content:
            missing.append(f"HELO for {domain}")

    if missing:
        print(f"WARNING: Missing in master.cf: {missing}")
    else:
        print("Verification passed: all transports and HELO names found in master.cf")

def main():
    print("=" * 60)
    print("HELO Per-Domain Migration Script")
    print("=" * 60)

    domains = get_domains()
    print(f"Found {len(domains)} active multi-IP domains")

    if len(domains) == 0:
        print("No domains found. Exiting.")
        sys.exit(0)

    print("\nSample transports that will be created:")
    for domain, ip in domains[:3]:
        transport = make_transport_name(domain, ip)
        print(f"  {transport} -> {ip} (HELO: {domain})")
    if len(domains) > 3:
        print(f"  ... and {len(domains) - 3} more")

    if os.environ.get("AUTO_CONFIRM") == "1":
        confirm = "yes"
    else:
        confirm = input("\nProceed with migration? (yes/no): ").strip().lower()
    if confirm != "yes":
        print("Aborted.")
        sys.exit(0)

    print("\n[1/4] Updating master.cf...")
    update_master_cf(domains)

    print("\n[2/4] Updating database...")
    update_db(domains)

    print("\n[3/4] Reloading Postfix...")
    reload_postfix()

    print("\n[4/4] Verifying...")
    verify(domains)

    print("\n" + "=" * 60)
    print("Migration complete!")
    print("=" * 60)

if __name__ == "__main__":
    main()
