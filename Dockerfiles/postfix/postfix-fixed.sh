#!/bin/bash

trap "postfix stop" EXIT

mkdir -p /var/spool/cron/crontabs
if [ -f /var/spool/cron/crontabs/root ] && grep -q "rotate_log.sh" /var/spool/cron/crontabs/root; then
    :
else
    chmod +x /rotate_log.sh 2>/dev/null || true
    echo "00 00 * * * bash /rotate_log.sh >> /var/log/mail/rotate_log.log 2>&1" >> /var/spool/cron/crontabs/root
    chmod 600 /var/spool/cron/crontabs/root
    chown root:crontab /var/spool/cron/crontabs/root 2>/dev/null || true
fi

# Use 127.0.0.1:25432 instead of "pgsql" (postfix is in host network mode)
DBHOST="127.0.0.1:25432"

cat <<EOF > /etc/postfix/btrule.cf
user = ${DBUSER}
password = ${DBPASS}
hosts = ${DBHOST}
dbname = ${DBNAME}
query = select s.goto from( select address, goto, 1 as stype from alias union select username,username,2 as stype from mailbox union select address, goto, 3 as stype from alias_domain a left join alias b on b.address = '@' || a.alias_domain and a.alias_domain ='%d' order by stype) s where s.address='%s' or s.stype=3 limit 0,1
EOF

cat <<EOF > /etc/postfix/sql/pgsql_virtual_alias_domain_catchall_maps.cf
user = ${DBUSER}
password = ${DBPASS}
hosts = ${DBHOST}
dbname = ${DBNAME}
query = SELECT goto FROM alias,alias_domain WHERE alias_domain.alias_domain = '%d' and alias.address = '@' || alias_domain.target_domain AND alias.active = 1 AND alias_domain.active = 1
EOF

cat <<EOF > /etc/postfix/sql/pgsql_virtual_alias_domain_mailbox_maps.cf
user = ${DBUSER}
password = ${DBPASS}
hosts = ${DBHOST}
dbname = ${DBNAME}
query = SELECT maildir FROM mailbox,alias_domain WHERE alias_domain.alias_domain = '%d' and mailbox.username = '%u' || '@' || alias_domain.target_domain AND mailbox.active = 1 AND alias_domain.active = 1
EOF

cat <<EOF > /etc/postfix/sql/pgsql_virtual_alias_domain_maps.cf
user = ${DBUSER}
password = ${DBPASS}
hosts = ${DBHOST}
dbname = ${DBNAME}
query = SELECT goto FROM alias,alias_domain WHERE alias_domain.alias_domain = '%d' and alias.address = '%u' || '@' || alias_domain.target_domain AND alias.active = 1 AND alias_domain.active = 1
EOF

cat <<EOF > /etc/postfix/sql/pgsql_virtual_alias_maps.cf
user = ${DBUSER}
password = ${DBPASS}
hosts = ${DBHOST}
dbname = ${DBNAME}
query = (select username from mailbox where username like '%s' and active = 1 limit 1) union (select goto from alias where address like '%s' and active = 1 limit 1)
EOF

cat <<EOF > /etc/postfix/sql/pgsql_virtual_domains_maps.cf
user = ${DBUSER}
password = ${DBPASS}
hosts = ${DBHOST}
dbname = ${DBNAME}
query = SELECT domain FROM domain WHERE domain='%s' AND active = 1
EOF

cat <<EOF > /etc/postfix/sql/pgsql_virtual_mailbox_maps.cf
user = ${DBUSER}
password = ${DBPASS}
hosts = ${DBHOST}
dbname = ${DBNAME}
query = SELECT maildir FROM mailbox WHERE username='%s' AND active=1
EOF

cat <<EOF > /etc/postfix/sql/pgsql_sender_relay_maps.cf
user = ${DBUSER}
password = ${DBPASS}
hosts = ${DBHOST}
dbname = ${DBNAME}
query = SELECT 'relay_host' WHERE 1=0
EOF

cat <<EOF > /etc/postfix/sql/pgsql_sender_transport_maps.cf
user = ${DBUSER}
password = ${DBPASS}
hosts = ${DBHOST}
dbname = ${DBNAME}
query = SELECT CONCAT(smtp_name, ':') FROM bm_domain_smtp_transport WHERE domain = SUBSTRING('%s' FROM POSITION('@' IN '%s')) AND atype = 'relay' AND smtp_name NOT LIKE '%%_DISABLED_%%' LIMIT 1
EOF

# Update main.cf to use 127.0.0.1:26 for LMTP
# sed -i 's|virtual_transport = lmtp:inet:172.66.1.4:10003|virtual_transport = lmtp:inet:127.0.0.1:26|' /etc/postfix/main.cf
# sed -i 's|smtpd_sasl_path = inet:127.0.0.1:10002|smtpd_sasl_path = inet:127.0.0.1:10002|' /etc/postfix/main.cf

if [ ! -f "/etc/postfix/conf/vmail_ssl.map" ]; then
    touch /etc/postfix/conf/vmail_ssl.map
fi
postmap -F hash:/etc/postfix/conf/vmail_ssl.map

chgrp -R postdrop /var/spool/postfix/public
chgrp -R postdrop /var/spool/postfix/maildrop

if [ -e "/var/spool/postfix/pid/master.pid" ]; then
    rm -rf /var/spool/postfix/pid/master.pid
fi

if [ -d "/var/spool/postfix/" ]; then
    [ ! -d "/var/spool/postfix/dev/" ] && mkdir /var/spool/postfix/dev
fi

postconf -c /etc/postfix/ > /dev/null

if [[ $? != 0 ]]; then
    echo "Postfix configuration error, Startup failed."
    exit 1
else
    postfix start-fg
fi
