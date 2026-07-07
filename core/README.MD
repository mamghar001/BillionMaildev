# BillionMail Core Backend

This is the Go-based core engine for BillionMail. It manages campaigns, SMTP delivery, rate limiting, and automated IP warmup.

---

## 🚀 Deliverability & Protection Features (Patched)

We have implemented three layers of automated protection to maximize success rates and prevent burning sending IPs:

### 1. Dynamic Bounce Protection
* Real-time monitoring of campaign delivery rates (every 2 minutes).
* If the bounce/deferral rate exceeds **5%**, sending speed is cut in half.
* If it exceeds **10%**, the campaign automatically pauses for 1 hour to cool down.
* Configured in `.env`:
  ```env
  BOUNCE_THROTTLE_THRESHOLD=0.05
  BOUNCE_PAUSE_THRESHOLD=0.10
  BOUNCE_THROTTLE_FACTOR=0.50
  ```

### 2. IP Cooldown Isolation
* If a single IP triggers bounces $\ge 10\%$ (e.g., gets blacklisted by Google), the system places **only that IP** on a 2-hour cooldown in Redis.
* Senders mapped to that IP's domain are temporarily skipped, allowing the rest of the campaign to route smoothly through the other healthy IPs.

### 3. Global Daily Cap (Safety Firewall)
* Prevents sudden volume spikes across the server.
* **Auto-Cap (Default):** Set `DAILY_SEND_LIMIT=` (blank). The backend dynamically calculates the limit by summing the daily warmup capacity of all active IPs, throttled by their health scores.
* **Manual Override:** Set `DAILY_SEND_LIMIT=5000` to enforce a hard daily limit.
* **Disabled:** Set `DAILY_SEND_LIMIT=disable` to remove the cap.