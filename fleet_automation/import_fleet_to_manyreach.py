#!/usr/bin/env python3
"""
ManyReach Automated Fleet Importer
Imports all 1,012 mailboxes into ManyReach via API with calibrated warmup settings.
- Warmup Daily Limit: 12 (Day 1)
- Increase Percent: 20% per day (+2 to 3 emails/day)
- Warmup Max: 30 emails/day (reached in ~4-5 days)
- Reply Percent: 30%
- Warmup Tag: Strachka
- Daily Outreach Limit: 50 (delay 5 min)
"""

import sys
import os
import csv
import time
import json
import urllib.request
import urllib.parse
import urllib.error

API_URL = "https://app.manyreach.com/api/v2"
API_KEY = os.environ.get("MANYREACH_API_KEY", "")
CSV_PATH = os.environ.get("CSV_PATH", "/root/manyreach_fleet_mailboxes.csv")
LOG_PATH = "/tmp/manyreach_import_progress.log"
FAILURES_PATH = "/tmp/manyreach_failed_imports.txt"

SIGNATURE_TEMPLATE = """<div style="font-family: Arial, sans-serif; font-size: 14px; color: #333;">
<p>Best,<br><strong style="font-family: inherit;">{name}</strong><br>B2B Growth Specialist</p>
<p style="font-size: 12px; color: #666;">Helping B2B teams book 10+ extra meetings/month with autonomous AI outbound SDRs.<br>
📅 <a href="https://tidycal.com/influencraftcom/intro-call" style="color: #2563eb;">Book 15 min with me</a></p>
<p style="font-size: 11px; color: #999;">This email and any attachments are confidential. If you are not the intended recipient, please delete this email and notify the sender.</p>
</div>"""

def mr_call(method, endpoint, data=None, params=None, retries=4):
    url = f"{API_URL}/{endpoint.lstrip('/')}"
    if params:
        url += "?" + urllib.parse.urlencode(params)
    
    body = json.dumps(data).encode("utf-8") if data is not None else None
    headers = {
        "User-Agent": "ManyReachFleetProvisioner/1.0",
        "Accept": "application/json",
        "Content-Type": "application/json",
        "X-API-Key": API_KEY,
    }

    for attempt in range(retries):
        req = urllib.request.Request(url, data=body, method=method, headers=headers)
        try:
            with urllib.request.urlopen(req, timeout=40) as r:
                resp_data = r.read().decode("utf-8", errors="ignore")
                try:
                    return r.status, json.loads(resp_data)
                except json.JSONDecodeError:
                    return r.status, {"raw": resp_data}
        except urllib.error.HTTPError as e:
            err_body = e.read().decode("utf-8", errors="ignore")
            if e.code == 429:
                wait_time = 5 * (attempt + 1)
                print(f"    [!] Rate limited (429). Backing off for {wait_time}s...")
                time.sleep(wait_time)
                continue
            try:
                parsed = json.loads(err_body)
                return e.code, parsed
            except Exception:
                return e.code, {"error": err_body}
        except Exception as e:
            if attempt < retries - 1:
                time.sleep(2 * (attempt + 1))
                continue
            return 500, {"error": str(e)}

    return 429, {"error": "Exceeded retries on 429"}

def get_existing_senders():
    """Retrieve all existing senders from ManyReach as {email: senderId}"""
    print("[+] Fetching existing senders from ManyReach...")
    existing = {}
    cursor = None
    page = 1
    
    while True:
        params = {"pageSize": 100}
        if cursor:
            params["cursor"] = cursor
        else:
            params["page"] = page

        status, resp = mr_call("GET", "/senders", params=params)
        if status != 200 or not isinstance(resp, dict):
            print(f"    [!] Warning: Failed to fetch senders page {page}: {resp}")
            break

        items = resp.get("items", [])
        if not items:
            break

        for s in items:
            em = s.get("email", "").strip().lower()
            sid = s.get("senderId")
            if em:
                existing[em] = sid

        pagination = resp.get("pagination", {})
        next_cursor = pagination.get("nextCursor")
        total = pagination.get("totalItems", len(existing))
        
        if next_cursor and next_cursor != cursor:
            cursor = next_cursor
        else:
            page += 1

        if len(existing) >= total or len(items) < 100:
            break

    print(f"[+] Found {len(existing)} senders already in ManyReach.")
    return existing

