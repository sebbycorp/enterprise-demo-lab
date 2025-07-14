#!/bin/bash

# Environment variables
S2_ENGINES_URL="https://${S2_BASE_URL}/engines/s2engine.sh"
S2_AGENT_URL="https://${S2_BASE_URL}/s2agent/s2agent_docker.sh"

echo "Deploying S2 Remote Engines using base URL: ${S2_BASE_URL}"
echo "=========================================================="

# SNMP Engine
echo "Deploying SNMP Engine..."
mkdir -p snmp-engine1
cd snmp-engine1
curl "${S2_ENGINES_URL}" | REMOTE_ENGINE_NAME=snmp-engine1 SNMP_ENGINE_CLASS=snmp-default bash -s snmp deploy
cd ..

# SNMP Trap Engine
echo "Deploying SNMP Trap Engine..."
mkdir -p snmptrap-engine1
cd snmptrap-engine1
curl "${S2_ENGINES_URL}" | REMOTE_ENGINE_NAME=snmptrap-engine1 bash -s snmptrap deploy
cd ..

# Syslog Engine
echo "Deploying Syslog Engine..."
mkdir -p syslog-engine1
cd syslog-engine1
curl "${S2_ENGINES_URL}" | REMOTE_ENGINE_NAME=syslog-engine1 bash -s syslog deploy
cd ..

# GNMI Engine
echo "Deploying GNMI Engine..."
mkdir -p gnmi-engine1
cd gnmi-engine1
curl "${S2_ENGINES_URL}" | REMOTE_ENGINE_NAME=gnmi-engine1 GNMI_ENGINE_CLASS=gnmi-default bash -s gnmi deploy
cd ..

# S2 Remote Agent
echo "Deploying S2 Remote Agent..."
mkdir -p ~/s2RemoteEngines/${HOSTNAME,,}-agent-1
cd ~/s2RemoteEngines/${HOSTNAME,,}-agent-1
curl "${S2_AGENT_URL}" | AGENTNAME=${HOSTNAME,,}-agent-1 S2AP_DNS="${S2_BASE_URL}" bash -s start
cd -

# UDF Engine
echo "Deploying UDF Engine..."
mkdir -p udf-engine1
cd udf-engine1
curl "${S2_ENGINES_URL}" | REMOTE_ENGINE_NAME=udf-engine1 bash -s udf deploy
cd ..

echo "=========================================================="
echo "All engines deployed successfully!"
echo "Base URL used: ${S2_BASE_URL}"
