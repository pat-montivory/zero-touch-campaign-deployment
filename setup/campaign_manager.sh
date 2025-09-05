#!/bin/bash

# Campaign Manager - Unified Campaign Management Tool
# Consolidates: detect_campaigns, auto_deploy, ultimate_deploy, combine.sh

set -e

# Configuration
CAMPAIGNS_DIR="/var/www/campaignmanagerv12/campaigns"
NGINX_DIR="/var/www/campaignmanagerv12/nginx"
CONFIG_FILE="$NGINX_DIR/campaignmanagerv12.conf"
BACKUP_DIR="$NGINX_DIR/backups"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Icons
ROCKET="🚀"
CHECK="✅"
ERROR="❌"
INFO="ℹ️"
WARNING="⚠️"
FOLDER="📁"
WRENCH="🔧"

# Usage function
usage() {
    echo -e "${BLUE}${ROCKET} Campaign Manager - Unified Tool${NC}"
    echo "Usage: $0 <command> [options]"
    echo ""
    echo -e "${GREEN}COMMANDS:${NC}"
    echo "  detect     - Detect available campaigns"
    echo "  deploy     - Deploy campaigns with nginx configuration"
    echo "  configure  - Configure nginx for existing campaigns"
    echo "  status     - Show campaign status"
    echo "  list       - List available campaigns"
    echo "  backup     - Backup current configuration"
    echo ""
    echo -e "${YELLOW}OPTIONS:${NC}"
    echo "  --campaign NAME    - Target specific campaign"
    echo "  --force           - Force operation without confirmation"
    echo "  --dry-run         - Show what would be done without executing"
    echo "  --verbose         - Enable verbose output"
    echo "  --separate-config - Use separate config files"
    echo ""
    echo -e "${CYAN}EXAMPLES:${NC}"
    echo "  $0 detect --verbose"
    echo "  $0 deploy --campaign VisoPisesLiquidShop"
    echo "  $0 configure --separate-config"
    echo "  $0 status"
}

# Logging functions
log_info() {
    echo -e "${INFO} $1"
}

log_success() {
    echo -e "${CHECK} ${GREEN}$1${NC}"
}

log_warning() {
    echo -e "${WARNING} ${YELLOW}$1${NC}"
}

log_error() {
    echo -e "${ERROR} ${RED}$1${NC}"
}

# Parse command line arguments
COMMAND=""
CAMPAIGN=""
FORCE=false
DRY_RUN=false
VERBOSE=false
SEPARATE_CONFIG=false

while [[ $# -gt 0 ]]; do
    case $1 in
        detect|deploy|configure|status|list|backup)
            COMMAND=$1
            shift
            ;;
        --campaign)
            CAMPAIGN="$2"
            shift 2
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --separate-config)
            SEPARATE_CONFIG=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

if [[ -z "$COMMAND" ]]; then
    log_error "No command specified"
    usage
    exit 1
fi

