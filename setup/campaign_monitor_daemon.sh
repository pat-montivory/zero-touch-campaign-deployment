#!/bin/bash

# Campaign Monitor Daemon
# Runs in background, monitors campaigns folder, auto-updates nginx config

CAMPAIGNS_DIR="/var/www/campaignmanagerv12/campaigns"
NGINX_DIR="/var/www/campaignmanagerv12/nginx"
CONFIG_FILE="$NGINX_DIR/campaignmanagerv12.conf"
TEMPLATE_FILE="$NGINX_DIR/static_campaign.template"
SCRIPT_DIR="/var/www/campaignmanagerv12/scripts"
LOG_FILE="/var/www/campaignmanagerv12/logs/campaign_monitor.log"
PID_FILE="/var/run/campaign_monitor.pid"
CHECK_INTERVAL=30  # Check every 30 seconds

# Create necessary directories
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$NGINX_DIR/backups"

# Logging function
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to check if campaign is static
is_static_campaign() {
    local dir="$1"
    [[ -f "$dir/index.php" && ! -f "$dir/public/index.php" ]]
}

# Function to get existing static campaigns from nginx config
get_existing_campaigns() {
    grep -oP "# \K[A-Za-z0-9_-]+(?= campaign - static PHP files)" "$CONFIG_FILE" 2>/dev/null || true
}

# Function to detect current static campaigns
detect_current_campaigns() {
    local campaigns=()
    
    for dir in "$CAMPAIGNS_DIR"/*; do
        if [[ -d "$dir" ]]; then
            local campaign_name=$(basename "$dir")
            
            # Skip Laravel campaigns
            if [[ "$campaign_name" == "KnorrBackToSchool" ]]; then
                continue
            fi
            
            if is_static_campaign "$dir"; then
                campaigns+=("$campaign_name")
            fi
        fi
    done
    
    printf '%s\n' "${campaigns[@]}" | sort -u
}

# Function to generate nginx config for a campaign
generate_campaign_config() {
    local campaign_name="$1"
    sed "s/{{CAMPAIGN_NAME}}/$campaign_name/g" "$TEMPLATE_FILE"
}

# Function to update nginx configuration
update_nginx_config() {
    local new_campaigns=("$@")
    
    log_message "🔧 Updating nginx configuration for campaigns: ${new_campaigns[*]}"
    
    # Backup current config
    local backup_file="$NGINX_DIR/backups/campaignmanagerv12.conf.auto.$(date +%Y%m%d_%H%M%S)"
    cp "$CONFIG_FILE" "$backup_file"
    log_message "📁 Backed up config to: $backup_file"
    
    # Find insertion point (before "Handle Laravel campaign PHP execution")
    local temp_config="/tmp/campaignmanagerv12_temp_$$.conf"
    local insertion_line=$(grep -n "# Handle Laravel campaign PHP execution" "$CONFIG_FILE" | head -1 | cut -d: -f1)
    
    if [[ -z "$insertion_line" ]]; then
        log_message "❌ Could not find insertion point in nginx config"
        return 1
    fi
    
    # Create new config with added campaigns
    head -n $((insertion_line - 1)) "$CONFIG_FILE" > "$temp_config"
    
    # Add new campaign configurations
    for campaign in "${new_campaigns[@]}"; do
        echo "" >> "$temp_config"
        generate_campaign_config "$campaign" >> "$temp_config"
    done
    
    # Add rest of original config
    tail -n +$insertion_line "$CONFIG_FILE" >> "$temp_config"
    
    # Test the new configuration
    if nginx -t -c "$temp_config" &>/dev/null; then
        log_message "✅ Configuration test passed"
        
        # Apply new configuration
        cp "$temp_config" "$CONFIG_FILE"
        
        # Reload nginx
        if systemctl reload nginx &>/dev/null; then
            log_message "✅ Nginx reloaded successfully"
            
            # Log new URLs
            for campaign in "${new_campaigns[@]}"; do
                log_message "🔗 New URL available: https://devpayload.southeastasia.cloudapp.azure.com/$campaign/"
            done
            
            rm -f "$temp_config"
            return 0
        else
            log_message "❌ Failed to reload nginx, restoring backup"
            cp "$backup_file" "$CONFIG_FILE"
            systemctl reload nginx &>/dev/null
            rm -f "$temp_config"
            return 1
        fi
    else
        log_message "❌ Configuration test failed, not applying changes"
        rm -f "$temp_config"
        return 1
    fi
}

# Function to handle daemon shutdown
cleanup() {
    log_message "🛑 Campaign monitor daemon stopping..."
    rm -f "$PID_FILE"
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Store PID
echo $$ > "$PID_FILE"

# Main monitoring loop
log_message "🚀 Campaign monitor daemon started (PID: $$)"
log_message "📂 Monitoring directory: $CAMPAIGNS_DIR"
log_message "⏰ Check interval: ${CHECK_INTERVAL}s"

# Initial state
previous_campaigns=($(detect_current_campaigns))
log_message "📊 Initial campaigns: ${previous_campaigns[*]:-none}"

while true; do
    # Detect current campaigns
    current_campaigns=($(detect_current_campaigns))
    
    # Find new campaigns (in current but not in previous)
    new_campaigns=()
    for campaign in "${current_campaigns[@]}"; do
        if [[ ! " ${previous_campaigns[*]} " =~ " ${campaign} " ]]; then
            new_campaigns+=("$campaign")
        fi
    done
    
    # Find removed campaigns (in previous but not in current)
    removed_campaigns=()
    for campaign in "${previous_campaigns[@]}"; do
        if [[ ! " ${current_campaigns[*]} " =~ " ${campaign} " ]]; then
            removed_campaigns+=("$campaign")
        fi
    done
    
    # Process changes
    if [[ ${#new_campaigns[@]} -gt 0 ]]; then
        log_message "🔍 New static campaigns detected: ${new_campaigns[*]}"
        
        # Get existing campaigns from config
        existing_in_config=($(get_existing_campaigns))
        
        # Find campaigns that need to be added to config
        campaigns_to_add=()
        for campaign in "${new_campaigns[@]}"; do
            if [[ ! " ${existing_in_config[*]} " =~ " ${campaign} " ]]; then
                campaigns_to_add+=("$campaign")
            fi
        done
        
        if [[ ${#campaigns_to_add[@]} -gt 0 ]]; then
            log_message "➕ Adding to nginx config: ${campaigns_to_add[*]}"
            if update_nginx_config "${campaigns_to_add[@]}"; then
                log_message "✅ Successfully configured new campaigns"
            else
                log_message "❌ Failed to configure new campaigns"
            fi
        else
            log_message "ℹ️ New campaigns already configured in nginx"
        fi
    fi
    
    if [[ ${#removed_campaigns[@]} -gt 0 ]]; then
        log_message "🗑️ Campaigns removed: ${removed_campaigns[*]} (nginx config not auto-removed for safety)"
    fi
    
    # Update previous state
    previous_campaigns=("${current_campaigns[@]}")
    
    # Wait before next check
    sleep "$CHECK_INTERVAL"
done