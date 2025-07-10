#!/bin/bash

# Define client IPs, container names, and load balancer IPs
CLIENTS=(
  "10.1.10.101:clab-s2-dc2_client1:10.1.10.50"
  "10.1.11.102:clab-s2-dc2_client2:10.1.11.50"
  "10.1.10.103:clab-s2-dc2_client3:10.1.10.50"
  "10.1.11.104:clab-s2-dc2_client4:10.1.11.50"
)

# iperf3 server IP
SERVER_IP="10.1.10.100"
PORT=5201
DURATION=$((24*3600))  # 24 hours
BANDWIDTH="200K"
PARALLEL=8
MTU=1460

for CLIENT in "${CLIENTS[@]}"; do
  IP=${CLIENT%%:*}
  CONTAINER=$(echo $CLIENT | cut -d: -f2)
  LB_IP=$(echo $CLIENT | cut -d: -f3)

  # Start iperf3 traffic
  echo "Starting iperf3 on $CONTAINER ($IP)"
  docker exec -d $CONTAINER iperf3 -c $SERVER_IP -t $DURATION -i 1 -p $PORT -B $IP -P $PARALLEL -b $BANDWIDTH -M $MTU &

  # Start HTTP traffic to load balancer on port 80
  echo "Starting HTTP traffic on $CONTAINER ($IP) to $LB_IP:80"
  docker exec -d $CONTAINER sh -c "while true; do curl -s -o /dev/null http://$LB_IP:80; sleep 1; done" &
done

echo "iperf3 and HTTP traffic started on all clients."