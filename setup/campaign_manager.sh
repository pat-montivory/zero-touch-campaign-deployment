#!/bin/bash

# Campaign Manager - Unified Campaign Management Tool
# Consolidates: detect_campaigns, auto_deploy, ultimate_deploy, combine.sh

set -e

# Configuration
CAMPAIGNS_DIR="/var/www/campaignmanagerv12/campaigns"
NGINX_DIR="/var/www/campaignmanagerv12/nginx"
CONFIG_FILE="$NGINX_DIR/campaignmanagerv12.conf"
BACKUP_DIR="$NGINX_DIR/backups"

# Permission settings
DIR_PERMISSIONS="775"
FILE_PERMISSIONS="664"
EXEC_PERMISSIONS="775"
WEB_USER="www-data"
WEB_GROUP="www-data"

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
    echo "  permissions - Set proper file and directory permissions"
    echo "  debug      - Show detailed debug information"
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
    echo "  $0 permissions --campaign knorrBackToSchool"
    echo "  $0 debug --verbose"
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
        detect|deploy|configure|status|list|backup|permissions|debug)
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
            # Create separate config file with proper naming format
            local config_type=""
            if [[ -f "$campaign_dir/index.php" ]]; then
                config_type="static"
            elif [[ -f "$campaign_dir/composer.json" && -f "$campaign_dir/artisan" ]]; then
                config_type="laravel"
            else
                config_type="static"
            fi
            
            local separate_config="$NGINX_DIR/${config_type}_${campaign}.conf"
            [[ "$VERBOSE" == true ]] && log_info "Creating separate config: $separate_config"
            
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