# Detect campaigns function
detect_campaigns() {
    log_info "Detecting campaigns in $CAMPAIGNS_DIR..."
    
    if [[ ! -d "$CAMPAIGNS_DIR" ]]; then
        log_error "Campaigns directory does not exist: $CAMPAIGNS_DIR"
        return 1
    fi
    
    local campaigns=()
    local static_campaigns=()
    local laravel_campaigns=()
    
    for dir in "$CAMPAIGNS_DIR"/*; do
        if [[ -d "$dir" ]]; then
            local campaign_name=$(basename "$dir")
            campaigns+=("$campaign_name")
            
            # Check if it's a static campaign (has index.php or index.html)
            if [[ -f "$dir/index.php" || -f "$dir/index.html" ]]; then
                static_campaigns+=("$campaign_name")
                [[ "$VERBOSE" == true ]] && log_info "Found static campaign: $campaign_name"
            fi
            
            # Check if it's a Laravel campaign (has composer.json and artisan)
            if [[ -f "$dir/composer.json" && -f "$dir/artisan" ]]; then
                laravel_campaigns+=("$campaign_name")
                [[ "$VERBOSE" == true ]] && log_info "Found Laravel campaign: $campaign_name"
            fi
        fi
    done
    
    echo -e "${FOLDER} Campaign Detection Results:"
    echo "   Total campaigns: ${#campaigns[@]} (${campaigns[*]})"
    echo "   Static campaigns: ${#static_campaigns[@]} (${static_campaigns[*]})"
    echo "   Laravel campaigns: ${#laravel_campaigns[@]} (${laravel_campaigns[*]})"
    
    # Export for use by other functions
    export DETECTED_CAMPAIGNS="${campaigns[*]}"
    export STATIC_CAMPAIGNS="${static_campaigns[*]}"
    export LARAVEL_CAMPAIGNS="${laravel_campaigns[*]}"
    
    return 0
}

# Backup configuration function
backup_config() {
    local backup_file="$BACKUP_DIR/campaignmanagerv12.conf.backup.$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    if [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "$backup_file"
        log_success "Configuration backed up to: $backup_file"
        return 0
    else
        log_warning "No configuration file found to backup"
        return 1
    fi
}

# Generate nginx configuration for campaigns
generate_config() {
    local campaigns=($STATIC_CAMPAIGNS)
    
    if [[ ${#campaigns[@]} -eq 0 ]]; then
        log_warning "No static campaigns found to configure"
        return 0
    fi
    
    log_info "Generating nginx configuration for campaigns: ${campaigns[*]}"
    
    for campaign in "${campaigns[@]}"; do
        local campaign_dir="$CAMPAIGNS_DIR/$campaign"
        
        if [[ "$SEPARATE_CONFIG" == true ]]; then
            # Create separate config file
            local separate_config="$NGINX_DIR/${campaign}_static.conf"
            cat > "$separate_config" << EOF
# $campaign static website configuration

# $campaign static website
location ^~ /$campaign/ {
    alias $campaign_dir/;
    index index.php index.html index.htm;
    try_files \$uri \$uri/ =404;
    
    # Handle PHP files
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fmp.sock;
        fastcgi_param SCRIPT_FILENAME \$request_filename;
        include fastcgi_params;
    }
}

# $campaign static assets
location ~ ^/$campaign/(assets|css|js|images|img|fonts)/(.*)$ {
    alias $campaign_dir/;
    expires 30d;
    add_header Cache-Control "public, no-transform";
    try_files /\$1/\$2 =404;
    access_log off;
}
EOF
            log_success "Created separate config: $separate_config"
        else
            log_info "Configuration will be added to main config file"
        fi
    done
}

# Deploy campaigns
deploy_campaigns() {
    log_info "${WRENCH} Starting campaign deployment..."
    
    # First detect campaigns
    if ! detect_campaigns; then
        log_error "Campaign detection failed"
        return 1
    fi
    
    # Backup existing configuration
    if [[ "$DRY_RUN" == false ]]; then
        backup_config
    fi
    
    # Generate configuration
    if [[ "$DRY_RUN" == false ]]; then
        generate_config
        
        # Test nginx configuration
        log_info "Testing nginx configuration..."
        if sudo nginx -t; then
            log_success "Nginx configuration test passed"
            
            # Reload nginx
            log_info "Reloading nginx..."
            if sudo systemctl reload nginx; then
                log_success "Nginx reloaded successfully"
            else
                log_error "Failed to reload nginx"
                return 1
            fi
        else
            log_error "Nginx configuration test failed"
            return 1
        fi
    else
        log_info "[DRY RUN] Would generate configuration and reload nginx"
    fi
    
    # Show results
    local campaigns=($STATIC_CAMPAIGNS)
    if [[ ${#campaigns[@]} -gt 0 ]]; then
        echo ""
        echo -e "${ROCKET} Deployed campaigns are now accessible:"
        for campaign in "${campaigns[@]}"; do
            echo "   ${CHECK} https://devpayload.southeastasia.cloudapp.azure.com/$campaign/"
            echo "   ${CHECK} https://devpayload.southeastasia.cloudapp.azure.com/$campaign/index.php"
        done
    fi
}

# Show campaign status
show_status() {
    log_info "Campaign Status Report"
    echo "===================="
    
    # Check nginx status
    if systemctl is-active --quiet nginx; then
        log_success "Nginx is running"
    else
        log_error "Nginx is not running"
    fi
    
    # Detect and show campaigns
    detect_campaigns
    
    # Check if campaigns are accessible
    local campaigns=($STATIC_CAMPAIGNS)
    if [[ ${#campaigns[@]} -gt 0 ]]; then
        echo ""
        echo "Campaign Accessibility:"
        for campaign in "${campaigns[@]}"; do
            local url="https://devpayload.southeastasia.cloudapp.azure.com/$campaign/"
            if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|302"; then
                echo "   ${CHECK} $campaign - Accessible"
            else
                echo "   ${ERROR} $campaign - Not accessible"
            fi
        done
    fi
}

# List campaigns
list_campaigns() {
    detect_campaigns
    echo ""
    echo -e "${FOLDER} Available Campaigns:"
    
    local campaigns=($DETECTED_CAMPAIGNS)
    for campaign in "${campaigns[@]}"; do
        local type=""
        if [[ " $STATIC_CAMPAIGNS " =~ " $campaign " ]]; then
            type="${GREEN}[Static]${NC}"
        elif [[ " $LARAVEL_CAMPAIGNS " =~ " $campaign " ]]; then
            type="${BLUE}[Laravel]${NC}"
        else
            type="${YELLOW}[Unknown]${NC}"
        fi
        echo "   • $campaign $type"
    done
}

# Main execution
case $COMMAND in
    detect)
        detect_campaigns
        ;;
    deploy)
        deploy_campaigns
        ;;
    configure)
        generate_config
        ;;
    status)
        show_status
        ;;
    list)
        list_campaigns
        ;;
    backup)
        backup_config
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac