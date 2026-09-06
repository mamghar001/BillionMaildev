#!/usr/bin/env python3
"""
Setup mail forwards for multiple mailboxes to one destination
Usage: python3 setup_forwards.py
"""

import requests
import time
import sys

# ============================================
# CONFIGURATION - FILL THESE IN
# ============================================

# Your BillionMail API Token (from Settings → API)
API_TOKEN = "YOUR_API_TOKEN_HERE"

# Your BillionMail domain (e.g., https://mail.yourdomain.com)
BASE_URL = "https://YOUR_DOMAIN"

# Destination mailbox where all emails will be forwarded
DESTINATION = "destination@yourdomain.com"

# ============================================
# MAILBOXES TO FORWARD (50 mailboxes)
# ============================================

SOURCE_MAILBOXES = [
    "rotationTest0me@moescale.xyz",
    "rotationTest1pz@moescale.xyz",
    "rotationTest2lx@moescale.xyz",
    "rotationTest3lf@moescale.xyz",
    "rotationTest4is@moescale.xyz",
    "rotationTest5ae@moescale.xyz",
    "rotationTest6gh@moescale.xyz",
    "rotationTest7ut@moescale.xyz",
    "rotationTest8di@moescale.xyz",
    "rotationTest9gd@moescale.xyz",
    "rotationTest10wv@moescale.xyz",
    "rotationTest11cd@moescale.xyz",
    "rotationTest12qd@moescale.xyz",
    "rotationTest13uy@moescale.xyz",
    "rotationTest14fg@moescale.xyz",
    "rotationTest15nb@moescale.xyz",
    "rotationTest16nn@moescale.xyz",
    "rotationTest17si@moescale.xyz",
    "rotationTest18yz@moescale.xyz",
    "rotationTest19lh@moescale.xyz",
    "rotationTest20yx@moescale.xyz",
    "rotationTest21rt@moescale.xyz",
    "rotationTest22jz@moescale.xyz",
    "rotationTest23vv@moescale.xyz",
    "rotationTest24kl@moescale.xyz",
    "rotationTest25bs@moescale.xyz",
    "rotationTest26oz@moescale.xyz",
    "rotationTest27xl@moescale.xyz",
    "rotationTest28cg@moescale.xyz",
    "rotationTest29jh@moescale.xyz",
    "rotationTest30uk@moescale.xyz",
    "rotationTest31la@moescale.xyz",
    "rotationTest32nu@moescale.xyz",
    "rotationTest33qs@moescale.xyz",
    "rotationTest34nt@moescale.xyz",
    "rotationTest35zc@moescale.xyz",
    "rotationTest36ae@moescale.xyz",
    "rotationTest37zz@moescale.xyz",
    "rotationTest38fk@moescale.xyz",
    "rotationTest39db@moescale.xyz",
    "rotationTest40ug@moescale.xyz",
    "rotationTest41qc@moescale.xyz",
    "rotationTest42vr@moescale.xyz",
    "rotationTest43fb@moescale.xyz",
    "rotationTest44ly@moescale.xyz",
    "rotationTest45zg@moescale.xyz",
    "rotationTest46ga@moescale.xyz",
    "rotationTest47qv@moescale.xyz",
    "rotationTest48jk@moescale.xyz",
    "rotationTest49mc@moescale.xyz",
]

# ============================================
# SCRIPT - DO NOT MODIFY BELOW
# ============================================

def create_forward(source_email, destination_email):
    """Create a mail forward via API"""
    url = f"{BASE_URL}/api/mail_forward/add"
    
    headers = {
        "Authorization": f"Bearer {API_TOKEN}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "address": source_email,
        "goto": destination_email,
        "active": 1
    }
    
    try:
        response = requests.post(url, json=payload, headers=headers, timeout=30)
        result = response.json()
        
        if response.status_code == 200 and result.get("code") == 0:
            print(f"✅ SUCCESS: {source_email} → {destination_email}")
            return True
        else:
            error_msg = result.get("message", "Unknown error")
            print(f"❌ FAILED: {source_email} - {error_msg}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"❌ ERROR: {source_email} - {str(e)}")
        return False

def main():
    print("=" * 60)
    print("BillionMail Bulk Forward Setup")
    print("=" * 60)
    print(f"\nDestination: {DESTINATION}")
    print(f"Total mailboxes to forward: {len(SOURCE_MAILBOXES)}")
    print(f"API URL: {BASE_URL}")
    print()
    
    # Validate configuration
    if API_TOKEN == "YOUR_API_TOKEN_HERE":
        print("❌ ERROR: Please set your API_TOKEN in the script!")
        sys.exit(1)
    
    if BASE_URL == "https://YOUR_DOMAIN":
        print("❌ ERROR: Please set your BASE_URL in the script!")
        sys.exit(1)
    
    print("Starting in 3 seconds... Press Ctrl+C to cancel")
    time.sleep(3)
    print()
    
    success_count = 0
    failed_count = 0
    
    for i, mailbox in enumerate(SOURCE_MAILBOXES, 1):
        print(f"[{i}/{len(SOURCE_MAILBOXES)}] ", end="")
        
        if create_forward(mailbox, DESTINATION):
            success_count += 1
        else:
            failed_count += 1
        
        # Small delay to avoid overwhelming the API
        time.sleep(0.5)
    
    print()
    print("=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(f"✅ Successful: {success_count}")
    print(f"❌ Failed: {failed_count}")
    print(f"📊 Total: {len(SOURCE_MAILBOXES)}")
    print()
    
    if failed_count == 0:
        print("🎉 All forwards created successfully!")
    else:
        print("⚠️  Some forwards failed. Check errors above.")
        sys.exit(1)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n❌ Cancelled by user")
        sys.exit(1)
