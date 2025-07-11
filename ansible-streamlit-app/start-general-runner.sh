#!/bin/bash

echo "⚙️ Starting General Ansible Playbook Runner..."
echo "This will start the general-purpose playbook execution interface"
echo ""

# Stop any existing containers
docker-compose down

# Build and start the general runner
docker-compose build
docker-compose --profile general up -d ansible-runner

echo ""
echo "✅ General Ansible Runner started!"
echo "🌐 Access at: http://localhost:8502"
echo ""
echo "Available features:"
echo "  • Run any Ansible playbook"
echo "  • Custom inventory and variables"
echo "  • Syntax checking"
echo "  • Execution logging"
echo ""
echo "To view logs: docker-compose logs -f ansible-runner"
echo "To stop: docker-compose down" 