#!/bin/bash

# Campaign Config - Pure Nginx Configuration Management
# Consolidates: update_nginx_config.sh, enhanced_update_nginx.sh, reload_nginx.sh

set -e

# Configuration
NGINX_DIR="/var/www/campaignmanagerv12/nginx"
CAMPAIGNS_DIR="/var/www/campaignmanagerv12/campaigns"
CONFIG_FILE="$NGINX_DIR/campaignmanagerv12.conf"
BACKUP_DIR="$NGINX_DIR/backups"
TEMPLATE_FILE="$NGINX_DIR/static_campaign.template"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Icons
CHECK="✅"
ERROR="❌"
INFO="ℹ️"
WARNING="⚠️"
WRENCH="🔧"
ROCKET="🚀"

usage() {
    echo -e "${BLUE}${WRENCH} Campaign Config - Nginx Configuration Management${NC}"
    echo "Usage: $0 <command> [options]"
    echo ""
    echo -e "${GREEN}COMMANDS:${NC}"
    echo "  generate   - Generate nginx configuration for campaigns"
    echo "  test       - Test nginx configuration"
    echo "  reload     - Reload nginx service"
    echo "  backup     - Backup current configuration"
    echo "  restore    - Restore from backup"
    echo "  clean      - Remove campaign configurations"
    echo ""
    echo -e "${YELLOW}OPTIONS:${NC}"
    echo "  --campaigns \"campaign1 campaign2\" - Specific campaigns"
    echo "  --separate                       - Use separate config files"
    echo "  --force                          - Force operation"
    echo "  --backup-file FILE               - Specific backup file to restore"
    echo ""
    echo -e "${BLUE}EXAMPLES:${NC}"
    echo "  $0 generate --campaigns \"VisoPisesLiquidShop\""
    echo "  $0 test"
    echo "  $0 reload"
    echo "  $0 backup"
}

log_info() { echo -e "${INFO} $1"; }
log_success() { echo -e "${CHECK} ${GREEN}$1${NC}"; }
log_warning() { echo -e "${WARNING} ${YELLOW}$1${NC}"; }
log_error() { echo -e "${ERROR} ${RED}$1${NC}"; }

# Parse arguments
COMMAND=""
CAMPAIGNS=""
SEPARATE=false
FORCE=false
BACKUP_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        generate|test|reload|backup|restore|clean)
            COMMAND=$1
            shift
            ;;
        --campaigns)
            CAMPAIGNS="$2"
            shift 2
            ;;
        --separate)
            SEPARATE=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --backup-file)
            BACKUP_FILE="$2"
            shift 2
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

