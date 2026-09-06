import csv
import subprocess
import os

MASTER_CF = "/opt/billionmail/conf/postfix/master.cf"
CSV_PATH = "/root/ip_assignments.csv"

# Backup master.cf
os.system(f"cp {MASTER_CF} {MASTER_CF}.bak.clean_assignment")

# Read assignments
assignments = []
with open(CSV_PATH, 'r') as f:
    for row in csv.DictReader(f):
        domain = row['domain'].strip()
        ip = row['outbound_ip'].strip()
        clean_domain = domain.replace('.', '_')
        clean_ip = ip.replace('.', '_')
        transport_name = f"smtp_bind_ip_{clean_ip}_{clean_domain}"
        helo = f"outbound-{clean_ip.replace('_', '-')}.b2bprosperity.com"
        assignments.append({
            'domain': domain,
            'ip': ip,
            'clean_domain': clean_domain,
            'clean_ip': clean_ip,
            'transport_name': transport_name,
            'helo': helo
        })

print(f"Loaded {len(assignments)} assignments from CSV")

# Read existing master.cf up to the custom transport section
with open(MASTER_CF, 'r') as f:
    lines = f.readlines()

base_lines = []
for line in lines:
    if line.startswith("smtp_bind_ip_"):
        break
    base_lines.append(line)

# Clean trailing whitespace/newlines from base_lines
while base_lines and base_lines[-1].strip() == "":
    base_lines.pop()

# Build new master.cf content
transport_blocks = []
for a in assignments:
    block = f"{a['transport_name']} unix - - n - - smtp\n"
    block += f"    -o smtp_bind_address={a['ip']}\n"
    block += f"    -o smtp_helo_name={a['helo']}\n"
    block += f"    -o syslog_name=postfix-{a['ip'].replace('.', '-')}\n"
    transport_blocks.append(block)

new_master_cf = "".join(base_lines) + "\n\n# BEGIN BILLIONMAIL 77.90.32.X dedicated transports\n" + "\n".join(transport_blocks) + "\n"

with open(MASTER_CF, 'w') as f:
    f.write(new_master_cf)

print(f"Written updated master.cf with {len(assignments)} transports")

# Now update PostgreSQL bm_domain_smtp_transport and domain table
sql_statements = ["BEGIN;"]
for a in assignments:
    domain_key = f"@{a['domain']}"
    sql_statements.append(f"""
    INSERT INTO bm_domain_smtp_transport (atype, domain, smtp_name)
    VALUES ('relay', '{domain_key}', '{a['transport_name']}')
    ON CONFLICT (domain) DO UPDATE SET smtp_name = EXCLUDED.smtp_name, atype = 'relay';
    """)
    sql_statements.append(f"""
    UPDATE domain SET a_record = '{a['ip']}', mailboxes = 101 WHERE domain = '{a['domain']}';
    """)
sql_statements.append("COMMIT;")

sql_script = "\n".join(sql_statements)
with open("/root/update_db_transports.sql", "w") as f:
    f.write(sql_script)

res = subprocess.run(["docker", "exec", "-i", "billionmail-pgsql-billionmail-1", "psql", "-U", "billionmail", "-d", "billionmail"], input=sql_script.encode(), capture_output=True)
if res.returncode == 0:
    print("Database update successful!")
else:
    print("Database update failed:", res.stderr.decode())

