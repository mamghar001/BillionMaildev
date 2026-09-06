#!/bin/bash
set -e

chmod 755 /var/lib/rspamd
chown _rspamd:_rspamd /var/lib/rspamd

cat <<EOC > /etc/rspamd/local.d/redis.conf
servers = "redis:6379";
write_servers = "redis:6379";
disabled_modules = ["ratelimit"];
timeout = 10s;
db = "0";
password = "${REDISPASS}";
EOC

exec /usr/bin/rspamd -f -u _rspamd -g _rspamd
