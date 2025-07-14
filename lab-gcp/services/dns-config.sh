#!/bin/bash

# ==============================================================================
# Enterprise GCP Demo Lab - DNS Configuration Script
# ==============================================================================
# This script configures the Technitium DNS server with zones and records
# Can be run independently or as part of the main deployment
# ==============================================================================

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="${SCRIPT_DIR}/config.env"

# Load configuration
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "Error: Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# ==============================================================================
# Logging functions
# ==============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
    esac
}

# ==============================================================================
# DNS Configuration Functions
# ==============================================================================

check_dns_server() {
    log "INFO" "Checking DNS server availability at $DNS_SERVER"
    
    if curl -s "$DNS_SERVER" &>/dev/null; then
        log "INFO" "DNS server is accessible"
        return 0
    else
        log "ERROR" "DNS server is not accessible at $DNS_SERVER"
        return 1
    fi
}

authenticate_dns() {
    log "INFO" "Authenticating with DNS server"
    
    # Get API token
    local api_token
    api_token=$(curl -s -X POST "$DNS_SERVER/api/user/createToken?user=$DNS_USERNAME&pass=$DNS_PASSWORD&tokenName=admin" | jq -r '.token')
    
    if [[ -z "$api_token" || "$api_token" == "null" ]]; then
        log "ERROR" "Failed to fetch API token"
        return 1
    fi
    
    # Get session token
    local session_token
    session_token=$(curl -s -X POST "$DNS_SERVER/api/user/login?user=$DNS_USERNAME&pass=$DNS_PASSWORD" | jq -r '.token')
    
    if [[ -z "$session_token" || "$session_token" == "null" ]]; then
        log "ERROR" "Failed to authenticate"
        return 1
    fi
    
    # Export tokens for use in other functions
    export API_TOKEN="$api_token"
    export SESSION_TOKEN="$session_token"
    
    log "INFO" "Authentication successful"
    return 0
}

create_dns_zone() {
    log "INFO" "Creating DNS zone $ZONE_NAME"
    
    # Check if zone exists
    local zone_check
    zone_check=$(curl -s -X GET "$DNS_SERVER/api/zones/list?token=$SESSION_TOKEN" | jq -r ".response.zones[]? | select(.name==\"$ZONE_NAME\")")
    
    if [[ -z "$zone_check" ]]; then
        local zone_response
        zone_response=$(curl -s -X POST "$DNS_SERVER/api/zones/create?token=$SESSION_TOKEN&zone=$ZONE_NAME&type=Primary")
        
        if echo "$zone_response" | grep -q '"status":"ok"'; then
            log "INFO" "DNS zone $ZONE_NAME created successfully"
        else
            log "ERROR" "Failed to create DNS zone $ZONE_NAME"
            return 1
        fi
    else
        log "INFO" "DNS zone $ZONE_NAME already exists"
    fi
    
    return 0
}

add_dns_record() {
    local subdomain="$1"
    local ip="$2"
    local record_type="${3:-A}"
    local ttl="${4:-3600}"
    
    log "INFO" "Adding $record_type record: $subdomain.$ZONE_NAME -> $ip"
    
    local response
    response=$(curl -s -X POST "$DNS_SERVER/api/zones/records/add?token=$SESSION_TOKEN&zone=$ZONE_NAME&domain=$subdomain.$ZONE_NAME&type=$record_type&ttl=$ttl&overwrite=true&ipAddress=$ip")
    
    if echo "$response" | grep -q '"status":"ok"'; then
        log "INFO" "Added $record_type record: $subdomain.$ZONE_NAME -> $ip"
    else
        log "ERROR" "Failed to add $record_type record for $subdomain.$ZONE_NAME"
        return 1
    fi
    
    return 0
}

configure_dns_records() {
    log "INFO" "Configuring DNS records for $ZONE_NAME"
    
    # Define DNS records
    local -A dns_records=(
        ["web"]="10.1.10.50"
        ["web1"]="10.1.10.101"
        ["web2"]="10.1.10.103"
        ["api"]="10.1.11.50"
        ["api1"]="10.1.11.102"
        ["api2"]="10.1.11.104"
        ["db"]="10.1.11.104"
        ["dns"]="10.1.10.101"
        ["haproxy1"]="10.1.10.50"
        ["haproxy2"]="10.1.11.50"
    )
    
    # Add A records
    for subdomain in "${!dns_records[@]}"; do
        local ip="${dns_records[$subdomain]}"
        add_dns_record "$subdomain" "$ip" "A"
    done
    
    # Add CNAME records for convenience
    add_cname_record "www" "web"
    add_cname_record "database" "db"
    add_cname_record "lb1" "haproxy1"
    add_cname_record "lb2" "haproxy2"
    
    log "INFO" "DNS records configuration completed"
}

add_cname_record() {
    local alias="$1"
    local target="$2"
    
    log "INFO" "Adding CNAME record: $alias.$ZONE_NAME -> $target.$ZONE_NAME"
    
    local response
    response=$(curl -s -X POST "$DNS_SERVER/api/zones/records/add?token=$SESSION_TOKEN&zone=$ZONE_NAME&domain=$alias.$ZONE_NAME&type=CNAME&ttl=3600&overwrite=true&cname=$target.$ZONE_NAME")
    
    if echo "$response" | grep -q '"status":"ok"'; then
        log "INFO" "Added CNAME record: $alias.$ZONE_NAME -> $target.$ZONE_NAME"
    else
        log "ERROR" "Failed to add CNAME record for $alias.$ZONE_NAME"
        return 1
    fi
    
    return 0
}

