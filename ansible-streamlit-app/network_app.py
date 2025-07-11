import streamlit as st
import os
import subprocess
import json
import yaml
from datetime import datetime
import glob
from pathlib import Path

# Page configuration
st.set_page_config(
    page_title="Network Device Manager",
    page_icon="🌐",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Constants
PLAYBOOKS_DIR = "/app/playbooks"
LOGS_DIR = "/app/logs"
INVENTORY_FILE = "/app/playbooks/inventory.yaml"

# Network device mappings
DEVICE_GROUPS = {
    "EOS Devices": {
        "DC1_SPINE1": "172.100.100.2",
        "DC1_SPINE2": "172.100.100.3", 
        "DC1_LEAF1A": "172.100.100.4",
        "DC1_LEAF1B": "172.100.100.5",
        "DC1_LEAF2A": "172.100.100.6",
        "DC1_LEAF2B": "172.100.100.7"
    },
    "VyOS Firewalls": {
        "VYOS01": "172.100.100.12",
        "VYOS02": "172.100.100.13"
    }
}

# Common interfaces for device types
COMMON_INTERFACES = {
    "EOS": ["Ethernet1", "Ethernet2", "Ethernet3", "Ethernet4", "Ethernet5", "Ethernet6", "Management1"],
    "VyOS": ["eth0", "eth1", "eth2", "eth3", "eth4"]
}

def get_network_playbooks():
    """Get list of network-specific playbooks"""
    playbooks = []
    network_dir = os.path.join(PLAYBOOKS_DIR, "network")
    if os.path.exists(network_dir):
        for file in glob.glob(f"{network_dir}/*.yml") + glob.glob(f"{network_dir}/*.yaml"):
            relative_path = os.path.relpath(file, PLAYBOOKS_DIR)
            playbooks.append(relative_path)
    return sorted(playbooks)

def run_network_playbook(playbook_path, extra_vars=None, check_mode=False):
    """Execute network playbook with inventory"""
    cmd = ["ansible-playbook"]
    
    # Add inventory
    cmd.extend(["-i", INVENTORY_FILE])
    
    # Add extra variables
    if extra_vars:
        cmd.extend(["--extra-vars", json.dumps(extra_vars)])
    
    # Add check mode if requested
    if check_mode:
        cmd.append("--check")
    
    # Add playbook path
    cmd.append(os.path.join(PLAYBOOKS_DIR, playbook_path))
    
    # Set environment
    env = os.environ.copy()
    env['ANSIBLE_STDOUT_CALLBACK'] = 'yaml'
    env['ANSIBLE_HOST_KEY_CHECKING'] = 'False'
    
    return subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        env=env,
        cwd=PLAYBOOKS_DIR
    )

