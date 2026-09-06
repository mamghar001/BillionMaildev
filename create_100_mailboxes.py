#!/usr/bin/env python3
"""
Create 100 mailboxes + forwarding aliases for a domain using BillionMail API
Usage: python3 create_100_mailboxes.py <domain>
Example: python3 create_100_mailboxes.py b2bgrowth.store

Email format: firstname.lastname@domain
Names: USA white women's names
Display name: Camel Case (Firstname Lastname)

API token is read from .env file (BM_API_TOKEN and BM_API_URL)
Also creates forwarding aliases in PostgreSQL (default: all_replies@moescale.site)
"""

import requests
import time
import sys
import random
import argparse
import os
import subprocess

# ============================================
# LOAD CONFIG FROM .ENV FILE
# ============================================

def load_env_file(filepath="/opt/billionmail/.env"):
    """Load environment variables from .env file"""
    env_vars = {}
    try:
        with open(filepath, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    env_vars[key] = value
    except FileNotFoundError:
        print(f"Warning: .env file not found at {filepath}")
    except Exception as e:
        print(f"Warning: Error reading .env file: {e}")
    return env_vars

# Load from .env file
env = load_env_file()

# Get API credentials from environment or .env file
API_TOKEN = os.environ.get('BM_API_TOKEN') or env.get('BM_API_TOKEN', '')
BASE_URL = os.environ.get('BM_API_URL') or env.get('BM_API_URL', 'https://mail.moescale.site')

if not API_TOKEN:
    print("❌ Error: BM_API_TOKEN not found in environment or .env file")
    print("Please set it in /opt/billionmail/.env or export BM_API_TOKEN")
    sys.exit(1)

MAILBOX_COUNT = 100

# USA White Women First Names
FIRST_NAMES = [
    "Emma", "Olivia", "Ava", "Isabella", "Sophia", "Mia", "Charlotte", "Amelia", "Evelyn", "Abigail",
    "Harper", "Emily", "Elizabeth", "Avery", "Sofia", "Ella", "Madison", "Scarlett", "Victoria", "Aria",
    "Grace", "Chloe", "Camila", "Penelope", "Riley", "Layla", "Lillian", "Nora", "Zoey", "Mila",
    "Aubrey", "Hannah", "Lily", "Addison", "Eleanor", "Natalie", "Luna", "Savannah", "Brooklyn", "Leah",
    "Zoe", "Stella", "Hazel", "Ellie", "Paisley", "Audrey", "Skylar", "Violet", "Claire", "Bella",
    "Aurora", "Lucy", "Anna", "Samantha", "Caroline", "Genesis", "Aaliyah", "Kennedy", "Kinsley", "Allison",
    "Maya", "Sarah", "Madelyn", "Adeline", "Alexa", "Ariana", "Elena", "Gabriella", "Naomi", "Alice",
    "Sadie", "Hailey", "Eva", "Emilia", "Autumn", "Quinn", "Nevaeh", "Piper", "Ruby", "Serenity",
    "Willow", "Everly", "Cora", "Kaylee", "Lydia", "Aubree", "Arianna", "Eliana", "Peyton", "Melanie",
    "Gianna", "Isabelle", "Julia", "Valentina", "Nova", "Clara", "Vivian", "Reagan", "Mackenzie", "Madeline"
]

# USA White Women Last Names
LAST_NAMES = [
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez",
    "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin",
    "Lee", "Perez", "Thompson", "White", "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson",
    "Walker", "Young", "Allen", "King", "Wright", "Scott", "Torres", "Nguyen", "Hill", "Flores",
    "Green", "Adams", "Nelson", "Baker", "Hall", "Rivera", "Campbell", "Mitchell", "Carter", "Roberts",
    "Gomez", "Phillips", "Evans", "Turner", "Diaz", "Parker", "Cruz", "Edwards", "Collins", "Reyes",
    "Stewart", "Morris", "Morales", "Murphy", "Cook", "Rogers", "Gutierrez", "Ortiz", "Morgan", "Cooper",
    "Peterson", "Bailey", "Reed", "Kelly", "Howard", "Ramos", "Kim", "Cox", "Ward", "Richardson",
    "Watson", "Brooks", "Chavez", "Wood", "James", "Bennett", "Gray", "Mendoza", "Ruiz", "Hughes",
    "Price", "Alvarez", "Castillo", "Sanders", "Patel", "Myers", "Long", "Ross", "Foster", "Jimenez"
]

def generate_unique_names(count):
    """Generate unique firstname.lastname combinations"""
    names = []
    used_combinations = set()
    
    # If we need more than possible combinations, we'll need to add numbers
    max_combinations = len(FIRST_NAMES) * len(LAST_NAMES)
    
    if count > max_combinations:
        print(f"Warning: Requested {count} names but only {max_combinations} unique combinations possible")
    
    attempts = 0
    while len(names) < count and attempts < count * 10:
        first = random.choice(FIRST_NAMES)
        last = random.choice(LAST_NAMES)
        combo = f"{first.lower()}.{last.lower()}"
        
        if combo not in used_combinations:
            used_combinations.add(combo)
            names.append({
                "first": first,
                "last": last,
                "combo": combo,
                "full_name": f"{first} {last}"
            })
        attempts += 1
    
    # If we still don't have enough, add numbers to make them unique
    counter = 1
    while len(names) < count:
        first = random.choice(FIRST_NAMES)
        last = random.choice(LAST_NAMES)
        combo = f"{first.lower()}.{last.lower()}{counter}"
        
        if combo not in [n["combo"] for n in names]:
            names.append({
                "first": first,
                "last": last,
                "combo": combo,
                "full_name": f"{first} {last}"
            })
        counter += 1
    
    return names

def generate_password():
    """Generate a random secure password"""
    chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
    return ''.join(random.choice(chars) for _ in range(12))

def create_mailbox(domain, local_part, full_name, password):
    """Create a single mailbox via API"""
    url = f"{BASE_URL}/api/mailbox/create"
    
    headers = {
        "Authorization": f"Bearer {API_TOKEN}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "domain": domain,
        "local_part": local_part,
        "full_name": full_name,
        "password": password,
        "active": 1,
        "isAdmin": 0,
        "quota": 5242880,
        "quota_active": 1
    }
    
    try:
        response = requests.post(url, json=payload, headers=headers, timeout=30)
        result = response.json()
        
        if response.status_code == 200 and result.get("code") == 0:
            return True, "Success"
        else:
            error_msg = result.get("message", "Unknown error")
            return False, error_msg
            
    except requests.exceptions.RequestException as e:
        return False, str(e)


def create_aliases(created_mailboxes, domain, forward_to):
    """Create forwarding aliases in PostgreSQL for all created mailboxes"""
    import time as time_module
    
    current_time = int(time_module.time())
    container = "billionmail-pgsql-billionmail-1"
    
    print()
    print("=" * 70)
    print("CREATING FORWARDING ALIASES")
    print("=" * 70)
    print(f"Forward target: {forward_to}")
    print()
    
    success_count = 0
    fail_count = 0
    
    for i, mb in enumerate(created_mailboxes, 1):
        email = mb["email"]
        print(f"[{i:3d}/{len(created_mailboxes)}] Alias {email:<45} → {forward_to} ... ", end="", flush=True)
        
        sql = (
            f"INSERT INTO alias (address, goto, domain, create_time, update_time, active) "
            f"VALUES ('{email}', '{forward_to}', '{domain}', {current_time}, {current_time}, 1) "
            f"ON CONFLICT (address) DO UPDATE SET goto = '{forward_to}', active = 1;"
        )
        
        try:
            result = subprocess.run(
                ["docker", "exec", container, "psql", "-U", "billionmail", "-d", "billionmail", "-c", sql],
                capture_output=True, text=True, timeout=30
            )
            if result.returncode == 0:
                print("✅ OK")
                success_count += 1
            else:
                err = result.stderr.strip() if result.stderr else "Unknown DB error"
                print(f"❌ FAILED: {err}")
                fail_count += 1
        except Exception as e:
            print(f"❌ FAILED: {e}")
            fail_count += 1
        
        time.sleep(0.05)
    
    print()
    print("=" * 70)
    print("ALIAS SUMMARY")
    print("=" * 70)
    print(f"✅ Successful: {success_count}")
    print(f"❌ Failed: {fail_count}")
    print()
    
    return success_count, fail_count

def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(
        description='Create 100 mailboxes with USA women names for a domain',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  python3 create_100_mailboxes.py b2bgrowth.store
  python3 create_100_mailboxes.py mydomain.com
  python3 create_100_mailboxes.py another-domain.org
        '''
    )
    parser.add_argument('domain', help='Domain name to create mailboxes for (e.g., b2bgrowth.store)')
    parser.add_argument('--skip-confirm', action='store_true', help='Skip confirmation prompt (for automated runs)')
    parser.add_argument('--forward-to', default='all_replies@moescale.site', 
                        help='Email address to forward all mailboxes to (default: all_replies@moescale.site)')
    parser.add_argument('--no-aliases', action='store_true', 
                        help='Skip creating forwarding aliases (mailboxes only)')
    args = parser.parse_args()
    
    domain = args.domain
    
    print("=" * 70)
    print("BillionMail Mailbox Creator")
    print("=" * 70)
    print(f"Domain: {domain}")
    print(f"Count: {MAILBOX_COUNT} mailboxes")
    print(f"Name Format: Firstname.Lastname (Camel Case Display)")
    print(f"API URL: {BASE_URL}")
    print("=" * 70)
    print()
    
    # Generate unique names
    print("Generating unique names...")
    names = generate_unique_names(MAILBOX_COUNT)
    print(f"✓ Generated {len(names)} unique name combinations")
    print()
    
    # Confirmation prompt (unless --skip-confirm)
    if not args.skip_confirm:
        print(f"This will create {MAILBOX_COUNT} mailboxes for {domain}")
        response = input("Continue? (yes/no): ").strip().lower()
        if response not in ['yes', 'y']:
            print("Cancelled.")
            return 0
        print()
    
    # Prepare results storage
    created_mailboxes = []
    failed_mailboxes = []
    
    print("Starting mailbox creation...")
    print("-" * 70)
    
    for i, name_info in enumerate(names, 1):
        password = generate_password()
        email = f"{name_info['combo']}@{domain}"
        
        print(f"[{i:3d}/{MAILBOX_COUNT}] Creating {email:<45} ... ", end="", flush=True)
        
        success, msg = create_mailbox(
            domain,
            name_info["combo"],
            name_info["full_name"],
            password
        )
        
        if success:
            print("✅ OK")
            created_mailboxes.append({
                "email": email,
                "password": password,
                "full_name": name_info["full_name"]
            })
        else:
            print(f"❌ FAILED: {msg}")
            failed_mailboxes.append({
                "email": email,
                "error": msg
            })
        
        # Small delay to avoid overwhelming the API
        time.sleep(0.3)
    
    print()
    print("=" * 70)
    print("SUMMARY")
    print("=" * 70)
    print(f"✅ Successful: {len(created_mailboxes)}")
    print(f"❌ Failed: {len(failed_mailboxes)}")
    print(f"📊 Total: {MAILBOX_COUNT}")
    print()
    
    # Create mailboxes directory if it doesn't exist
    output_dir = "mailboxes"
    os.makedirs(output_dir, exist_ok=True)
    
    # Save successful mailboxes to CSV
    if created_mailboxes:
        csv_filename = os.path.join(output_dir, f"mailboxes_{domain.replace('.', '_')}.csv")
        with open(csv_filename, 'w') as f:
            f.write("Email,Password,Full Name\n")
            for mb in created_mailboxes:
                f.write(f"{mb['email']},{mb['password']},{mb['full_name']}\n")
        print(f"💾 Saved {len(created_mailboxes)} mailboxes to: {csv_filename}")
    
    # Save failed mailboxes to log
    if failed_mailboxes:
        error_filename = os.path.join(output_dir, f"failed_mailboxes_{domain.replace('.', '_')}.log")
        with open(error_filename, 'w') as f:
            for mb in failed_mailboxes:
                f.write(f"{mb['email']}: {mb['error']}\n")
        print(f"⚠️  Saved {len(failed_mailboxes)} failures to: {error_filename}")
    
    print()
    
    # Create forwarding aliases if mailboxes were created and not skipped
    if created_mailboxes and not args.no_aliases:
        alias_success, alias_fail = create_aliases(created_mailboxes, domain, args.forward_to)
    
    if len(failed_mailboxes) == 0:
        print("🎉 All mailboxes created successfully!")
        if not args.no_aliases and created_mailboxes:
            print(f"📤 All {len(created_mailboxes)} aliases forwarding to {args.forward_to}")
        return 0
    else:
        print(f"⚠️  {len(failed_mailboxes)} mailboxes failed. Check {error_filename} for details.")
        return 1

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n\n❌ Cancelled by user")
        sys.exit(1)