enable_dns_logging() {
    log "INFO" "Enabling DNS query logging"
    
    local log_response
    log_response=$(curl -s -X POST "$DNS_SERVER/api/settings/set?token=$SESSION_TOKEN" -d "enableLogging=true")
    
    if echo "$log_response" | grep -q '"status":"ok"'; then
        log "INFO" "DNS query logging enabled"
    else
        log "ERROR" "Failed to enable DNS query logging"
        return 1
    fi
    
    return 0
}

install_log_exporter() {
    log "INFO" "Installing Log Exporter App"
    
    local install_response
    install_response=$(curl -s -X GET "$DNS_SERVER/api/apps/downloadAndInstall?token=$API_TOKEN&name=Log%20Exporter&url=https%3A%2F%2Fdownload.technitium.com%2Fdns%2Fapps%2FLogExporterApp-v1.0.2.zip")
    
    if echo "$install_response" | grep -q '"status":"ok"'; then
        log "INFO" "Log Exporter App installed successfully"
        configure_log_exporter
    else
        log "ERROR" "Failed to install Log Exporter App"
        return 1
    fi
}

configure_log_exporter() {
    log "INFO" "Configuring Log Exporter App for syslog export"
    
    local config_response
    config_response=$(curl -s -X POST "$DNS_SERVER/api/apps/config/set?token=$API_TOKEN&name=Log%20Exporter" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data-urlencode "config={
            \"maxQueueSize\": 1000000,
            \"file\": {
                \"path\": \"./dns_logs.json\",
                \"enabled\": false
            },
            \"http\": {
                \"endpoint\": \"http://localhost:5000/logs\",
                \"headers\": {
                    \"Authorization\": \"Bearer abc123\"
                },
                \"enabled\": false
            },
            \"syslog\": {
                \"address\": \"$SYSLOG_SERVER\",
                \"port\": 514,
                \"protocol\": \"UDP\",
                \"enabled\": true
            }
        }")
    
    if echo "$config_response" | grep -q '"status":"ok"'; then
        log "INFO" "Log Exporter App configured for syslog export to $SYSLOG_SERVER:514"
    else
        log "ERROR" "Failed to configure Log Exporter App"
        return 1
    fi
}

list_dns_records() {
    log "INFO" "Listing DNS records for zone $ZONE_NAME"
    
    local records_response
    records_response=$(curl -s -X GET "$DNS_SERVER/api/zones/records/get?token=$SESSION_TOKEN&zone=$ZONE_NAME")
    
    if echo "$records_response" | grep -q '"status":"ok"'; then
        echo
        echo "===================================================="
        echo "           DNS RECORDS FOR $ZONE_NAME"
        echo "===================================================="
        echo "$records_response" | jq -r '.response.records[] | select(.type == "A" or .type == "CNAME") | "\(.name) \(.type) \(.rData.ipAddress // .rData.cname)"'
        echo "===================================================="
        echo
    else
        log "ERROR" "Failed to retrieve DNS records"
        return 1
    fi
}

test_dns_resolution() {
    log "INFO" "Testing DNS resolution"
    
    local test_domains=("web" "api" "db" "www")
    
    for domain in "${test_domains[@]}"; do
        local full_domain="$domain.$ZONE_NAME"
        log "INFO" "Testing resolution for $full_domain"
        
        if nslookup "$full_domain" "$PRIMARY_DNS" &>/dev/null; then
            log "INFO" "✓ $full_domain resolves correctly"
        else
            log "WARN" "✗ $full_domain failed to resolve"
        fi
    done
}

# ==============================================================================
# Main Functions
# ==============================================================================

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

DNS Configuration Script for Enterprise GCP Demo Lab

OPTIONS:
    -h, --help          Show this help message
    -c, --configure     Configure DNS zones and records
    -l, --list          List current DNS records
    -t, --test          Test DNS resolution
    -a, --all           Run full configuration (default)

EXAMPLES:
    $0                  # Run full DNS configuration
    $0 --configure      # Configure zones and records only
    $0 --list           # List current records
    $0 --test           # Test DNS resolution

EOF
}

configure_dns() {
    log "INFO" "Starting DNS configuration"
    
    # Check dependencies
    if ! command -v curl &> /dev/null; then
        log "ERROR" "curl is required but not installed"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log "ERROR" "jq is required but not installed"
        exit 1
    fi
    
    # Check DNS server availability
    check_dns_server
    
    # Authenticate
    authenticate_dns
    
    # Create zone
    create_dns_zone
    
    # Configure records
    configure_dns_records
    
    # Enable logging
    enable_dns_logging
    
    # Install and configure log exporter
    install_log_exporter
    
    log "INFO" "DNS configuration completed successfully"
}

# ==============================================================================
# Main Execution
# ==============================================================================

main() {
    local action="all"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -c|--configure)
                action="configure"
                shift
                ;;
            -l|--list)
                action="list"
                shift
                ;;
            -t|--test)
                action="test"
                shift
                ;;
            -a|--all)
                action="all"
                shift
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    case $action in
        "configure")
            configure_dns
            ;;
        "list")
            check_dns_server
            authenticate_dns
            list_dns_records
            ;;
        "test")
            test_dns_resolution
            ;;
        "all")
            configure_dns
            list_dns_records
            test_dns_resolution
            ;;
        *)
            log "ERROR" "Invalid action: $action"
            exit 1
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 