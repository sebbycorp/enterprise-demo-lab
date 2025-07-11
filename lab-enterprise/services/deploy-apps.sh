#!/bin/bash

# Configuration
DNS_SERVER="http://172.100.100.8:5380"
USERNAME="admin"
PASSWORD="admin"
ZONE_NAME="s2ademo.ai"

# Fetch API token
API_KEY_NAME=$(curl -s -X POST "$DNS_SERVER/api/user/createToken?user=$USERNAME&pass=$PASSWORD&tokenName=admin" | jq -r '.token')
if [ -z "$API_KEY_NAME" ] || [ "$API_KEY_NAME" == "null" ]; then
  echo "Error: Failed to fetch API token."
  exit 1
fi

# Authenticate to get session token
TOKEN=$(curl -s -X POST "$DNS_SERVER/api/user/login?user=$USERNAME&pass=$PASSWORD" | jq -r '.token')
if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
  echo "Error: Failed to authenticate."
  exit 1
fi

# Check if zone exists, create if not
ZONE_CHECK=$(curl -s -X GET "$DNS_SERVER/api/zones/list?token=$TOKEN" | jq -r ".response.zones[] | select(.name==\"$ZONE_NAME\")")
if [ -z "$ZONE_CHECK" ]; then
  ZONE_RESPONSE=$(curl -s -X POST "$DNS_SERVER/api/zones/create?token=$TOKEN&zone=$ZONE_NAME&type=Primary")
  if echo "$ZONE_RESPONSE" | grep -q '"status":"ok"'; then
    echo "Zone $ZONE_NAME created."
  else
    echo "Error: Failed to create zone $ZONE_NAME."
    exit 1
  fi
else
  echo "Zone $ZONE_NAME exists."
fi

# Wait for zone to propagate
sleep 10

# Verify zone exists
ZONE_VERIFY=$(curl -s -X GET "$DNS_SERVER/api/zones/list?token=$TOKEN" | jq -r ".response.zones[] | select(.name==\"$ZONE_NAME\")")
if [ -z "$ZONE_VERIFY" ]; then
  echo "Error: Zone $ZONE_NAME not found."
  exit 1
fi

# Add A records
add_record() {
  local subdomain=$1
  local ip=$2
  RESPONSE=$(curl -s -X POST "$DNS_SERVER/api/zones/records/add?token=$TOKEN&zone=$ZONE_NAME&domain=$subdomain.$ZONE_NAME&type=A&ttl=3600&overwrite=false&ipAddress=$ip")
  if echo "$RESPONSE" | grep -q '"status":"ok"'; then
    echo "Added A record: $subdomain.$ZONE_NAME -> $ip"
  else
    echo "Error: Failed to add A record for $subdomain.$ZONE_NAME."
  fi
}

add_record "web" "10.1.10.50"
add_record "web1" "10.1.10.101"
add_record "web2" "10.1.10.103"
add_record "api" "10.1.11.50"
add_record "api1" "10.1.11.102"
add_record "api2" "10.1.11.104"
add_record "db" "10.1.11.104"

# Enable query logging
LOG_RESPONSE=$(curl -s -X POST "$DNS_SERVER/api/settings/set?token=$TOKEN" -d "enableLogging=true")
if echo "$LOG_RESPONSE" | grep -q '"status":"ok"'; then
  echo "Query logging enabled."
else
  echo "Error: Failed to enable query logging."
fi

# Install Log Exporter App
INSTALL_RESPONSE=$(curl -s -X GET "$DNS_SERVER/api/apps/downloadAndInstall?token=$API_KEY_NAME&name=Log%20Exporter&url=https%3A%2F%2Fdownload.technitium.com%2Fdns%2Fapps%2FLogExporterApp-v1.0.2.zip&_=1751984063549")
if echo "$INSTALL_RESPONSE" | grep -q '"status":"ok"'; then
  echo "Log Exporter App installed."
else
  echo "Error: Failed to install Log Exporter App."
fi

