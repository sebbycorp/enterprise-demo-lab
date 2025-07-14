# Enterprise GCP Demo Lab - Services Directory

## Overview

This directory contains the refactored service deployment scripts for the Enterprise GCP Demo Lab. The scripts have been completely rewritten to be more modular, maintainable, and robust.

## Directory Structure

```
services/
├── README.md           # This file
├── config.env          # Configuration file for all scripts
├── serverbuild.sh      # Main deployment script
├── dns-config.sh       # DNS configuration script
├── cleanup.sh          # Cleanup and teardown script
├── remoteengines.sh    # (Empty - placeholder for future use)
└── archive/            # Original scripts (deprecated)
    ├── deploy-apps.sh
    ├── temp.sh
    └── readme.md
```

## Key Improvements

### 🔧 **Modular Architecture**
- Separated concerns into focused scripts
- Function-based design for better reusability
- Configuration management through external files

### 🛡️ **Enhanced Error Handling**
- Comprehensive error checking and validation
- Graceful failure handling with proper cleanup
- Detailed logging for troubleshooting

### 📊 **Better Logging**
- Colored output for better readability
- Timestamped logs saved to files
- Different log levels (INFO, WARN, ERROR, DEBUG)

### ⚙️ **Configuration Management**
- External configuration file (`config.env`)
- Environment variable support
- No hardcoded values in scripts

### 🔐 **Security Improvements**
- Removed hardcoded credentials
- Configuration file for sensitive data
- Clear security warnings and best practices

## Scripts Overview

### 1. `serverbuild.sh` - Main Deployment Script

The primary script that orchestrates the entire deployment process.

**Features:**
- Automated Docker installation and configuration
- Network VLAN configuration
- Service deployment with health checks
- DNS server setup and configuration
- HAProxy configuration
- Comprehensive logging and error handling

**Usage:**
```bash
./serverbuild.sh
```

**What it does:**
1. Installs Docker on all client containers
2. Configures VLAN interfaces (110 and 111)
3. Sets up routing and DNS resolution
4. Deploys DNS server (Technitium DNS)
5. Configures HAProxy load balancers
6. Deploys application services (Web, API, Database)
7. Configures DNS zones and records
8. Provides access information

### 2. `dns-config.sh` - DNS Configuration Script

Standalone script for DNS server configuration that can be used independently.

**Features:**
- DNS server health checks
- Zone creation and management
- DNS record management (A, CNAME)
- Logging configuration
- Log exporter setup for syslog

**Usage:**
```bash
./dns-config.sh [OPTIONS]

Options:
  -h, --help          Show help message
  -c, --configure     Configure DNS zones and records
  -l, --list          List current DNS records
  -t, --test          Test DNS resolution
  -a, --all           Run full configuration (default)
```

**Examples:**
```bash
# Full DNS configuration
./dns-config.sh

# Configure zones and records only
./dns-config.sh --configure

# List current DNS records
./dns-config.sh --list

# Test DNS resolution
./dns-config.sh --test
```

### 3. `cleanup.sh` - Cleanup and Teardown Script

Comprehensive cleanup script for safely removing deployed services.

**Features:**
- Service cleanup with graceful shutdown
- Network configuration cleanup
- DNS zone cleanup
- HAProxy cleanup
- Verification of cleanup completion
- Interactive and forced modes

**Usage:**
```bash
./cleanup.sh [OPTIONS]

Options:
  -h, --help          Show help message
  -a, --all           Clean up all services (default)
  -s, --services      Clean up only containerized services
  -n, --network       Clean up only network configuration
  -d, --dns           Clean up only DNS configuration
  -l, --logs          Clean up log files
  -v, --verify        Verify cleanup completion
  --status            Show current deployment status
  --force             Force cleanup without confirmation
```

**Examples:**
```bash
# Interactive cleanup with confirmation
./cleanup.sh

# Force cleanup of everything
./cleanup.sh --all --force

# Clean up only services
./cleanup.sh --services

# Show current status
./cleanup.sh --status
```

### 4. `config.env` - Configuration File

Central configuration file for all scripts.

**Key Configuration Sections:**
- DNS Server Configuration
- Network Configuration (VLANs, Subnets, Gateways)
- Container Images
- Logging Configuration
- Service Port Assignments

**Important:** Change default credentials before production use!

## Configuration

### Network Architecture

The scripts configure the following network topology:

| Component | VLAN | IP Address | Purpose |
|-----------|------|------------|---------|
| Client1 | 110 | 10.1.10.101 | DNS Server + Web + Client Service |
| Client2 | 111 | 10.1.11.102 | API Service |
| Client3 | 110 | 10.1.10.103 | Web + Client Service |
| Client4 | 111 | 10.1.11.104 | Database + API Service |
| HAProxy1 | 110 | 10.1.10.50 | Load Balancer |
| HAProxy2 | 111 | 10.1.11.50 | Load Balancer |

### Service Ports

| Service | Port | Container |
|---------|------|-----------|
| Client Service | 5000 | Client1, Client3 |
| Web Front | 8080 | Client1, Client3 |
| API Service | 9090 | Client2, Client4 |
| Database | 1521 | Client4 |
| DNS Server | 53/UDP, 5380/TCP | Client1 |

### DNS Records

The following DNS records are automatically configured:

| Subdomain | IP Address | Purpose |
|-----------|------------|---------|
| web.s2ademo.ai | 10.1.10.50 | Web service via HAProxy |
| api.s2ademo.ai | 10.1.11.50 | API service via HAProxy |
| db.s2ademo.ai | 10.1.11.104 | Database service |
| dns.s2ademo.ai | 10.1.10.101 | DNS server |

## Usage Workflow

### 1. Initial Deployment

```bash
# 1. Review and customize configuration
nano config.env

# 2. Run the main deployment script
./serverbuild.sh

# 3. Wait for deployment to complete
# Access information will be displayed at the end
```

### 2. DNS Management

```bash
# List current DNS records
./dns-config.sh --list

# Test DNS resolution
./dns-config.sh --test

# Reconfigure DNS if needed
./dns-config.sh --configure
```

### 3. Status Monitoring

```bash
# Check deployment status
./cleanup.sh --status

# Verify services are running
docker exec -it clab-s2-dc1_client1 docker ps
```

### 4. Cleanup

```bash
# Clean up everything (with confirmation)
./cleanup.sh

# Force cleanup without confirmation
./cleanup.sh --force

# Clean up only services
./cleanup.sh --services
```

## Logs and Troubleshooting

### Log Files

- `deployment.log` - Main deployment script logs
- `cleanup.log` - Cleanup script logs
- DNS configuration logs are included in deployment.log

### Common Issues and Solutions

1. **Container Not Ready**
   - Check if containerlab topology is running
   - Verify container names match the expected format

2. **DNS Configuration Failed**
   - Check DNS server accessibility
   - Verify credentials in config.env
   - Ensure DNS server container is running

3. **Service Health Check Failed**
   - Check service logs: `docker exec <container> docker logs <service>`
   - Verify network connectivity
   - Check DNS resolution

4. **Network Configuration Issues**
   - Verify VLAN interfaces are created
   - Check routing table: `docker exec <container> route -n`
   - Verify DNS settings in /etc/resolv.conf

### Debugging Commands

```bash
# Check container status
docker exec <container> docker ps

# Check network interfaces
docker exec <container> ip addr show

# Check DNS resolution
docker exec <container> nslookup web.s2ademo.ai

# Check service logs
docker exec <container> docker logs <service-name>
```

## Security Considerations

### Default Credentials

⚠️ **IMPORTANT:** Change default credentials before production use!

Default credentials are set in `config.env`:
- DNS_USERNAME="admin"
- DNS_PASSWORD="admin"

### Best Practices

1. **Change Default Passwords**
   ```bash
   # Edit config.env and change:
   DNS_USERNAME="your-username"
   DNS_PASSWORD="your-secure-password"
   ```

2. **Use Environment Variables**
   ```bash
   export DNS_PASSWORD="your-secure-password"
   # The script will use the environment variable
   ```

3. **Review Configuration**
   - Always review `config.env` before deployment
   - Ensure network settings match your environment
   - Verify syslog server address

4. **Network Security**
   - Default setup is for lab/testing environments
   - Implement proper firewall rules for production
   - Use encrypted connections where possible

## Advanced Usage

### Custom Configuration

1. **Network Customization**
   ```bash
   # Edit config.env
   VLAN_110="200"
   VLAN_111="201"
   SUBNET_BASE="192.168"
   ```

2. **Service Customization**
   ```bash
   # Edit config.env
   FAKE_SERVICE_IMAGE="your-custom-image:latest"
   ZONE_NAME="yourdomain.com"
   ```

3. **Logging Customization**
   ```bash
   # Edit config.env
   SYSLOG_SERVER="192.168.1.100"
   ```

### Integration with Other Scripts

The scripts can be integrated into larger deployment workflows:

```bash
# Example workflow script
#!/bin/bash
cd services/
./serverbuild.sh
./dns-config.sh --test
# Continue with your workflow...
```

## Migration from Old Scripts

If you're upgrading from the old scripts in the `archive/` directory:

1. **Review Configuration**
   - Check your current settings
   - Map them to the new `config.env` format

2. **Clean Up Old Deployment**
   ```bash
   ./cleanup.sh --all --force
   ```

3. **Run New Deployment**
   ```bash
   ./serverbuild.sh
   ```

4. **Verify Migration**
   ```bash
   ./dns-config.sh --test
   ./cleanup.sh --status
   ```

## Contributing

When contributing to these scripts:

1. **Follow the established patterns**
   - Use the logging functions
   - Handle errors gracefully
   - Add configuration options to `config.env`

2. **Test thoroughly**
   - Test both success and failure scenarios
   - Verify cleanup works properly
   - Check logs for clarity

3. **Update documentation**
   - Update this README
   - Add inline comments for complex logic
   - Update usage examples

## Support

For issues or questions:

1. **Check the logs**
   ```bash
   tail -f deployment.log
   ```

2. **Verify prerequisites**
   - Ensure containerlab is running
   - Check Docker availability
   - Verify network connectivity

3. **Use the status command**
   ```bash
   ./cleanup.sh --status
   ```

4. **Clean up and retry**
   ```bash
   ./cleanup.sh --force
   ./serverbuild.sh
   ```

---

This refactored service deployment system provides a much more maintainable and robust foundation for the Enterprise GCP Demo Lab. The modular design makes it easy to extend, debug, and customize for different environments. 