#!/bin/bash

# ==============================================================================
# Enterprise GCP Demo Lab - Cleanup Script
# ==============================================================================
# This script safely stops and removes all deployed services and containers
# Used for cleanup after testing or before redeployment
# ==============================================================================

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="${SCRIPT_DIR}/config.env"
readonly LOG_FILE="${SCRIPT_DIR}/cleanup.log"

# Load configuration if available
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# ==============================================================================
# Logging functions
# ==============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} $message" ;;
    esac
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# ==============================================================================
# Cleanup functions
# ==============================================================================

cleanup_container_services() {
    local container="$1"
    
    log "INFO" "Cleaning up services in container: $container"
    
    # Check if container exists
    if ! docker exec "$container" true &>/dev/null; then
        log "WARN" "Container $container not found or not running"
        return 0
    fi
    
    # Stop and remove all running containers within the container
    log "INFO" "Stopping services in $container"
    
    # Get list of running containers
    local running_containers
    running_containers=$(docker exec "$container" docker ps -q 2>/dev/null || echo "")
    
    if [[ -n "$running_containers" ]]; then
        # Stop containers gracefully
        docker exec "$container" docker stop $running_containers 2>/dev/null || true
        
        # Remove containers
        docker exec "$container" docker rm $running_containers 2>/dev/null || true
        
        log "INFO" "Stopped and removed services in $container"
    else
        log "INFO" "No running services found in $container"
    fi
    
    # Clean up Docker volumes and networks
    docker exec "$container" docker volume prune -f 2>/dev/null || true
    docker exec "$container" docker network prune -f 2>/dev/null || true
    
    # Stop Docker daemon if running
    if docker exec "$container" pgrep dockerd &>/dev/null; then
        log "INFO" "Stopping Docker daemon in $container"
        docker exec "$container" pkill dockerd || true
    fi
}

cleanup_network_config() {
    local container="$1"
    
    log "INFO" "Cleaning up network configuration in: $container"
    
    # Check if container exists
    if ! docker exec "$container" true &>/dev/null; then
        log "WARN" "Container $container not found or not running"
        return 0
    fi
    
    # Remove VLAN interfaces
    local vlan_interfaces
    vlan_interfaces=$(docker exec "$container" ip link show | grep -E "eth1\.(110|111)" | awk '{print $2}' | tr -d ':' 2>/dev/null || echo "")
    
    if [[ -n "$vlan_interfaces" ]]; then
        for interface in $vlan_interfaces; do
            log "INFO" "Removing VLAN interface: $interface"
            docker exec "$container" ip link delete "$interface" 2>/dev/null || true
        done
    fi
    
    # Reset resolv.conf to defaults
    docker exec "$container" sh -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf' 2>/dev/null || true
    
    log "INFO" "Network configuration cleaned up in $container"
}

cleanup_haproxy() {
    local container="$1"
    
    log "INFO" "Cleaning up HAProxy in: $container"
    
    # Check if container exists
    if ! docker exec "$container" true &>/dev/null; then
        log "WARN" "Container $container not found or not running"
        return 0
    fi
    
    # Stop HAProxy processes
    if docker exec "$container" pgrep haproxy &>/dev/null; then
        log "INFO" "Stopping HAProxy processes in $container"
        docker exec "$container" pkill haproxy || true
    fi
    
    log "INFO" "HAProxy cleanup completed in $container"
}

cleanup_dns_zone() {
    local zone_name="${1:-$ZONE_NAME}"
    
    log "INFO" "Cleaning up DNS zone: $zone_name"
    
    # Check if DNS server is accessible
    if ! curl -s "${DNS_SERVER:-http://172.100.100.8:5380}" &>/dev/null; then
        log "WARN" "DNS server not accessible, skipping DNS cleanup"
        return 0
    fi
    
    # Authenticate with DNS server
    local session_token
    session_token=$(curl -s -X POST "${DNS_SERVER}/api/user/login?user=${DNS_USERNAME:-admin}&pass=${DNS_PASSWORD:-admin}" | jq -r '.token' 2>/dev/null || echo "")
    
    if [[ -z "$session_token" || "$session_token" == "null" ]]; then
        log "WARN" "Failed to authenticate with DNS server, skipping DNS cleanup"
        return 0
    fi
    
    # Delete DNS zone
    local delete_response
    delete_response=$(curl -s -X POST "${DNS_SERVER}/api/zones/delete?token=$session_token&zone=$zone_name" 2>/dev/null || echo "")
    
    if echo "$delete_response" | grep -q '"status":"ok"'; then
        log "INFO" "DNS zone $zone_name deleted successfully"
    else
        log "WARN" "Failed to delete DNS zone $zone_name or zone doesn't exist"
    fi
}

# ==============================================================================
# Main cleanup functions
# ==============================================================================

cleanup_all_services() {
    log "INFO" "Starting comprehensive service cleanup"
    
    # Client containers
    local client_containers=("clab-s2-dc1_client1" "clab-s2-dc1_client2" "clab-s2-dc1_client3" "clab-s2-dc1_client4")
    
    for container in "${client_containers[@]}"; do
        cleanup_container_services "$container"
        cleanup_network_config "$container"
    done
    
    # HAProxy containers
    local haproxy_containers=("clab-s2-dc1_haproxy1" "clab-s2-dc1_haproxy2")
    
    for container in "${haproxy_containers[@]}"; do
        cleanup_haproxy "$container"
        cleanup_network_config "$container"
    done
    
    # DNS cleanup
    cleanup_dns_zone
    
    log "INFO" "Service cleanup completed"
}

