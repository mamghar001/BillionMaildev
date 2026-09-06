#!/usr/bin/env python3
"""
BillionMail + Cloudflare DNS Auto-Configurator
Updates SPF records to include all sending IPs
"""

import requests
import json
import sys
from datetime import datetime

# Configuration
CLOUDFLARE_API_TOKEN = os.environ.get("CLOUDFLARE_API_TOKEN", "")
CLOUDFLARE_API_URL = "https://api.cloudflare.com/client/v4"

# All sending IPs
ALL_IPS = ["85.121.241.162", "85.121.241.250", "85.121.241.251"]

# Domains to update
DOMAINS = [
    "b2bscale.xyz",
    "affiliategrowth.shop",
    "b2bgrowth.shop",
    "aiemail.shop",
    "moescalesystem.shop",
    "aioutboundagents.shop",
    "b2baioutbound.shop",
    "moescale.xyz"
]

def log(message):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {message}")
    sys.stdout.flush()

def get_zone_id(domain):
    """Get Cloudflare Zone ID for domain"""
    headers = {
        "Authorization": f"Bearer {CLOUDFLARE_API_TOKEN}",
        "Content-Type": "application/json"
    }
    
    response = requests.get(
        f"{CLOUDFLARE_API_URL}/zones",
        headers=headers,
        params={"name": domain},
        timeout=30
    )
    
    if response.status_code == 200:
        data = response.json()
        if data.get("success") and data["result"]:
            return data["result"][0]["id"]
    
    log(f"❌ Failed to get zone ID for {domain}: {response.text[:200]}")
    return None

def get_spf_record(zone_id, domain):
    """Get existing SPF record"""
    headers = {
        "Authorization": f"Bearer {CLOUDFLARE_API_TOKEN}",
        "Content-Type": "application/json"
    }
    
    response = requests.get(
        f"{CLOUDFLARE_API_URL}/zones/{zone_id}/dns_records",
        headers=headers,
        params={"type": "TXT", "name": domain},
        timeout=30
    )
    
    if response.status_code == 200:
        data = response.json()
        if data.get("success"):
            for record in data["result"]:
                content = record.get("content", "")
                if "v=spf1" in content:
                    return record["id"], content
    
    return None, None

def update_spf_record(zone_id, record_id, domain, spf_value):
    """Update SPF record"""
    headers = {
        "Authorization": f"Bearer {CLOUDFLARE_API_TOKEN}",
        "Content-Type": "application/json"
    }
    
    data = {
        "type": "TXT",
        "name": domain,
        "content": spf_value,
        "ttl": 300  # 5 minutes for testing
    }
    
    if record_id:
        # Update existing record
        response = requests.put(
            f"{CLOUDFLARE_API_URL}/zones/{zone_id}/dns_records/{record_id}",
            headers=headers,
            json=data,
            timeout=30
        )
    else:
        # Create new record
        response = requests.post(
            f"{CLOUDFLARE_API_URL}/zones/{zone_id}/dns_records",
            headers=headers,
            json=data,
            timeout=30
        )
    
    if response.status_code == 200:
        result = response.json()
        if result.get("success"):
            return True
    
    log(f"❌ Failed to update SPF: {response.text[:200]}")
    return False

def main():
    log("🚀 Cloudflare DNS SPF Updater")
    log("=" * 50)
    
    # Build correct SPF record with all IPs
    spf_ips = ""
    for ip in ALL_IPS:
        spf_ips += f" +ip4:{ip}"
    
    correct_spf = f"v=spf1 +a +mx{spf_ips} ~all"
    
    log(f"Correct SPF record: {correct_spf}")
    log("")
    
    for domain in DOMAINS:
        log(f"Processing {domain}...")
        
        # Get zone ID
        zone_id = get_zone_id(domain)
        if not zone_id:
            log(f"  ⚠️  Skipping {domain} - zone not found")
            continue
        
        # Get current SPF
        record_id, current_spf = get_spf_record(zone_id, domain)
        
        if current_spf:
            log(f"  Current SPF: {current_spf}")
            
            # Check if update needed
            missing_ips = []
            for ip in ALL_IPS:
                if ip not in current_spf:
                    missing_ips.append(ip)
            
            if not missing_ips:
                log(f"  ✅ SPF already correct")
                continue
            
            log(f"  Missing IPs: {', '.join(missing_ips)}")
        else:
            log(f"  No SPF found, creating new one")
        
        # Update SPF
        if update_spf_record(zone_id, record_id, domain, correct_spf):
            log(f"  ✅ SPF updated successfully")
        else:
            log(f"  ❌ Failed to update SPF")
    
    log("")
    log("=" * 50)
    log("Done! DNS changes may take 1-5 minutes to propagate.")

if __name__ == "__main__":
    main()
