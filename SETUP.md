# BillionMail Setup Guide

## Fresh VPS Installation

### 1. Clone the Repository
```bash
git clone -b dns-auto-sync https://github.com/mamghar001/MoeScale-BillionMail.git
cd MoeScale-BillionMail
```

### 2. Configure Environment
```bash
cp .env.example .env
# Edit .env with your settings
nano .env
```

### 3. Build and Deploy
```bash
# Run the deploy script which will:
# 1. Build the frontend
# 2. Create necessary directories
# 3. Build the Docker image with rotation support
# 4. Start all services
bash deploy-updated.sh
```

### 4. Access BillionMail
- URL: https://your-server-ip
- Login with credentials from .env file

## Key Features in This Branch

### ✅ Mailbox Rotation
- Emails rotate through ALL mailboxes across ALL domains
- Checkbox in Marketing → Tasks → Create Task
- Default is ON for new campaigns

### ✅ SPA Routing Fixed
- Direct URL access works (e.g., /market/task/edit)
- Page refresh works on all routes

### ✅ Sidebar Icons Fixed
- All menu icons properly displayed

### ✅ Postfix Fixed
- SQL config uses correct database user
- Domain lookups work properly

### ✅ Dovecot Optimized
- Process limits increased for high volume

## Troubleshooting

### Emails not sending with rotation
Make sure `rotate_senders` column exists:
```bash
docker exec billionmail-pgsql-billionmail-1 psql -U billionmail -d billionmail -c "ALTER TABLE email_tasks ADD COLUMN IF NOT EXISTS rotate_senders INTEGER DEFAULT 0;"
```

### Rebuild just the frontend
```bash
cd core/frontend
pnpm install
pnpm run build
cp -r dist/* ../public/
mkdir -p ../public/dist && ln -sf ../index.html ../public/dist/index.html
cd ../..
docker compose restart core-billionmail
```

### View logs
```bash
# Core logs
docker logs billionmail-core-billionmail-1 -f

# Postfix logs
docker logs billionmail-postfix-billionmail-1 -f
```
