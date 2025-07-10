#!/bin/sh
STATS=$(echo "show stat" | socat /var/run/haproxy.sock stdio 2>/dev/null)
INFO=$(echo "show info" | socat /var/run/haproxy.sock stdio 2>/dev/null)
BACKEND_STATUS=$(echo "$STATS" | grep http_back | awk -F, '{print $18}')
SERVER1_STATUS=$(echo "$STATS" | grep client1 | awk -F, '{print $17}')
SERVER2_STATUS=$(echo "$STATS" | grep client2 | awk -F, '{print $17}')
ERROR_RATE=$(echo "$STATS" | grep http_back | awk -F, '{print $10}')
CONN_COUNT=$(echo "$STATS" | grep http_back | awk -F, '{print $5}')
HEALTH_FAIL1=$(echo "$STATS" | grep client1 | awk -F, '{print $16}')
HEALTH_FAIL2=$(echo "$STATS" | grep client2 | awk -F, '{print $16}')
UPTIME=$(echo "$INFO" | grep Uptime_sec | awk '{print $2}')
LOG_CHECK=$(tail -n 100 /var/log/haproxy.log 2>/dev/null | grep -q "$(date +%b)")

# Backend status
if [ "$BACKEND_STATUS" = "DOWN" ]; then
    snmptrap -v 2c -c public 172.16.10.118 '' .1.3.6.1.4.1.23263.3.1002 s "Backend DOWN"
fi

# Server health
if [ "$SERVER1_STATUS" = "DOWN" ]; then
    snmptrap -v 2c -c public 172.16.10.118 '' .1.3.6.1.4.1.23263.3.1003 s "Server client1 DOWN"
fi
if [ "$SERVER2_STATUS" = "DOWN" ]; then
    snmptrap -v 2c -c public 172.16.10.118 '' .1.3.6.1.4.1.23263.3.1004 s "Server client2 DOWN"
fi

# HTTP errors
if [ "$ERROR_RATE" -gt 100 ]; then
    snmptrap -v 2c -c public 172.16.10.118 '' .1.3.6.1.4.1.23263.3.1005 s "High HTTP errors"
fi

# Connection count
if [ "$CONN_COUNT" -gt 1000 ]; then
    snmptrap -v 2c -c public 172.16.10.118 '' .1.3.6.1.4.1.23263.3.1006 s "High connections"
fi

# Health check failures
if [ "$HEALTH_FAIL1" != "0" ]; then
    snmptrap -v 2c -c public 172.16.10.118 '' .1.3.6.1.4.1.23263.3.1007 s "Health check failed for client1"
fi
if [ "$HEALTH_FAIL2" != "0" ]; then
    snmptrap -v 2c -c public 172.16.10.118 '' .1.3.6.1.4.1.23263.3.1008 s "Health check failed for client2"
fi

# Stats socket
if [ -z "$STATS" ]; then
    snmptrap -v 2c -c public 172.16.10.118 '' .1.3.6.1.4.1.23263.3.1009 s "Stats socket unresponsive"
fi

# HAProxy uptime
if [ -z "$UPTIME" ]; then
    snmptrap -v 2c -c public 172.16.10.118 '' .1.3.6.1.4.1.23263.3.1010 s "HAProxy not running"
fi

# Stats interface
if ! curl -s -u admin:password http://172.100.100.14:8404/stats >/dev/null; then
    snmptrap -v 2c -c public 172.16.10.118 '' .1.3.6.1.4.1.23263.3.1011 s "Stats interface down"
fi

# Logging
if ! $LOG_CHECK; then
    snmptrap -v 2c -c public 172.16.10.118 '' .1.3.6.1.4.1.23263.3.1012 s "No recent logs"
fi

# SNMP query handling
case "$1" in
    ".1.3.6.1.4.1.23263.1") echo "integer"; echo "1"; ;;
    *) echo "string"; echo "unknown"; ;;
esac