def main():
    st.title("🌐 Network Device Manager")
    st.markdown("Manage network devices and interfaces through Ansible automation")
    
    # Sidebar for device and operation selection
    with st.sidebar:
        st.header("🎯 Device Selection")
        
        # Device group selection
        device_group = st.selectbox(
            "Device Group:",
            list(DEVICE_GROUPS.keys()),
            key="device_group"
        )
        
        # Individual device selection
        selected_device = st.selectbox(
            "Select Device:",
            list(DEVICE_GROUPS[device_group].keys()),
            key="selected_device"
        )
        
        if selected_device:
            device_ip = DEVICE_GROUPS[device_group][selected_device]
            st.info(f"📍 IP: {device_ip}")
        
        st.divider()
        
        # Operation selection
        st.header("⚙️ Operations")
        operation = st.selectbox(
            "Select Operation:",
            [
                "Device Information",
                "Interface Status", 
                "Enable Interface",
                "Disable Interface"
            ],
            key="operation"
        )
    
    # Main content area
    col1, col2 = st.columns([2, 1])
    
    with col1:
        st.header(f"🎯 {operation}")
        
        # Device information section
        if operation == "Device Information":
            st.markdown("### Gather comprehensive device information")
            
            if device_group == "EOS Devices":
                playbook = "network/eos-device-info.yml"
            else:
                playbook = "network/vyos-device-info.yml"
            
            extra_vars = {"target_host": selected_device}
            
            if st.button("🔍 Get Device Info", type="primary"):
                with st.spinner(f"Gathering information from {selected_device}..."):
                    result = run_network_playbook(playbook, extra_vars)
                    display_results(result, f"Device Info - {selected_device}")
        
        # Interface status section
        elif operation == "Interface Status":
            st.markdown("### Check interface status and configuration")
            
            if device_group == "EOS Devices":
                playbook = "network/eos-interface-status.yml"
            else:
                st.warning("Interface status check not yet implemented for VyOS devices")
                return
            
            extra_vars = {"target_host": selected_device}
            
            if st.button("📊 Check Interface Status", type="primary"):
                with st.spinner(f"Checking interfaces on {selected_device}..."):
                    result = run_network_playbook(playbook, extra_vars)
                    display_results(result, f"Interface Status - {selected_device}")
        
        # Interface enable/disable section
        elif operation in ["Enable Interface", "Disable Interface"]:
            st.markdown(f"### {operation} on {selected_device}")
            
            # Interface selection
            device_type = "EOS" if device_group == "EOS Devices" else "VyOS"
            
            col_int1, col_int2 = st.columns(2)
            with col_int1:
                interface = st.selectbox(
                    "Select Interface:",
                    COMMON_INTERFACES[device_type],
                    key="interface_select"
                )
            
            with col_int2:
                custom_interface = st.text_input(
                    "Or enter custom interface:",
                    placeholder="e.g., Ethernet48"
                )
            
            # Use custom interface if provided
            target_interface = custom_interface if custom_interface else interface
            
            # Optional description
            description = st.text_input(
                "Interface Description (optional):",
                placeholder="Enter a description for this change"
            )
            
            # Dry run option
            check_mode = st.checkbox("🧪 Dry Run (check mode)")
            
            # Action button
            action = "enable" if operation == "Enable Interface" else "disable"
            action_emoji = "✅" if action == "enable" else "❌"
            
            if st.button(f"{action_emoji} {operation}", type="primary"):
                # Select appropriate playbook
                if device_group == "EOS Devices":
                    playbook = "network/eos-interface-toggle.yml"
                else:
                    playbook = "network/vyos-interface-toggle.yml"
                
                extra_vars = {
                    "target_host": selected_device,
                    "interface_name": target_interface,
                    "action": action,
                    "description": description
                }
                
                with st.spinner(f"{operation.title()}ing {target_interface} on {selected_device}..."):
                    result = run_network_playbook(playbook, extra_vars, check_mode)
                    display_results(result, f"{operation} - {selected_device}:{target_interface}")
    
    with col2:
        st.header("📋 Quick Actions")
        
        # Quick device ping test
        if st.button("🏓 Ping Test"):
            with st.spinner("Testing connectivity..."):
                result = subprocess.run(
                    ["ping", "-c", "3", device_ip],
                    capture_output=True,
                    text=True
                )
                if result.returncode == 0:
                    st.success(f"✅ {selected_device} is reachable")
                else:
                    st.error(f"❌ {selected_device} is not reachable")
                
                with st.expander("Ping Output"):
                    st.code(result.stdout)
        
        st.divider()
        
        # Device summary
        st.subheader("🔍 Device Summary")
        st.text(f"Group: {device_group}")
        st.text(f"Device: {selected_device}")
        st.text(f"IP: {device_ip}")
        
        if device_group == "EOS Devices":
            st.text("Type: Arista EOS")
            st.text("Connection: HTTPAPI")
            st.text("Port: 443")
        else:
            st.text("Type: VyOS Firewall")
            st.text("Connection: Network CLI")
            st.text("Port: 22")
        
        st.divider()
        
        # Available playbooks
        st.subheader("📂 Available Playbooks")
        playbooks = get_network_playbooks()
        for playbook in playbooks:
            st.text(f"• {playbook}")

def display_results(result, title):
    """Display execution results with proper formatting"""
    st.subheader(f"📊 {title}")
    
    # Status indicator
    if result.returncode == 0:
        st.success("✅ Operation completed successfully!")
    else:
        st.error(f"❌ Operation failed with return code {result.returncode}")
    
    # Create tabs for output
    tab1, tab2 = st.tabs(["📤 Output", "🚨 Errors"])
    
    with tab1:
        if result.stdout:
            st.code(result.stdout, language="yaml")
        else:
            st.info("No output")
    
    with tab2:
        if result.stderr:
            st.code(result.stderr, language="text")
        else:
            st.success("No errors")

if __name__ == "__main__":
    # Ensure directories exist
    os.makedirs(PLAYBOOKS_DIR, exist_ok=True)
    os.makedirs(LOGS_DIR, exist_ok=True)
    
    # Check if inventory exists
    if not os.path.exists(INVENTORY_FILE):
        st.error(f"❌ Inventory file not found at {INVENTORY_FILE}")
        st.info("Please ensure the inventory.yaml file is in the playbooks directory")
        st.stop()
    
    main() 