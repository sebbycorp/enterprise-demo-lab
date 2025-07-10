#!/bin/bash

sudo containerlab deploy -t topology.yaml

ansible-playbook playbooks/superbook.yaml

./services/serverbuild.sh 

sleep 5

./services/deploy-apps.sh

echo "[INFO] All services deployed successfully."
echo "[INFO] All services deployed successfully."
echo "[INFO] Starting traffic generation..."

./traffic/traffic.sh 