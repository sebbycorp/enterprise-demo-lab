# Enterprise GCP Demo Lab

![Network Topology Diagram](lab-enterprise/diagram.png)

## Overview

This is a comprehensive enterprise network lab that demonstrates a data center fabric topology using Arista cEOS switches with Ansible automation. The lab includes spine-leaf architecture, VyOS firewalls, HAProxy load balancers, and containerized services to simulate real-world enterprise networking scenarios.  NOTE: CLIENT ARE NOT RUNNING LLDP/TEAM in GCP Environment.
 
## Network Topology

The Enterprise Demo Lab is a comprehensive network simulation environment that includes:
- Arista cEOS switches in a spine-leaf topology
- VyOS firewalls
- HAProxy load balancers
- Containerized services and applications
- Automated traffic generation

![Network Topology Diagram](lab-gcp/diagram.png)

## How to get started

### System Requirements
- Linux system with Docker support
- Sudo privileges
- Minimum 16GB RAM recommended
- 50GB free disk space

### Prerequisites



```bash


docker run -d \
  --name=kasm \
  --network=ceos_clab \
  -p 6901:6901 \
  -e VNC_PW=mypassword \
  --shm-size=512m \
  --memory=2g \
  --cpus=2 \
  kasmweb/desktop:1.15.0
  
  asm_user