# Configure Log Exporter App
CONFIG_RESPONSE=$(curl -s -X POST "$DNS_SERVER/api/apps/config/set?token=$API_KEY_NAME&name=Log%20Exporter" \
  -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" \
  -H "Accept: application/json, text/javascript, */*; q=0.01" \
  -H "X-Requested-With: XMLHttpRequest" \
  --data-urlencode "config={
    \"maxQueueSize\": 1000000,
    \"file\": {
      \"path\": \"./dns_logs.json\",
      \"enabled\": false
    },
    \"http\": {
      \"endpoint\": \"http://localhost:5000/logs\",
      \"headers\": {
        \"Authorization\": \"Bearer abc123\"
      },
      \"enabled\": false
    },
    \"syslog\": {
      \"address\": \"172.16.10.118\",
      \"port\": 514,
      \"protocol\": \"UDP\",
      \"enabled\": true
    }
  }")
if echo "$CONFIG_RESPONSE" | grep -q '"status":"ok"'; then
  echo "Log Exporter App configured."
else
  echo "Error: Failed to configure Log Exporter App."
fi

echo "Configuration complete. Access web UI at http://172.100.100.8:5380"
echo "Default login: admin/admin (change password immediately)"
echo "Install Log Exported App and configure syslog to 172.16.10.118:514 via web UI"




# Client1 service configuration
CMD1Client1='docker run --privileged -d -p 5000:5000 \
  -e LISTEN_ADDR=0.0.0.0:5000 \
  -e UPSTREAM_URIS="http://web.s2ademo.ai" \
  -e MESSAGE="Client" \
  -e NAME="Client" \
  -e SERVER_TYPE="http" \
  nicholasjackson/fake-service:v0.7.1'

# Client3 service configuration
CMD3Client3='docker run --privileged -d -p 5000:5000 \
  -e LISTEN_ADDR=0.0.0.0:5000 \
  -e UPSTREAM_URIS="http://api.s2ademo.ai" \
  -e MESSAGE="Client" \
  -e NAME="Client" \
  -e SERVER_TYPE="http" \
  nicholasjackson/fake-service:v0.7.1'

# Web service on client1
WEB101='docker run --privileged -d -p 8080:8080 \
  -e LISTEN_ADDR=0.0.0.0:8080 \
  -e UPSTREAM_URIS="http://api.s2ademo.ai" \
  -e MESSAGE="Web Front" \
  -e NAME="Web front" \
  -e SERVER_TYPE="http" \
  nicholasjackson/fake-service:v0.7.1'

# API service on client2
API102='docker run --privileged -d -p 9090:9090 \
  -e LISTEN_ADDR=0.0.0.0:9090 \
  -e UPSTREAM_URIS="http://db.s2ademo.ai:1521" \
  -e MESSAGE="API" \
  -e NAME="API" \
  -e SERVER_TYPE="http" \
  nicholasjackson/fake-service:v0.7.1'

# Web service on client3
WEB103='docker run --privileged -d -p 8080:8080 \
  -e LISTEN_ADDR=0.0.0.0:8080 \
  -e UPSTREAM_URIS="http://api.s2ademo.ai" \
  -e MESSAGE="Web Front" \
  -e NAME="Web front" \
  -e SERVER_TYPE="http" \
  nicholasjackson/fake-service:v0.7.1'


# API service on client4
API104='docker run --privileged -d -p 9090:9090 \
  -e LISTEN_ADDR=0.0.0.0:9090 \
  -e UPSTREAM_URIS="http://db.s2ademo.ai:1521" \
  -e MESSAGE="API" \
  -e NAME="API" \
  -e SERVER_TYPE="http" \
  nicholasjackson/fake-service:v0.7.1'

# Database service on client4
CMD4DB='docker run --privileged -d -p 1521:1521 \
  -e LISTEN_ADDR=0.0.0.0:1521 \
  -e MESSAGE="Database" \
  -e NAME="Database" \
  -e SERVER_TYPE="http" \
  nicholasjackson/fake-service:v0.7.1'


CMdcADVISOR='docker run --privileged -d --name=cadvisor -p 5001:5001 \
  --log-driver=syslog \
  --log-opt syslog-address=udp://172.16.10.118:514 \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  google/cadvisor:latest'
  

docker exec -it clab-s2-dc1_client1 /bin/sh -c "$CMD1Client1"
docker exec -it clab-s2-dc1_client1 /bin/sh -c "$WEB101"
docker exec -it clab-s2-dc1_client2 /bin/sh -c "$API102"
docker exec -it clab-s2-dc1_client3 /bin/sh -c "$CMD3Client3"
docker exec -it clab-s2-dc1_client3 /bin/sh -c "$WEB103"
docker exec -it clab-s2-dc1_client4 /bin/sh -c "$CMD4DB"
docker exec -it clab-s2-dc1_client4 /bin/sh -c "$API104"

docker exec -it clab-s2-dc1_client1 /bin/sh -c "$CMdcADVISOR"
docker exec -it clab-s2-dc1_client2 /bin/sh -c "$CMdcADVISOR"
docker exec -it clab-s2-dc1_client3 /bin/sh -c "$CMdcADVISOR"
docker exec -it clab-s2-dc1_client4 /bin/sh -c "$CMdcADVISOR"
