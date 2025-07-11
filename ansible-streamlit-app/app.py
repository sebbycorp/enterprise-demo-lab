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
    page_title="Ansible Playbook Runner",
    page_icon="⚙️",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Constants
PLAYBOOKS_DIR = "/app/playbooks"
LOGS_DIR = "/app/logs"

def get_playbooks():
    """Get list of available playbooks"""
    if not os.path.exists(PLAYBOOKS_DIR):
        return []
    
    playbooks = []
    for file in glob.glob(f"{PLAYBOOKS_DIR}/**/*.yml", recursive=True) + \
                glob.glob(f"{PLAYBOOKS_DIR}/**/*.yaml", recursive=True):
        relative_path = os.path.relpath(file, PLAYBOOKS_DIR)
        playbooks.append(relative_path)
    
    return sorted(playbooks)

def parse_playbook_info(playbook_path):
    """Extract basic info from playbook"""
    try:
        with open(os.path.join(PLAYBOOKS_DIR, playbook_path), 'r') as file:
            content = yaml.safe_load(file)
            if isinstance(content, list) and len(content) > 0:
                first_play = content[0]
                return {
                    'name': first_play.get('name', 'Unnamed playbook'),
                    'hosts': first_play.get('hosts', 'localhost'),
                    'description': first_play.get('description', 'No description available')
                }
    except Exception as e:
        st.error(f"Error parsing playbook {playbook_path}: {e}")
    
    return {'name': 'Unknown', 'hosts': 'Unknown', 'description': 'Could not parse playbook'}

def run_ansible_playbook(playbook_path, inventory=None, extra_vars=None, check_mode=False):
    """Execute ansible playbook"""
    cmd = ["ansible-playbook"]
    
    # Add inventory if specified
    if inventory:
        cmd.extend(["-i", inventory])
    else:
        cmd.extend(["-i", "localhost,"])
    
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

# Main app
def main():
    st.title("⚙️ Ansible Playbook Runner")
    st.markdown("Select and execute Ansible playbooks from your collection")
    
    # Sidebar for playbook selection
    with st.sidebar:
        st.header("📋 Playbook Selection")
        
        playbooks = get_playbooks()
        
        if not playbooks:
            st.warning("No playbooks found in /app/playbooks directory")
            st.info("Add .yml or .yaml playbook files to get started")
            return
        
        selected_playbook = st.selectbox(
            "Choose a playbook:",
            playbooks,
            key="playbook_selector"
        )
        
        # Display playbook info
        if selected_playbook:
            st.subheader("📖 Playbook Info")
            info = parse_playbook_info(selected_playbook)
            st.text(f"Name: {info['name']}")
            st.text(f"Hosts: {info['hosts']}")
            st.text(f"Description: {info['description']}")
    
    # Main content area
    if selected_playbook:
        col1, col2 = st.columns([2, 1])
        
        with col1:
            st.header(f"🎯 Execute: {selected_playbook}")
            
            # Execution options
            with st.expander("⚙️ Execution Options", expanded=True):
                col_opts1, col_opts2 = st.columns(2)
                
                with col_opts1:
                    inventory = st.text_input(
                        "Inventory File (optional)",
                        placeholder="e.g., inventory.ini or leave empty for localhost"
                    )
                    
                    check_mode = st.checkbox(
                        "Dry Run Mode (--check)",
                        help="Run in check mode to see what would change"
                    )
                
                with col_opts2:
                    extra_vars_input = st.text_area(
                        "Extra Variables (JSON format)",
                        placeholder='{"variable": "value", "debug": true}',
                        height=100
                    )
            
            # Parse extra vars
            extra_vars = None
            if extra_vars_input.strip():
                try:
                    extra_vars = json.loads(extra_vars_input)
                    st.success("✅ Extra variables parsed successfully")
                except json.JSONDecodeError as e:
                    st.error(f"❌ Invalid JSON in extra variables: {e}")
            
            # Execute button
            if st.button("🚀 Execute Playbook", type="primary"):
                with st.spinner("Executing playbook..."):
                    result = run_ansible_playbook(
                        selected_playbook,
                        inventory if inventory else None,
                        extra_vars,
                        check_mode
                    )
                    
                    # Display results
                    st.subheader("📊 Execution Results")
                    
                    # Status
                    if result.returncode == 0:
                        st.success(f"✅ Playbook executed successfully!")
                    else:
                        st.error(f"❌ Playbook failed with return code {result.returncode}")
                    
                    # Output tabs
                    tab1, tab2 = st.tabs(["📤 Standard Output", "🚨 Standard Error"])
                    
                    with tab1:
                        if result.stdout:
                            st.code(result.stdout, language="yaml")
                        else:
                            st.info("No standard output")
                    
                    with tab2:
                        if result.stderr:
                            st.code(result.stderr, language="text")
                        else:
                            st.info("No errors")
        
        with col2:
            st.header("📄 Playbook Content")
            
            # Display playbook content
            try:
                with open(os.path.join(PLAYBOOKS_DIR, selected_playbook), 'r') as file:
                    content = file.read()
                    st.code(content, language="yaml")
            except Exception as e:
                st.error(f"Error reading playbook: {e}")
            
            # Quick actions
            st.subheader("🔧 Quick Actions")
            if st.button("📝 View Raw File"):
                st.text("File path: " + os.path.join(PLAYBOOKS_DIR, selected_playbook))
            
            if st.button("🔍 Syntax Check"):
                result = subprocess.run(
                    ["ansible-playbook", "--syntax-check", os.path.join(PLAYBOOKS_DIR, selected_playbook)],
                    capture_output=True,
                    text=True
                )
                if result.returncode == 0:
                    st.success("✅ Syntax is valid")
                else:
                    st.error("❌ Syntax errors found:")
                    st.code(result.stderr)

if __name__ == "__main__":
    # Ensure directories exist
    os.makedirs(PLAYBOOKS_DIR, exist_ok=True)
    os.makedirs(LOGS_DIR, exist_ok=True)
    
    main() 