def create_manyreach_sender(record):
    email = record["email"]
    first = record["first_name"]
    last = record["last_name"]
    full_name = f"{first} {last}"
    ip = record["outbound_ip"]
    password = record["password"]
    signature = SIGNATURE_TEMPLATE.format(name=full_name)

    payload = {
        "email": email,
        "fromName": full_name,
        "firstName": first,
        "lastName": last,
        "accountType": "CustomSmtp",
        "customSmtpServer": ip,
        "customSmtpPort": 587,
        "customSmtpUsername": email,
        "customSmtpPass": password,
        "customImapServer": ip,
        "customImapPort": 993,
        "customImapUsername": email,
        "customImapPass": password,
        "warmup": True,
        "warmupDailyLimit": 12,
        "warmupDailyLimitIncrease": True,
        "warmupDailyLimitIncreasePercent": 20,
        "warmupDailyLimitIncreaseToMax": 30,
        "warmupReplyPercent": 30,
        "warmupSkipWeekends": False,
        "dailyLimit": 50,
        "dailyLimitIncrease": False,
        "delayMin": 5,
        "delayMinMinutes": 5,
        "customWarmupTag": "Strachka",
        "workspaceId": 15733,
        "signature": signature,
    }

    status, resp = mr_call("POST", "/senders", data=payload)
    if status in (200, 201):
        sender_id = resp.get("senderId")
        return True, sender_id
    else:
        err_msg = resp.get("message") or resp.get("error") or str(resp)
        return False, f"HTTP {status}: {err_msg}"

def update_sender_warmup(sender_id):
    """Calibrate existing sender to new limits"""
    payload = {
        "warmup": True,
        "warmupDailyLimit": 12,
        "warmupDailyLimitIncrease": True,
        "warmupDailyLimitIncreasePercent": 20,
        "warmupDailyLimitIncreaseToMax": 30,
    }
    mr_call("PATCH", f"/senders/{sender_id}", data=payload)

def main():
    if not os.path.exists(CSV_PATH):
        print(f"[!] Error: Master CSV {CSV_PATH} not found!")
        sys.exit(1)

    with open(CSV_PATH) as f:
        records = list(csv.DictReader(f))

    total_records = len(records)
    print(f"======================================================================")
    print(f"MANYREACH BULK FLEET IMPORTER")
    print(f"Total Mailboxes to Process: {total_records}")
    print(f"Warmup Strategy: Day 1: 12 emails/day | +20%/day | Cap: 30/day")
    print(f"======================================================================\n")

    existing = get_existing_senders()

    # If test sender exists, update its limits
    test_email = "bailey.robinson@aioutboundagents.shop"
    if test_email in existing:
        update_sender_warmup(existing[test_email])
        print(f"[+] Re-calibrated test account ({test_email}) to 12/day +20% -> max 30.")

    created_count = 0
    skipped_count = 0
    failed_count = 0
    failures = []

    start_time = time.time()

    for idx, r in enumerate(records, 1):
        email = r["email"]

        if email in existing:
            skipped_count += 1
            continue

        ok, result = create_manyreach_sender(r)
        if ok:
            created_count += 1
            existing[email] = result
        else:
            failed_count += 1
            failures.append((email, result))
            print(f"    [!] FAILED: {email} -> {result}")

        # Throttle between calls
        time.sleep(0.3)

        if idx % 10 == 0 or idx == total_records:
            elapsed = time.time() - start_time
            rate = (created_count + skipped_count) / max(elapsed, 1)
            remaining = (total_records - idx) / max(rate, 0.01)
            mins = int(remaining // 60)
            secs = int(remaining % 60)
            print(f"  [{idx:4d}/{total_records}] Created: {created_count:4d} | Skipped: {skipped_count:4d} | Failed: {failed_count:3d} (ETA: {mins:02d}:{secs:02d})")
            sys.stdout.flush()

    print(f"\n======================================================================")
    print(f"IMPORT COMPLETE SUMMARY")
    print(f"======================================================================")
    print(f"  Total Fleet Accounts: {total_records}")
    print(f"  Successfully Added:   {created_count}")
    print(f"  Skipped (Existing):   {skipped_count}")
    print(f"  Failed:               {failed_count}")
    print(f"  Total Time Elapsed:   {int(time.time() - start_time)} seconds")
    print(f"======================================================================\n")

    if failures:
        with open(FAILURES_PATH, "w") as f:
            for em, err in failures:
                f.write(f"{em}: {err}\n")
        print(f"[!] Logged {len(failures)} failures to {FAILURES_PATH}")

if __name__ == "__main__":
    main()
