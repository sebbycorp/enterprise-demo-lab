
echo "[INFO] Starting lab deployment..."

# Deploy containerlab topology
echo "[INFO] Deploying containerlab topology..."
sudo containerlab deploy -t topology.yaml

# Configure firewall
echo "[INFO] Configuring firewall..."
ansible-playbook playbooks/firewall.yaml

# Start Kasm container
echo "[INFO] Starting Kasm desktop container..."
docker run -d \
  --name=kasm \
  --network=ceos_clab \
  -p 6901:6901 \
  -e VNC_PW=mypassword \
  --shm-size=512m \
  --memory=2g \
  --cpus=2 \
  kasmweb/desktop:1.15.0

# Build servers
echo "[INFO] Building servers..."
./services/serverbuild.sh 

# Wait for services to stabilize
echo "[INFO] Waiting for services to stabilize..."
sleep 5

echo "[INFO] All services deployed successfully."
echo "[INFO] Starting traffic generation..."

# Start traffic generation
./traffic/traffic.sh 