# Set proper permissions function
set_permissions() {
    log_info "${WRENCH} Setting proper file and directory permissions..."
    
    local campaigns=()
    if [[ -n "$CAMPAIGN" ]]; then
        campaigns=("$CAMPAIGN")
    else
        # Get all detected campaigns
        detect_campaigns > /dev/null
        campaigns=($DETECTED_CAMPAIGNS)
    fi
    
    if [[ ${#campaigns[@]} -eq 0 ]]; then
        log_warning "No campaigns found to set permissions"
        return 0
    fi
    
    for campaign in "${campaigns[@]}"; do
        local campaign_dir="$CAMPAIGNS_DIR/$campaign"
        
        if [[ ! -d "$campaign_dir" ]]; then
            log_warning "Campaign directory not found: $campaign_dir"
            continue
        fi
        
        log_info "Setting permissions for campaign: $campaign"
        
        if [[ "$DRY_RUN" == false ]]; then
            # Set ownership
            [[ "$VERBOSE" == true ]] && log_info "Setting ownership to $WEB_USER:$WEB_GROUP"
            sudo chown -R "$WEB_USER:$WEB_GROUP" "$campaign_dir"
            
            # Set directory permissions (775)
            [[ "$VERBOSE" == true ]] && log_info "Setting directory permissions to $DIR_PERMISSIONS"
            find "$campaign_dir" -type d -exec chmod "$DIR_PERMISSIONS" {} \;
            
            # Set file permissions (664)
            [[ "$VERBOSE" == true ]] && log_info "Setting file permissions to $FILE_PERMISSIONS"
            find "$campaign_dir" -type f -exec chmod "$FILE_PERMISSIONS" {} \;
            
            # Set executable permissions for specific files
            if [[ -f "$campaign_dir/artisan" ]]; then
                chmod "$EXEC_PERMISSIONS" "$campaign_dir/artisan"
            fi
            
            # Set special permissions for storage and cache directories (Laravel)
            if [[ -d "$campaign_dir/storage" ]]; then
                [[ "$VERBOSE" == true ]] && log_info "Setting Laravel storage permissions"
                chmod -R 775 "$campaign_dir/storage"
            fi
            
            if [[ -d "$campaign_dir/bootstrap/cache" ]]; then
                chmod -R 775 "$campaign_dir/bootstrap/cache"
            fi
            
            log_success "Permissions set for: $campaign"
        else
            log_info "[DRY RUN] Would set permissions for: $campaign"
            echo "  - Directory permissions: $DIR_PERMISSIONS"
            echo "  - File permissions: $FILE_PERMISSIONS"
            echo "  - Owner: $WEB_USER:$WEB_GROUP"
        fi
    done
    
    log_success "Permission setting completed"
}

# Debug information function
show_debug_info() {
    log_info "${WRENCH} Gathering debug information..."
    
    echo "==================== SYSTEM INFORMATION ===================="
    echo -e "${BLUE}System:${NC} $(uname -a)"
    echo -e "${BLUE}Date:${NC} $(date)"
    echo -e "${BLUE}User:${NC} $(whoami)"
    echo -e "${BLUE}Working Directory:${NC} $(pwd)"
    echo ""
    
    echo "==================== NGINX STATUS ===================="
    if systemctl is-active --quiet nginx; then
        echo -e "${GREEN}Nginx Status: Running${NC}"
        echo -e "${BLUE}Version:${NC} $(nginx -v 2>&1)"
        echo -e "${BLUE}Configuration Test:${NC}"
        if sudo nginx -t 2>/dev/null; then
            echo -e "  ${CHECK} Configuration is valid"
        else
            echo -e "  ${ERROR} Configuration has errors:"
            sudo nginx -t 2>&1 | sed 's/^/    /'
        fi
    else
        echo -e "${RED}Nginx Status: Not Running${NC}"
    fi
    echo ""
    
    echo "==================== PHP STATUS ===================="
    if command -v php >/dev/null 2>&1; then
        echo -e "${BLUE}PHP Version:${NC} $(php -v | head -1)"
        echo -e "${BLUE}PHP-FPM Status:${NC}"
        if systemctl is-active --quiet php8.4-fpm; then
            echo -e "  ${CHECK} PHP-FPM is running"
        else
            echo -e "  ${ERROR} PHP-FPM is not running"
        fi
    else
        echo -e "${RED}PHP not installed${NC}"
    fi
    echo ""
    
    echo "==================== DIRECTORY STRUCTURE ===================="
    echo -e "${BLUE}Base Directory:${NC} /var/www/campaignmanagerv12"
    if [[ -d "/var/www/campaignmanagerv12" ]]; then
        echo -e "  ${CHECK} Directory exists"
        ls -la /var/www/campaignmanagerv12 | head -10
        if [[ $(ls /var/www/campaignmanagerv12 | wc -l) -gt 10 ]]; then
            echo "  ... (truncated, $(ls /var/www/campaignmanagerv12 | wc -l) total items)"
        fi
    else
        echo -e "  ${ERROR} Directory does not exist"
    fi
    echo ""
    
    echo -e "${BLUE}Campaigns Directory:${NC} $CAMPAIGNS_DIR"
    if [[ -d "$CAMPAIGNS_DIR" ]]; then
        echo -e "  ${CHECK} Directory exists"
        local campaign_count=$(find "$CAMPAIGNS_DIR" -maxdepth 1 -type d | wc -l)
        echo "  Total subdirectories: $((campaign_count - 1))"
        if [[ "$VERBOSE" == true ]]; then
            ls -la "$CAMPAIGNS_DIR"
        fi
    else
        echo -e "  ${ERROR} Directory does not exist"
    fi
    echo ""
    
    echo -e "${BLUE}Nginx Directory:${NC} $NGINX_DIR"
    if [[ -d "$NGINX_DIR" ]]; then
        echo -e "  ${CHECK} Directory exists"
        if [[ "$VERBOSE" == true ]]; then
            ls -la "$NGINX_DIR"
        fi
    else
        echo -e "  ${ERROR} Directory does not exist"
    fi
    echo ""
    
    echo "==================== CAMPAIGN ANALYSIS ===================="
    detect_campaigns
    
    local campaigns=($DETECTED_CAMPAIGNS)
    for campaign in "${campaigns[@]}"; do
        local campaign_dir="$CAMPAIGNS_DIR/$campaign"
        echo -e "${BLUE}Campaign:${NC} $campaign"
        echo "  Path: $campaign_dir"
        echo "  Size: $(du -sh "$campaign_dir" 2>/dev/null | cut -f1)"
        
        # Check key files
        local key_files=("index.php" "index.html" "composer.json" "artisan" ".env")
        for file in "${key_files[@]}"; do
            if [[ -f "$campaign_dir/$file" ]]; then
                echo "  ${CHECK} $file exists"
            fi
        done
        
        # Check permissions
        local dir_perms=$(stat -c "%a" "$campaign_dir" 2>/dev/null)
        local owner=$(stat -c "%U:%G" "$campaign_dir" 2>/dev/null)
        echo "  Permissions: $dir_perms ($owner)"
        
        # Check accessibility
        local url="https://devpayload.southeastasia.cloudapp.azure.com/$campaign/"
        local status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
        if [[ "$status_code" == "200" || "$status_code" == "302" ]]; then
            echo -e "  ${CHECK} Accessible (HTTP $status_code)"
        else
            echo -e "  ${ERROR} Not accessible (HTTP $status_code)"
        fi
        echo ""
    done
    
    echo "==================== NGINX CONFIGURATION ===================="
    echo -e "${BLUE}Main Config:${NC} $CONFIG_FILE"
    if [[ -f "$CONFIG_FILE" ]]; then
        echo -e "  ${CHECK} Configuration file exists"
        echo "  Size: $(wc -l < "$CONFIG_FILE") lines"
        echo "  Last modified: $(stat -c "%y" "$CONFIG_FILE")"
        
        if [[ "$VERBOSE" == true ]]; then
            echo ""
            echo "Configuration preview (first 20 lines):"
            head -20 "$CONFIG_FILE" | sed 's/^/    /'
            echo "    ... (use --verbose for full content)"
        fi
    else
        echo -e "  ${ERROR} Configuration file does not exist"
    fi
    echo ""
    
    echo -e "${BLUE}Separate Config Files:${NC}"
    local separate_configs=($(find "$NGINX_DIR" -name "*_*.conf" 2>/dev/null))
    if [[ ${#separate_configs[@]} -gt 0 ]]; then
        for config in "${separate_configs[@]}"; do
            echo "  ${CHECK} $(basename "$config")"
        done
    else
        echo "  No separate configuration files found"
    fi
    echo ""
    
    echo "==================== TROUBLESHOOTING TIPS ===================="
    echo "Common nginx config file naming examples:"
    echo "  • static_VisoPisesLiquidShop.conf"
    echo "  • laravel_knorrBackToSchool.conf" 
    echo "  • static_unileverPromo.conf"
    echo ""
    echo "Debug commands:"
    echo "  • nginx -t                    (test configuration)"
    echo "  • systemctl status nginx      (check nginx status)"
    echo "  • systemctl status php8.4-fpm (check PHP-FPM status)"
    echo "  • tail -f /var/log/nginx/error.log (check error logs)"
    echo ""
    echo "Permission commands:"
    echo "  • $0 permissions --campaign CAMPAIGN_NAME"
    echo "  • chmod 775 directory_name"
    echo "  • chmod 664 file_name"
    echo "  • chown www-data:www-data directory_name"
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
    permissions)
        set_permissions
        ;;
    debug)
        show_debug_info
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac