# BillionMail REST API Reference

All API calls must include the authorization header:
`Authorization: Bearer <BM_API_TOKEN>`

---

## 1. Mailboxes (Senders)
Manage outgoing email sender accounts.

* **List Mailboxes (Paginated):**
  * `GET /mailbox/list`
  * Query parameters: `page` (int), `limit` (int), `search` (string)
* **Get All Mailboxes:**
  * `GET /mailbox/all`
* **Get All Mailbox Emails:**
  * `GET /mailbox/all_email`
* **Create Mailbox:**
  * `POST /mailbox/create`
  * JSON body: `email`, `password`, `smtp_host`, `smtp_port`, `imap_host`, `imap_port`, `ssl` (0/1), `name`, `status` (0/1)
* **Update Mailbox:**
  * `POST /mailbox/update`
* **Delete Mailbox:**
  * `POST /mailbox/delete`
  * JSON body: `ids` (array of integers)

---

## 2. Domains
Manage sending domains, branding, and DNS configurations.

* **List Domains (Paginated):**
  * `GET /domains/list`
  * Query parameters: `page`, `limit`
* **Get All Domains:**
  * `GET /domains/all`
* **Create Domain:**
  * `POST /domains/create`
  * JSON body: `domain`, `brand_domain`
* **Delete Domain:**
  * `POST /domains/delete`
  * JSON body: `domain`
* **Refresh DNS Records:**
  * `POST /domains/fresh_dns_records`
  * JSON body: `domain`

---

## 3. Campaigns (Tasks)
Manage cold email outbound tasks.

* **List Campaigns:**
  * `GET /batch_mail/task/list`
  * Query parameters: `page`, `limit`, `status` (optional)
* **Get Campaign by ID:**
  * `GET /batch_mail/task/find`
  * Query parameters: `id` (int64)
* **Create Campaign:**
  * `POST /batch_mail/task/create`
  * JSON body: `task_name`, `sender_group_id`, `template_id`, `recipient_group_id`, `warmup` (0/1), `speed` (emails/hour)
* **Pause Campaign:**
  * `POST /batch_mail/task/pause`
  * JSON body: `id` (int64)
* **Resume Campaign:**
  * `POST /batch_mail/task/resume`
  * JSON body: `id` (int64)
* **Delete Campaign:**
  * `POST /batch_mail/task/delete`
  * JSON body: `id` (int64)
* **Get Campaign Sending Logs:**
  * `GET /batch_mail/tracking/logs`
  * Query parameters: `task_id` (int64), `page`, `limit`, `status` (optional)

---

## 4. Email Templates
Manage campaign email templates.

* **List Templates (Paginated):**
  * `GET /email_template/list`
  * Query parameters: `page`, `limit`
* **Get All Templates:**
  * `GET /email_template/all`
* **Get Template Details:**
  * `GET /email_template/get`
  * Query parameters: `id` (int)
* **Create Template:**
  * `POST /email_template/create`
  * JSON body: `temp_name`, `subject`, `content`
* **Update Template:**
  * `POST /email_template/update`
* **Delete Template:**
  * `POST /email_template/delete`
  * JSON body: `id` (int)

---

## 5. Overview & Outbound Stats
Fetch live analytics and mail logs.

* **Get Dashboard Stats:**
  * `GET /overview`
  * Query parameters: `start_time` (Unix timestamp), `end_time` (Unix timestamp), `campaign_id` (optional), `domain` (optional)
* **Get Failed Mail Logs:**
  * `GET /overview/failed`
  * Query parameters: `start_time` (Unix timestamp), `end_time` (Unix timestamp)

---

## 6. Abnormal Recipients (Blocklist)
Manage dead emails, hard bounces, and SPAM blocks.

* **List Abnormal Recipients:**
  * `GET /abnormal_recipient/list`
  * Query parameters: `page`, `limit`
* **Add Abnormal Recipient:**
  * `POST /abnormal_recipient/add`
  * JSON body: `email`, `reason`
* **Delete Abnormal Recipient:**
  * `POST /abnormal_recipient/delete`
  * JSON body: `ids` (array of integers)
