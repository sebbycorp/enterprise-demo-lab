#!/bin/bash

echo "🌐 Starting Network Device Manager..."
echo "This will start the specialized network device management interface"
echo ""

# Stop any existing containers
docker-compose down

# Build and start the network manager
docker-compose build
docker-compose up -d network-manager

echo ""
echo "✅ Network Device Manager started!"
echo "🌐 Access at: http://localhost:8501"
echo ""
echo "Available features:"
echo "  • Device selection (EOS/VyOS)"
echo "  • Interface management"
echo "  • Device information gathering"
echo "  • Real-time connectivity testing"
echo ""
echo "To view logs: docker-compose logs -f network-manager"
echo "To stop: docker-compose down" 