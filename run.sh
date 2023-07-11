#!/bin/sh

# run mysql to zabbix
docker run -d --name mysql-zabbix \
 --restart always \
 -p 3306:3306 \
 -v ./mysql-data:/var/lib/mysql \
 mysql-zabbix \
 --default-authentication-plugin=mysql_native_password

# view mysql logs (CTRL+C to continue)
docker logs -f mysql-zabbix

# run SNMP Trap
docker run -d --name zabbix-snmptraps -t \
 --restart always \
 -p 162:1162/udp \
 -v ./snmptraps:/var/lib/zabbix/snmptraps:rw \
 -v ./mibs:/usr/share/snmp/mibs:ro \
 zabbix-snmptraps

# view traps logs (CTRL+C to continue)
docker logs -f zabbix-snmptraps

# run zabbix server
docker run -d --name zabbix-server \
 --restart always \
 -p 10051:10051 \
 --volumes-from zabbix-snmptraps \
 zabbix-server-mysql

# view zabbix server logs (CTRL+C to continue)
docker logs -f zabbix-server

# run zabbix web
docker run -d --name zabbix-web \
 --restart always \
 -p 80:8080 \
 -e ZBX_SERVER_HOST="zabbix-server" \
 -e DB_SERVER_HOST="zabbix-mysql" \
 -e DB_SERVER_PORT="3306" \
 -e MYSQL_ROOT_PASSWORD="secret" \
 -e MYSQL_DATABASE="zabbix" \
 -e MYSQL_USER="zabbix" \
 -e MYSQL_PASSWORD="zabbix" \
 -e PHP_TZ="America/Sao_Paulo" \
 --network=zabbix-net \
 zabbix/zabbix-web-nginx-mysql:${ZABBIX_VERSION}

# view zabbix web logs (CTRL+C to continue)
docker logs -f zabbix-web

