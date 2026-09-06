#!/bin/bash

id vmail || useradd -r -u 150 -g mail -d /var/vmail -s /sbin/nologin -c "Virtual Mail User" vmail
chown vmail:mail /var/vmail

# Fix ownership asynchronously in background so Dovecot starts instantly
( find /var/vmail \( ! -user 150 -o ! -group 8 \) -exec chown vmail:mail {} + 2>/dev/null & )

if [ ! -f "/etc/ssl/mail/dh.pem" ] || [ ! -f "/etc/ssl/mail/cert.pem" ] || [ ! -f "/etc/ssl/mail/key.pem" ]; then
    cp -d -n /etc/ssl/ssl-self-signed/* /etc/ssl/mail/
fi

mkdir -p /var/spool/cron/crontabs
if [ -f /var/spool/cron/crontabs/root ] && grep -q "rotate_log.sh" /var/spool/cron/crontabs/root; then
    :
else
    chmod +x /rotate_log.sh 2>/dev/null || true
    echo "05 00 * * * bash /rotate_log.sh >> /var/log/mail/rotate_log.log 2>&1" >> /var/spool/cron/crontabs/root
    chmod 600 /var/spool/cron/crontabs/root
    chown root:crontab /var/spool/cron/crontabs/root 2>/dev/null || true
fi

cat <<SQL_EOF > /etc/dovecot/conf.d/dovecot-sql.conf.ext
driver = pgsql
connect = host=pgsql dbname=${DBNAME} user=${DBUSER} password=${DBPASS}

default_pass_scheme = MD5-CRYPT

user_query = SELECT '/var/vmail/%d/%n' as home, 'maildir:/var/vmail/%d/%n' as mail, 150 AS uid, 8 AS gid, 'maildir:storage=' || quota AS quota FROM mailbox WHERE username = '%u' AND active = 1

password_query = SELECT username as user, password, '/var/vmail/%d/%n' as userdb_home, 'maildir:/var/vmail/%d/%n' as userdb_mail, 150 as userdb_uid, 8 as userdb_gid FROM mailbox WHERE username = '%u' AND active = 1
SQL_EOF

chmod +x /usr/lib/dovecot/sieve/sa-learn-spam.sh 2>/dev/null || true
chmod +x /usr/lib/dovecot/sieve/sa-learn-ham.sh 2>/dev/null || true
sievec /usr/lib/dovecot/sieve/spam-to-folder.sieve 2>/dev/null || true
sievec /usr/lib/dovecot/sieve/report-spam.sieve 2>/dev/null || true
sievec /usr/lib/dovecot/sieve/report-ham.sieve 2>/dev/null || true

exec "$@"
