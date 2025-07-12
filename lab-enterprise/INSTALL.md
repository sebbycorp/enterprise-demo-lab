# Enterprise Demo Lab - Installation Guide

This guide provides step-by-step instructions for installing all dependencies required to run the Enterprise Demo Lab on Ubuntu.

## System Requirements

- **Operating System**: Ubuntu 18.04 LTS or later
- **RAM**: Minimum 16GB recommended 
- **Storage**: 50GB free disk space
- **Privileges**: Sudo access required
- **Network**: Internet connectivity for downloading packages and container images

## Overview

The Enterprise Demo Lab is a comprehensive network simulation environment that includes:
- Arista cEOS switches in a spine-leaf topology
- VyOS firewalls
- HAProxy load balancers
- Containerized services and applications
- Automated traffic generation

## Installation Steps

### 1. Update System Packages

```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Install System Dependencies

```bash
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    make \
    curl \
    wget \
    ssh \
    sshpass \
    unzip \
    net-tools \
    bridge-utils \
    iptables \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    ansible
```

### 3. Install Docker

#### Install Docker Engine

```bash
# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index
sudo apt update

# Install Docker Engine
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

#### Configure Docker

```bash
# Add your user to the docker group
sudo usermod -aG docker $USER

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Verify Docker installation
sudo docker run hello-world
```

**Important**: Log out and log back in for the group changes to take effect, or run `newgrp docker`.

### 4. Install ContainerLab

```bash
# Install ContainerLab using the official installer
bash -c "$(curl -sL https://get.containerlab.dev)"

# Verify installation
containerlab version
```

### 5. Install Python Dependencies

#### Upgrade Ansible (Optional)

If you need a specific version of Ansible Core, you can upgrade it:

```bash
# Install/upgrade Ansible Core (version 2.15.0 to 2.17.x)
pip3 install "ansible-core>=2.15.0,<2.18.0"
sudo apt-get install ansible-core
sudo apt-get install ansible

# Verify installation
ansible --version
```

#### Install Required Python Packages

```bash
# Install PyAVD with Ansible support (required for AVD collection)
pip3 install "pyavd[ansible]"

# Install additional core Python requirements
pip3 install \
    netaddr>=0.7.19 \
    Jinja2>=3.0.0 \
    treelib>=1.5.5 \
    cvprac>=1.4.0 \
    jsonschema>=4.10.3 \
    referencing>=0.35.0 \
    requests>=2.27.0 \
    PyYAML>=6.0.0 \
    deepmerge>=1.1.0 \
    cryptography>=38.0.4 \
    paramiko>=2.7.1 \
    aristaproto>=0.1.1
```

**Note**: The `pyavd[ansible]` package includes all necessary Python requirements for the Arista AVD collection. The package version should match your AVD collection version.

### 6. Install Ansible Collections

```bash
# Install required Ansible collections
ansible-galaxy collection install arista.avd
ansible-galaxy collection install arista.cvp
ansible-galaxy collection install community.general

# Verify collections are installed
ansible-galaxy collection list | grep arista
```

### 7. Configure Ansible

Create or update your Ansible configuration file:

```bash
# Create ansible.cfg in your home directory or project directory
cat > ~/.ansible.cfg << EOF
[defaults]
jinja2_extensions=jinja2.ext.loopcontrols,jinja2.ext.do
duplicate_dict_key=error
host_key_checking = False
timeout = 60
stdout_callback = yaml
EOF
```

### 8. Pre-pull Container Images (Optional)

Pre-pulling images can speed up the initial deployment:

```bash
# Pull required container images
docker pull arista/ceos:4.33.4M
docker pull sebbycorp/ceosimage:4.33.4M
docker pull muruu1/vyos:latest
docker pull nicholasjackson/fake-service:v0.7.1
docker pull alpine:latest
```

### 9. Build Alpine Demo Image

Navigate to the alpine-demo directory and build the custom Alpine image:

```bash
cd alpine-demo
docker build -t alpine-demo .
cd ..
```

## Automated Installation Script

You can use this automated script to install all dependencies:

```bash
#!/bin/bash
set -e

echo "=== Enterprise Demo Lab - Dependency Installation ==="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Update system
log_info "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install system packages including Ansible
log_info "Installing system dependencies..."
sudo apt install -y \
    python3 python3-pip python3-venv git make curl wget ssh sshpass \
    unzip net-tools bridge-utils iptables software-properties-common \
    apt-transport-https ca-certificates gnupg lsb-release ansible

# Install Docker
log_info "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USER
sudo systemctl start docker
sudo systemctl enable docker

# Install ContainerLab
log_info "Installing ContainerLab..."
bash -c "$(curl -sL https://get.containerlab.dev)"

# Upgrade Ansible Core if needed
log_info "Upgrading Ansible Core (optional)..."
pip3 install "ansible-core>=2.15.0,<2.18.0" --upgrade

# Install Ansible collections
log_info "Installing Ansible collections..."
ansible-galaxy collection install arista.avd
ansible-galaxy collection install arista.cvp
ansible-galaxy collection install community.general

# Install Python requirements
log_info "Installing Python requirements..."
pip3 install "pyavd[ansible]"
pip3 install netaddr Jinja2 treelib cvprac jsonschema referencing requests PyYAML deepmerge cryptography paramiko aristaproto

# Configure Ansible
log_info "Configuring Ansible..."
cat > ~/.ansible.cfg << EOF
[defaults]
jinja2_extensions=jinja2.ext.loopcontrols,jinja2.ext.do
duplicate_dict_key=error
host_key_checking = False
timeout = 60
stdout_callback = yaml
EOF

# Build Alpine demo image
if [ -d "alpine-demo" ]; then
    log_info "Building Alpine demo image..."
    cd alpine-demo
    docker build -t alpine-demo .
    cd ..
fi

log_info "Installation completed successfully!"
log_warn "Please log out and back in for Docker group changes to take effect."
log_info "After logging back in, navigate to lab-enterprise/ and run ./build.sh to deploy the lab."
```

Save this script as `install-deps.sh`, make it executable, and run it:

```bash
chmod +x install-deps.sh
./install-deps.sh
```

## Verification

After installation, verify that all components are working correctly:

### Check Versions

```bash
# Check Python version (should be 3.8+)
python3 --version

# Check Ansible version
ansible --version

# Check Docker version
docker --version

# Check ContainerLab version
containerlab version
```

### Test Docker Access

```bash
# Test Docker without sudo (should work after re-login)
docker ps

# Test pulling an image
docker pull hello-world
docker run hello-world
```

### Verify Ansible Collections

```bash
# List installed collections
ansible-galaxy collection list

# Should show arista.avd and arista.cvp collections
ansible-galaxy collection list | grep arista
```

### Test Ansible Connectivity

```bash
# Test Ansible installation
ansible localhost -m ping
```

## Deployment

Once all dependencies are installed and verified:

1. **Navigate to the lab directory:**
   ```bash
   cd lab-enterprise
   ```

2. **Deploy the complete lab:**
   ```bash
   # Option 1: Using the build script
   ./build.sh
   
   # Option 2: Using Make
   make deploy
   
   # Option 3: Step by step
   sudo containerlab deploy -t topology.yaml
   ansible-playbook playbooks/superbook.yaml
   ./services/serverbuild.sh
   ./services/deploy-apps.sh
   ./traffic/traffic.sh
   ```

3. **Verify deployment:**
   ```bash
   # Check topology status
   sudo containerlab inspect -t topology.yaml
   
   # Verify Ansible connectivity to devices
   ansible all -i inventory.yaml -m ping
   ```

## Troubleshooting

### Common Issues

#### Docker Permission Denied
If you get permission denied errors with Docker:
```bash
# Ensure you're in the docker group
groups $USER

# If docker group is missing, add it and re-login
sudo usermod -aG docker $USER
# Then log out and back in
```

#### Python Package Installation Issues
If pip installations fail:
```bash
# Upgrade pip
python3 -m pip install --upgrade pip

# Install with user flag if needed
pip3 install --user <package_name>
```

#### Ansible Collection Installation Issues
If Ansible collections fail to install:
```bash
# Check Ansible configuration
ansible-config dump

# Install with specific path
ansible-galaxy collection install arista.avd -p ~/.ansible/collections
```

#### ContainerLab Issues
If ContainerLab fails to start containers:
```bash
# Check Docker service
sudo systemctl status docker

# Check for port conflicts
sudo netstat -tlnp | grep :80

# View ContainerLab logs
sudo containerlab logs -t topology.yaml
```

#### Missing pyavd Package Error
If you get an error about "No package metadata was found for pyavd":
```bash
# Install the missing pyavd package
pip3 install "pyavd[ansible]"

# If you need a specific version to match your AVD collection
pip3 install "pyavd[ansible]==5.5.0"  # Replace with your AVD version
```

### Getting Help

- Check the main [README.md](README.md) for lab-specific documentation
- Review container logs: `docker logs <container_name>`
- Check ContainerLab status: `sudo containerlab inspect -t topology.yaml`
- Verify network connectivity between containers
- Ensure all required ports are available

## Additional Resources

- [ContainerLab Documentation](https://containerlab.dev/)
- [Arista AVD Collection Documentation](https://avd.arista.com/)
- [Arista CVP Collection Documentation](https://cvp.avd.sh/)
- [Docker Documentation](https://docs.docker.com/)
- [Ansible Documentation](https://docs.ansible.com/)

## License

This installation guide is provided for educational and testing purposes. Please review the licensing terms for all included software components and container images. 