# Get available campaigns
get_campaigns() {
    local campaigns=()
    
    if [[ -n "$CAMPAIGNS" ]]; then
        campaigns=($CAMPAIGNS)
    else
        # Auto-detect static campaigns
        for dir in "$CAMPAIGNS_DIR"/*; do
            if [[ -d "$dir" ]]; then
                local campaign_name=$(basename "$dir")
                if [[ -f "$dir/index.php" || -f "$dir/index.html" ]]; then
                    campaigns+=("$campaign_name")
                fi
            fi
        done
    fi
    
    echo "${campaigns[*]}"
}

# Backup configuration
backup_config() {
    local backup_file="$BACKUP_DIR/campaignmanagerv12.conf.$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    if [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "$backup_file"
        log_success "Configuration backed up to: $backup_file"
        echo "$backup_file"
        return 0
    else
        log_error "Configuration file not found: $CONFIG_FILE"
        return 1
    fi
}

# Generate campaign configuration block
generate_campaign_config() {
    local campaign_name="$1"
    local campaign_dir="$CAMPAIGNS_DIR/$campaign_name"
    
    cat << EOF
    # $campaign_name static website
    location ^~ /$campaign_name/ {
        alias $campaign_dir/;
        index index.php index.html index.htm;
        try_files \$uri \$uri/ =404;
        
        # Handle PHP files
        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
            fastcgi_param SCRIPT_FILENAME \$request_filename;
            include fastcgi_params;
        }
    }
    
    # $campaign_name static assets
    location ~ ^/$campaign_name/(assets|css|js|images|img|fonts)/(.*)$ {
        alias $campaign_dir/;
        expires 30d;
        add_header Cache-Control "public, no-transform";
        try_files /\$1/\$2 =404;
        access_log off;
    }

EOF
}

# Generate nginx configuration
generate_config() {
    local campaigns=($(get_campaigns))
    
    if [[ ${#campaigns[@]} -eq 0 ]]; then
        log_warning "No campaigns found to configure"
        return 0
    fi
    
    log_info "Generating nginx configuration for: ${campaigns[*]}"
    
    if [[ "$SEPARATE" == true ]]; then
        # Generate separate config files
        for campaign in "${campaigns[@]}"; do
            local separate_config="$NGINX_DIR/${campaign}_static.conf"
            generate_campaign_config "$campaign" > "$separate_config"
            log_success "Generated separate config: $separate_config"
        done
        
        # Update main config to include separate files
        local temp_config="/tmp/campaignmanagerv12_temp.conf"
        
        # Find where to insert includes
        awk '
        /# Include.*static website configuration/ { next }
        /include.*static.*conf;/ { next }
        /# Main app front controller/ {
            print "    # Include campaign static configurations"
            for (i in campaigns) {
                print "    include " nginx_dir "/" campaigns[i] "_static.conf;"
            }
            print ""
        }
        { print }
        ' campaigns="${campaigns[*]}" nginx_dir="$NGINX_DIR" "$CONFIG_FILE" > "$temp_config"
        
        if [[ "$FORCE" == true ]] || [[ ! -s "$temp_config" ]]; then
            cp "$temp_config" "$CONFIG_FILE"
            rm -f "$temp_config"
            log_success "Updated main configuration with includes"
        fi
        
    else
        # Generate inline configuration
        local temp_config="/tmp/campaignmanagerv12_temp.conf"
        local marker_found=false
        
        # Create new config with campaign blocks
        {
            # Copy everything before campaign configurations
            awk '/# Include.*static website configuration|# .*campaign - static|# Main app front controller/ { exit } { print }' "$CONFIG_FILE"
            
            # Add new campaign configurations
            for campaign in "${campaigns[@]}"; do
                generate_campaign_config "$campaign"
            done
            
            # Add the rest from main front controller onwards
            awk '/# Main app front controller/,EOF' "$CONFIG_FILE"
            
        } > "$temp_config"
        
        if [[ -s "$temp_config" ]]; then
            cp "$temp_config" "$CONFIG_FILE"
            rm -f "$temp_config"
            log_success "Updated configuration with inline campaign blocks"
        else
            log_error "Failed to generate configuration"
            rm -f "$temp_config"
            return 1
        fi
    fi
}

# Test nginx configuration
test_config() {
    log_info "Testing nginx configuration..."
    
    if sudo nginx -t 2>/dev/null; then
        log_success "Nginx configuration test passed!"
        return 0
    else
        log_error "Nginx configuration test failed!"
        echo ""
        echo "Configuration errors:"
        sudo nginx -t
        return 1
    fi
}

# Reload nginx
reload_nginx() {
    log_info "Reloading nginx..."
    
    if test_config; then
        if sudo systemctl reload nginx; then
            log_success "Nginx reloaded successfully!"
            
            # Show campaign URLs
            local campaigns=($(get_campaigns))
            if [[ ${#campaigns[@]} -gt 0 ]]; then
                echo ""
                log_info "Campaigns should now be accessible:"
                for campaign in "${campaigns[@]}"; do
                    echo "   ${CHECK} https://devpayload.southeastasia.cloudapp.azure.com/$campaign/"
                done
            fi
            return 0
        else
            log_error "Failed to reload nginx"
            return 1
        fi
    else
        log_error "Configuration test failed. Not reloading."
        return 1
    fi
}

# Restore from backup
restore_config() {
    if [[ -n "$BACKUP_FILE" ]]; then
        if [[ -f "$BACKUP_FILE" ]]; then
            cp "$BACKUP_FILE" "$CONFIG_FILE"
            log_success "Configuration restored from: $BACKUP_FILE"
        else
            log_error "Backup file not found: $BACKUP_FILE"
            return 1
        fi
    else
        # Find latest backup
        local latest_backup=$(ls -t "$BACKUP_DIR"/*.conf.* 2>/dev/null | head -1)
        if [[ -n "$latest_backup" ]]; then
            cp "$latest_backup" "$CONFIG_FILE"
            log_success "Configuration restored from latest backup: $latest_backup"
        else
            log_error "No backup files found in $BACKUP_DIR"
            return 1
        fi
    fi
    
    # Test restored configuration
    test_config
}

# Clean campaign configurations
clean_config() {
    log_warning "Removing campaign configurations..."
    
    if [[ "$FORCE" != true ]]; then
        read -p "Are you sure you want to remove all campaign configurations? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Operation cancelled"
            return 0
        fi
    fi
    
    # Backup before cleaning
    backup_config
    
    # Remove separate config files
    rm -f "$NGINX_DIR"/*_static.conf
    
    # Remove inline configurations
    local temp_config="/tmp/campaignmanagerv12_clean.conf"
    awk '
    /# .*campaign - static/ { skip = 1; next }
    /# Include.*static website configuration/ { skip = 1; next }
    /include.*static.*conf;/ { next }
    /# Main app front controller/ { skip = 0 }
    !skip { print }
    ' "$CONFIG_FILE" > "$temp_config"
    
    cp "$temp_config" "$CONFIG_FILE"
    rm -f "$temp_config"
    
    log_success "Campaign configurations removed"
    
    # Test and reload
    if test_config; then
        reload_nginx
    fi
}

# Main execution
case $COMMAND in
    generate)
        backup_config
        generate_config
        ;;
    test)
        test_config
        ;;
    reload)
        reload_nginx
        ;;
    backup)
        backup_config
        ;;
    restore)
        restore_config
        ;;
    clean)
        clean_config
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        usage
        exit 1
        ;;
esac