# Ansible Streamlit Runner

A Docker-based Streamlit application that provides a web interface for selecting and executing Ansible playbooks.

## Features

🚀 **Easy Playbook Execution**: Select and run Ansible playbooks through a beautiful web interface  
📋 **Playbook Management**: Browse, view, and validate playbook syntax  
⚙️ **Execution Options**: Support for inventory files, extra variables, and dry-run mode  
📊 **Real-time Results**: View execution output and errors in real-time  
🔧 **Built-in Tools**: Syntax checking and playbook information parsing  

## Quick Start

### Prerequisites

- Docker
- Docker Compose

### 1. Clone or Create the Project

```bash
mkdir ansible-streamlit-app
cd ansible-streamlit-app
```

### 2. Build and Run

```bash
# Build the Docker image
docker-compose build

# Start the application
docker-compose up -d

# View logs
docker-compose logs -f
```

### 3. Access the Application

Open your browser and navigate to: http://localhost:8501

## Project Structure

```
ansible-streamlit-app/
├── app.py                 # Main Streamlit application
├── requirements.txt       # Python dependencies
├── Dockerfile            # Docker configuration
├── docker-compose.yml    # Docker Compose configuration
├── README.md             # This file
├── playbooks/            # Directory for Ansible playbooks
│   ├── hello-world.yml   # Sample hello world playbook
│   └── system-info.yml   # Sample system information playbook
└── logs/                 # Directory for execution logs
```

## Adding Your Own Playbooks

1. Place your `.yml` or `.yaml` playbook files in the `playbooks/` directory
2. The application will automatically detect them
3. Organize playbooks in subdirectories if needed (e.g., `playbooks/networking/`, `playbooks/security/`)

### Example Playbook Structure

```yaml
---
- name: My Custom Playbook
  hosts: localhost
  connection: local
  gather_facts: true
  
  vars:
    my_variable: "value"
    
  tasks:
    - name: Example task
      debug:
        msg: "Hello from {{ my_variable }}!"
```

## Usage

### Basic Execution

1. **Select a Playbook**: Choose from the dropdown in the sidebar
2. **Review Playbook**: View the playbook content and information
3. **Configure Options**: Set inventory, extra variables, or enable dry-run mode
4. **Execute**: Click the "Execute Playbook" button
5. **View Results**: See the output in real-time

### Execution Options

- **Inventory File**: Specify a custom inventory file (optional)
- **Extra Variables**: Provide additional variables in JSON format
- **Dry Run Mode**: Use `--check` flag to see what would change without making changes

### Extra Variables Example

```json
{
  "target_directory": "/tmp/test",
  "file_content": "Hello World",
  "debug_mode": true
}
```

## Advanced Usage

### Custom Inventory

Create an inventory file in the `playbooks/` directory:

```ini
[web_servers]
server1 ansible_host=192.168.1.100
server2 ansible_host=192.168.1.101

[database_servers]
db1 ansible_host=192.168.1.200
```

### SSH Key Management

To run playbooks against remote hosts, mount your SSH keys:

```yaml
# In docker-compose.yml
volumes:
  - ~/.ssh:/root/.ssh:ro
```

### Environment Variables

Customize the application behavior:

```bash
# Set custom Streamlit port
STREAMLIT_SERVER_PORT=8502

# Disable CORS (already set)
STREAMLIT_SERVER_ENABLE_CORS=false

# Ansible specific settings
ANSIBLE_HOST_KEY_CHECKING=False
ANSIBLE_STDOUT_CALLBACK=yaml
```

## Development

### Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run locally
streamlit run app.py
```

### Building Custom Images

```bash
# Build with custom tag
docker build -t my-ansible-runner .

# Run custom image
docker run -p 8501:8501 -v $(pwd)/playbooks:/app/playbooks my-ansible-runner
```

## Troubleshooting

### Common Issues

**Playbooks not appearing**: Ensure your playbook files have `.yml` or `.yaml` extensions

**Permission errors**: Check that the playbooks directory is readable by the container

**SSH connection failures**: Verify SSH keys are properly mounted and inventory is correct

**Syntax errors**: Use the built-in syntax checker to validate playbooks

### Logs

View application logs:
```bash
docker-compose logs ansible-streamlit
```

View Ansible execution logs:
```bash
docker-compose exec ansible-streamlit cat /app/logs/ansible.log
```

## Security Considerations

- The container runs with elevated privileges to execute Ansible
- SSH keys should be mounted read-only
- Consider network isolation for production use
- Validate playbook content before execution
- Use inventory files to control target hosts

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is open source and available under the MIT License. 