cleanup_logs() {
    log "INFO" "Cleaning up log files"
    
    # Clean up deployment logs
    if [[ -f "${SCRIPT_DIR}/deployment.log" ]]; then
        rm -f "${SCRIPT_DIR}/deployment.log"
        log "INFO" "Deployment log cleaned up"
    fi
    
    # Clean up this cleanup log (after current session)
    trap 'rm -f "$LOG_FILE"' EXIT
}

verify_cleanup() {
    log "INFO" "Verifying cleanup completion"
    
    local client_containers=("clab-s2-dc1_client1" "clab-s2-dc1_client2" "clab-s2-dc1_client3" "clab-s2-dc1_client4")
    local all_clean=true
    
    for container in "${client_containers[@]}"; do
        if docker exec "$container" true &>/dev/null; then
            # Check for running containers
            local running_containers
            running_containers=$(docker exec "$container" docker ps -q 2>/dev/null || echo "")
            
            if [[ -n "$running_containers" ]]; then
                log "WARN" "Container $container still has running services: $running_containers"
                all_clean=false
            fi
            
            # Check for VLAN interfaces
            local vlan_interfaces
            vlan_interfaces=$(docker exec "$container" ip link show | grep -E "eth1\.(110|111)" 2>/dev/null || echo "")
            
            if [[ -n "$vlan_interfaces" ]]; then
                log "WARN" "Container $container still has VLAN interfaces configured"
                all_clean=false
            fi
        fi
    done
    
    if [[ "$all_clean" == true ]]; then
        log "INFO" "✓ Cleanup verification passed - all services cleaned up"
    else
        log "WARN" "✗ Cleanup verification failed - some services may still be running"
    fi
}

# ==============================================================================
# Interactive functions
# ==============================================================================

show_status() {
    log "INFO" "Showing current deployment status"
    
    echo
    echo "===================================================="
    echo "           DEPLOYMENT STATUS"
    echo "===================================================="
    
    local client_containers=("clab-s2-dc1_client1" "clab-s2-dc1_client2" "clab-s2-dc1_client3" "clab-s2-dc1_client4")
    
    for container in "${client_containers[@]}"; do
        if docker exec "$container" true &>/dev/null; then
            echo "Container: $container"
            
            # Show running services
            local running_services
            running_services=$(docker exec "$container" docker ps --format "table {{.Names}}\t{{.Ports}}\t{{.Status}}" 2>/dev/null || echo "None")
            echo "  Running services: $running_services"
            
            # Show network interfaces
            local vlan_interfaces
            vlan_interfaces=$(docker exec "$container" ip addr show | grep -E "eth1\.(110|111)" | awk '{print $2}' | tr -d ':' 2>/dev/null || echo "None")
            echo "  VLAN interfaces: $vlan_interfaces"
            
            echo
        else
            echo "Container: $container (NOT RUNNING)"
        fi
    done
    
    echo "===================================================="
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Cleanup Script for Enterprise GCP Demo Lab

OPTIONS:
    -h, --help          Show this help message
    -a, --all           Clean up all services (default)
    -s, --services      Clean up only containerized services
    -n, --network       Clean up only network configuration
    -d, --dns           Clean up only DNS configuration
    -l, --logs          Clean up log files
    -v, --verify        Verify cleanup completion
    --status            Show current deployment status
    --force             Force cleanup without confirmation

EXAMPLES:
    $0                  # Interactive cleanup with confirmation
    $0 --all --force    # Force cleanup of everything
    $0 --services       # Clean up only services
    $0 --status         # Show current status

EOF
}

# ==============================================================================
# Main execution
# ==============================================================================

main() {
    local action="all"
    local force=false
    
    # Initialize log file
    > "$LOG_FILE"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -a|--all)
                action="all"
                shift
                ;;
            -s|--services)
                action="services"
                shift
                ;;
            -n|--network)
                action="network"
                shift
                ;;
            -d|--dns)
                action="dns"
                shift
                ;;
            -l|--logs)
                action="logs"
                shift
                ;;
            -v|--verify)
                action="verify"
                shift
                ;;
            --status)
                action="status"
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Show status first
    if [[ "$action" != "status" ]]; then
        show_status
    fi
    
    # Confirmation prompt (unless forced)
    if [[ "$force" == false && "$action" != "status" && "$action" != "verify" ]]; then
        echo
        read -p "Are you sure you want to proceed with cleanup? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "INFO" "Cleanup cancelled by user"
            exit 0
        fi
    fi
    
    # Execute requested action
    case $action in
        "all")
            cleanup_all_services
            verify_cleanup
            ;;
        "services")
            local client_containers=("clab-s2-dc1_client1" "clab-s2-dc1_client2" "clab-s2-dc1_client3" "clab-s2-dc1_client4")
            for container in "${client_containers[@]}"; do
                cleanup_container_services "$container"
            done
            local haproxy_containers=("clab-s2-dc1_haproxy1" "clab-s2-dc1_haproxy2")
            for container in "${haproxy_containers[@]}"; do
                cleanup_haproxy "$container"
            done
            ;;
        "network")
            local all_containers=("clab-s2-dc1_client1" "clab-s2-dc1_client2" "clab-s2-dc1_client3" "clab-s2-dc1_client4" "clab-s2-dc1_haproxy1" "clab-s2-dc1_haproxy2")
            for container in "${all_containers[@]}"; do
                cleanup_network_config "$container"
            done
            ;;
        "dns")
            cleanup_dns_zone
            ;;
        "logs")
            cleanup_logs
            ;;
        "verify")
            verify_cleanup
            ;;
        "status")
            show_status
            ;;
        *)
            log "ERROR" "Invalid action: $action"
            exit 1
            ;;
    esac
    
    log "INFO" "Cleanup script completed"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 