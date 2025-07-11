#!/bin/bash

# Network configuration for client1
CMD1='cat /etc/hostname; \
sudo vconfig add team0 110; \
sudo ifconfig team0.110 10.1.10.101 netmask 255.255.255.0; \
sudo ip link set up team0.110; \
sudo ip route add 10.1.0.0/16 via 10.1.10.10 dev team0.110; \
echo -e "nameserver 10.1.10.101\nnameserver 8.8.8.8" | sudo tee /etc/resolv.conf; \
sudo ifconfig team0.110; \
sudo route -n'

# Docker installation and daemon startup
DOCKER='set -e; \
if ! command -v docker >/dev/null 2>&1; then \
    echo "Docker is not installed. Installing..."; \
    apk add docker; \
fi; \
echo "Starting Docker daemon..."; \
dockerd & \
echo "Waiting for Docker daemon..."; \
timeout=30; \
while [ $timeout -gt 0 ] && ! docker info >/dev/null 2>&1; do \
    sleep 1; \
    timeout=$((timeout - 1)); \
done; \
if docker info >/dev/null 2>&1; then \
    echo "Docker daemon is running successfully"; \
else \
    echo "Failed to start Docker daemon"; \
    exit 1; \
fi'

# HAProxy configuration for haproxy1
haproxy1='cat /etc/hostname; \
sudo vconfig add team0 110; \
sudo ifconfig team0.110 10.1.10.50 netmask 255.255.255.0; \
sudo ip link set up team0.110; \
sudo ip route add 10.1.0.0/16 via 10.1.10.10 dev team0.110; \
sudo ifconfig team0.110; \
sudo route -n'

# HAProxy configuration for haproxy2
haproxy2='cat /etc/hostname; \
sudo vconfig add team0 111; \
sudo ifconfig team0.111 10.1.11.50 netmask 255.255.255.0; \
sudo ip link set up team0.111; \
sudo ip route add 10.1.0.0/16 via 10.1.11.10 dev team0.111; \
sudo ifconfig team0.111; \
sudo route -n'

# Network configuration for client2
CMD2='cat /etc/hostname; \
sudo vconfig add team0 111; \
sudo ifconfig team0.111 10.1.11.102 netmask 255.255.255.0; \
sudo ip link set up team0.111; \
sudo ip route add 10.1.0.0/16 via 10.1.11.10 dev team0.111; \
echo -e "nameserver 10.1.10.101\nnameserver 8.8.8.8" | sudo tee /etc/resolv.conf; \
sudo ifconfig team0.111; \
sudo route -n'

# Network configuration for client3
CMD3='cat /etc/hostname; \
sudo vconfig add team0 110; \
sudo ifconfig team0.110 10.1.10.103 netmask 255.255.255.0; \
sudo ip link set up team0.110; \
sudo ip route add 10.1.0.0/16 via 10.1.10.10 dev team0.110; \
echo -e "nameserver 10.1.10.101\nnameserver 8.8.8.8" | sudo tee /etc/resolv.conf; \
sudo ifconfig team0.110; \
sudo route -n'

# Network configuration for client4
CMD4='cat /etc/hostname; \
sudo vconfig add team0 111; \
sudo ifconfig team0.111 10.1.11.104 netmask 255.255.255.0; \
sudo ip link set up team0.111; \
sudo ip route add 10.1.0.0/16 via 10.1.11.10 dev team0.111; \
echo -e "nameserver 10.1.10.101\nnameserver 8.8.8.8" | sudo tee /etc/resolv.conf; \
sudo ifconfig team0.111; \
sudo route -n'


# PowerDNS configuration for client1
DNS='docker run --privileged -d --name technitium-dns \
  -p 53:53/udp \
  -p 5380:5380 \
  -v technitium-data:/etc/dns/config \
  -e DNS_SERVER_FORWARDERS=1.1.1.1,8.8.8.8 \
  --restart unless-stopped \
  technitium/dns-server
'
# Start HAProxy
HAStart='sudo haproxy -f /usr/local/etc/haproxy/haproxy.cfg -D'

echo "[INFO] Install Docker and start daemon"
docker exec -u root -it clab-s2-dc1_client1 /bin/sh -c "${DOCKER}"
docker exec -u root -it clab-s2-dc1_client2 /bin/sh -c "${DOCKER}"
docker exec -u root -it clab-s2-dc1_client3 /bin/sh -c "${DOCKER}"
docker exec -u root -it clab-s2-dc1_client4 /bin/sh -c "${DOCKER}"

echo "[INFO] Configuring clab-s2-dc1_client1"
docker exec -it clab-s2-dc1_client1 /bin/sh -c "$CMD1"
docker exec -it clab-s2-dc1_client1 /bin/sh -c "$DNS"


echo "[INFO] Configuring clab-s2-haproxy1 and clab-s2-haproxy2"
docker exec -it clab-s2-dc1_haproxy1 /bin/sh -c "$haproxy1"
docker exec -it clab-s2-dc1_haproxy2 /bin/sh -c "$haproxy2"

echo "[INFO] Configuring clab-s2-dc1_client2"
docker exec -it clab-s2-dc1_client2 /bin/sh -c "$CMD2"

echo "[INFO] Configuring clab-s2-dc1_client3"
docker exec -it clab-s2-dc1_client3 /bin/sh -c "$CMD3"


echo "[INFO] Configuring clab-s2-dc1_client4"
docker exec -it clab-s2-dc1_client4 /bin/sh -c "$CMD4"

echo "[INFO] Starting HAProxy"
docker exec -it clab-s2-dc1_haproxy1 /bin/sh -c "$HAStart"
docker exec -it clab-s2-dc1_haproxy2 /bin/sh -c "$HAStart"


echo "[INFO] SETUP DNS"
echo "http://172.100.100.8:5380 and generate an API key"
echo "Use [ docker exec -it clab-s2-dc1_client1 /bin/sh ] to login to host."

dc1_client1
mkdir -p ~/s2RemoteEngines/dc1_client1-agent-1 && cd ~/s2RemoteEngines/dc1_client1-agent-1
wget wget https://demo3.selector.ai/s2agent/s2agent_docker.sh 

sudo curl https://demo3.selector.ai/s2agent/s2agent_docker.sh | AGENTNAME=dc1_client1-agent-1 S2AP_DNS=demo3.selector.ai bash -s start
