#!/usr/bin/env python3
"""
Link all ManyReach senders (IDs 502970 - 503975) to Workspace 15733 ('Moe').
This makes them visible in the ManyReach Web Dashboard.
"""

import urllib.request
import urllib.error
import json
import time
import sys

API_URL = "https://app.manyreach.com/api/v2"
API_KEY = os.environ.get("MANYREACH_API_KEY", "")
WORKSPACE_ID = int(os.environ.get("MANYREACH_WORKSPACE_ID", "15733"))

def patch_sender(sid, retries=5):
    url = f"{API_URL}/senders/{sid}"
    data = json.dumps({"workspaceId": WORKSPACE_ID}).encode()
    headers = {
        "X-API-Key": API_KEY,
        "Content-Type": "application/json",
        "Accept": "application/json"
    }

    for attempt in range(retries):
        req = urllib.request.Request(url, data=data, headers=headers, method="PATCH")
        try:
            with urllib.request.urlopen(req, timeout=15) as r:
                return r.status
        except urllib.error.HTTPError as e:
            if e.code == 429:
                wait_time = 5 * (attempt + 1)
                time.sleep(wait_time)
                continue
            return e.code
        except Exception as e:
            time.sleep(2)
            continue
    return 429

def main():
    start_id = 502970
    end_id = 503975
    total = end_id - start_id + 1

    print(f"Linking senders {start_id} to {end_id} ({total} potential IDs) to Workspace {WORKSPACE_ID}...")
    
    linked = 0
    not_found = 0
    start_time = time.time()

    for idx, sid in enumerate(range(start_id, end_id + 1), 1):
        status = patch_sender(sid)
        if status in (200, 204):
            linked += 1
        elif status == 404:
            not_found += 1
        else:
            print(f"  [!] Sender {sid} returned status {status}")

        time.sleep(0.35)

        if idx % 25 == 0 or idx == total:
            elapsed = time.time() - start_time
            print(f"  [{idx:4d}/{total}] Linked: {linked:4d} | 404: {not_found:3d} ({elapsed:.1f}s)")
            sys.stdout.flush()

    print("\n" + "="*60)
    print(f"Done! Successfully linked {linked} senders to Workspace {WORKSPACE_ID}.")
    print("="*60)

if __name__ == "__main__":
    main()
