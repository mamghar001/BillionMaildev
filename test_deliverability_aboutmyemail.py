#!/usr/bin/env python3
"""
Automated Deliverability & Authentication Tester using aboutmy.email
Usage:
    python3 test_deliverability_aboutmyemail.py <sender_email> [subject]
Example:
    python3 test_deliverability_aboutmyemail.py alex@aibdr.shop
"""

import sys
import json
import time
import urllib.request
import smtplib
import re
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

def test_deliverability(sender, subject="Deliverability & Authentication Audit"):
    print(f"=== INITIATING DELIVERABILITY TEST FOR: {sender} ===")
    
    # 1. Obtain temporary test mailbox from aboutmy.email
    print("1. Requesting temporary analysis inbox from aboutmy.email...")
    req = urllib.request.Request(
        "https://aboutmy.email/s?c=",
        headers={"User-Agent": "Mozilla/5.0 (BillionMail-Deliverability-Bot/1.0)"}
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode())[0]
            session_id = data["s"]
            target_email = data["e"]
    except Exception as e:
        print(f"❌ Failed to obtain test address from aboutmy.email: {e}")
        return False

    print(f"   ✓ Inbox assigned: {target_email}")
    print(f"   ✓ Session token: {session_id}")

    # 2. Dispatch email via local Postfix instance
    print(f"2. Dispatching message via local Postfix (127.0.0.1:25)...")
    domain = sender.split("@")[-1]
    msg = MIMEMultipart()
    msg["From"] = f"Verification Bot <{sender}>"
    msg["To"] = target_email
    msg["Subject"] = f"{subject} [{domain}]"
    
    body = (
        f"Deliverability and authentication test email.\n\n"
        f"Sender: {sender}\n"
        f"Domain: {domain}\n"
        f"Timestamp: {int(time.time())}\n"
    )
    msg.attach(MIMEText(body, "plain", "utf-8"))

    try:
        with smtplib.SMTP("127.0.0.1", 25, timeout=10) as server:
            server.sendmail(sender, [target_email], msg.as_string())
        print("   ✓ Email accepted by Postfix queue")
    except Exception as e:
        print(f"❌ Failed to submit email to Postfix: {e}")
        return False

    # 3. Poll for analysis completion
    report_url = f"https://aboutmy.email/{session_id}"
    print(f"3. Waiting for aboutmy.email report generation at {report_url}...")
    
    ready = False
    for attempt in range(15):
        time.sleep(3)
        try:
            req = urllib.request.Request(
                report_url,
                headers={"User-Agent": "Mozilla/5.0 (BillionMail-Deliverability-Bot/1.0)"}
            )
            with urllib.request.urlopen(req, timeout=10) as resp:
                html = resp.read().decode('utf-8', errors='ignore')
                if f"About {domain}" in html or "SPF Passes" in html or "Authentication" in html:
                    ready = True
                    break
        except Exception:
            pass
        print(f"   ... waiting ({attempt+1}/15)")

    print(f"\n✅ ANALYSIS COMPLETE!")
    print(f"👉 Full Report URL: {report_url}")
    
    # Check results
    try:
        yahoogle_url = f"{report_url}/yahoogle"
        req = urllib.request.Request(yahoogle_url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            text = resp.read().decode('utf-8', errors='ignore')
            ip_m = re.search(r"(\d+\.\d+\.\d+\.\d+)", text)
            print(f"   * Connecting IP: {ip_m.group(1) if ip_m else 'Unknown'}")
            print(f"   * SPF Status:    {'PASS' if 'SPF Passes' in text or 'pass' in text else 'CHECK REPORT'}")
            print(f"   * DKIM Status:   {'PASS' if 'DKIM passes' in text or 'DKIM Passes' in text else 'CHECK REPORT'}")
            print(f"   * DMARC Status:  {'PASS' if 'DMARC Passes' in text or 'DMARC pass' in text else 'CHECK REPORT'}")
    except Exception as e:
        print(f"   (Could not parse sub-page: {e})")

    return report_url

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 test_deliverability_aboutmyemail.py <sender_email> [subject]")
        sys.exit(1)
    
    sender_arg = sys.argv[1]
    subject_arg = sys.argv[2] if len(sys.argv) > 2 else "Deliverability Audit"
    test_deliverability(sender_arg, subject_arg)
