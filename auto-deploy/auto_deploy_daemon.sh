#!/bin/bash

# Auto Deploy Daemon - Monitors campaigns folder and auto-deploys new campaigns
# Runs in background and automatically generates URLs

set -e

# Configuration
CAMPAIGNS_DIR="/var/www/campaignmanagerv12/campaigns"
NGINX_DIR="/var/www/campaignmanagerv12/nginx"
SETUP_DIR="/var/www/campaignmanagerv12/scripts/setup"
AUTO_DEPLOY_DIR="/var/www/campaignmanagerv12/scripts/auto-deploy"
LOG_FILE="/var/log/campaign-auto-deploy.log"
PID_FILE="/var/run/campaign-auto-deploy.pid"
CHECK_INTERVAL=10  # seconds

# Server domain (auto-detect or set manually)
SERVER_DOMAIN="${SERVER_DOMAIN:-$(hostname -f)}"
if [[ "$SERVER_DOMAIN" == "localhost" ]] || [[ "$SERVER_DOMAIN" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    SERVER_DOMAIN="devpayload.southeastasia.cloudapp.azure.com"
fi

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Icons
CHECK="✅"
ERROR="❌"
INFO="ℹ️"
ROCKET="🚀"

# Logging function
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")  echo -e "${INFO} ${BLUE}[$timestamp]${NC} $message" | tee -a "$LOG_FILE" ;;
        "SUCCESS") echo -e "${CHECK} ${GREEN}[$timestamp]${NC} $message" | tee -a "$LOG_FILE" ;;
        "ERROR") echo -e "${ERROR} ${RED}[$timestamp]${NC} $message" | tee -a "$LOG_FILE" ;;
        "WARN")  echo -e "${YELLOW}[$timestamp]${NC} $message" | tee -a "$LOG_FILE" ;;
        *) echo "[$timestamp] $message" | tee -a "$LOG_FILE" ;;
    esac
}

# Check if campaign is already deployed
is_campaign_deployed() {
    local campaign_name=$1
    local static_config="$NGINX_DIR/static_${campaign_name}.conf"
    local laravel_config="$NGINX_DIR/laravel_${campaign_name}.conf"
    
    [[ -f "$static_config" ]] || [[ -f "$laravel_config" ]]
}

# Detect campaign type
detect_campaign_type() {
    local campaign_dir=$1
    
    if [[ -f "$campaign_dir/composer.json" ]] && [[ -f "$campaign_dir/artisan" ]] && [[ -d "$campaign_dir/public" ]]; then
        echo "laravel"
    elif [[ -f "$campaign_dir/index.php" ]] || [[ -f "$campaign_dir/index.html" ]]; then
        echo "static"
    else
        echo "unknown"
    fi
}

# Setup Laravel campaign
setup_laravel_campaign() {
    local campaign_name=$1
    local campaign_dir="$CAMPAIGNS_DIR/$campaign_name"
    
    log_message "INFO" "Setting up Laravel campaign: $campaign_name"
    
    cd "$campaign_dir"
    
    # Install composer dependencies
    if [[ -f "composer.json" ]] && [[ ! -d "vendor" ]]; then
        log_message "INFO" "Installing Composer dependencies for $campaign_name"
        if composer install --no-dev --optimize-autoloader --quiet; then
            log_message "SUCCESS" "Composer dependencies installed for $campaign_name"
        else
            log_message "ERROR" "Failed to install Composer dependencies for $campaign_name"
            return 1
        fi
    fi
    
    # Setup environment file
    if [[ -f ".env.example" ]] && [[ ! -f ".env" ]]; then
        log_message "INFO" "Creating .env file for $campaign_name"
        cp .env.example .env
        
        # Generate application key
        if php artisan key:generate --quiet; then
            log_message "SUCCESS" "Application key generated for $campaign_name"
        else
            log_message "ERROR" "Failed to generate application key for $campaign_name"
            return 1
        fi
    fi
    
    # Set Laravel-specific permissions
    if [[ -d "storage" ]]; then
        chmod -R 775 storage
        log_message "INFO" "Set storage permissions for $campaign_name"
    fi
    
    if [[ -d "bootstrap/cache" ]]; then
        chmod -R 775 bootstrap/cache
        log_message "INFO" "Set cache permissions for $campaign_name"
    fi
    
    return 0
}

# Deploy campaign
deploy_campaign() {
    local campaign_name=$1
    local campaign_dir="$CAMPAIGNS_DIR/$campaign_name"
    local campaign_type=$(detect_campaign_type "$campaign_dir")
    
    log_message "INFO" "${ROCKET} Auto-deploying $campaign_type campaign: $campaign_name"
    
    # Change to setup directory
    cd "$SETUP_DIR"
    
    # Set permissions first
    log_message "INFO" "Setting permissions for $campaign_name"
    if ./campaign_manager.sh permissions --campaign "$campaign_name" --force 2>/dev/null; then
        log_message "SUCCESS" "Permissions set for $campaign_name"
    else
        log_message "WARN" "Permission setting had issues for $campaign_name (continuing anyway)"
    fi
    
    # Setup Laravel if needed
    if [[ "$campaign_type" == "laravel" ]]; then
        if ! setup_laravel_campaign "$campaign_name"; then
            log_message "ERROR" "Laravel setup failed for $campaign_name"
            return 1
        fi
    fi
    
    # Generate nginx configuration
    log_message "INFO" "Generating nginx configuration for $campaign_name"
    if ./campaign_manager.sh configure --separate-config --campaign "$campaign_name" 2>/dev/null; then
        log_message "SUCCESS" "Nginx configuration generated for $campaign_name"
    else
        log_message "ERROR" "Failed to generate nginx configuration for $campaign_name"
        return 1
    fi
    
    # Test nginx configuration
    log_message "INFO" "Testing nginx configuration"
    if ./campaign_config.sh test 2>/dev/null; then
        log_message "SUCCESS" "Nginx configuration test passed"
    else
        log_message "ERROR" "Nginx configuration test failed"
        return 1
    fi
    
    # Reload nginx
    log_message "INFO" "Reloading nginx"
    if ./campaign_config.sh reload 2>/dev/null; then
        log_message "SUCCESS" "Nginx reloaded successfully"
    else
        log_message "ERROR" "Failed to reload nginx"
        return 1
    fi
    
    # Generate URLs
    local urls=()
    if [[ "$campaign_type" == "laravel" ]]; then
        urls=(
            "https://$SERVER_DOMAIN/$campaign_name/"
            "https://$SERVER_DOMAIN/$campaign_name/signup"
            "https://$SERVER_DOMAIN/$campaign_name/signin"
        )
    else
        urls=(
            "https://$SERVER_DOMAIN/$campaign_name/"
            "https://$SERVER_DOMAIN/$campaign_name/index.php"
        )
    fi
    
    log_message "SUCCESS" "${ROCKET} Campaign $campaign_name deployed successfully!"
    log_message "SUCCESS" "Campaign Type: $campaign_type"
    log_message "SUCCESS" "Available URLs:"
    for url in "${urls[@]}"; do
        log_message "SUCCESS" "  ${CHECK} $url"
    done
    
    return 0
}

# Monitor campaigns directory
monitor_campaigns() {
    log_message "INFO" "${ROCKET} Starting Campaign Auto-Deploy Daemon"
    log_message "INFO" "Monitoring: $CAMPAIGNS_DIR"
    log_message "INFO" "Server Domain: $SERVER_DOMAIN"
    log_message "INFO" "Check Interval: ${CHECK_INTERVAL}s"
    
    while true; do
        if [[ -d "$CAMPAIGNS_DIR" ]]; then
            for campaign_path in "$CAMPAIGNS_DIR"/*; do
                if [[ -d "$campaign_path" ]]; then
                    local campaign_name=$(basename "$campaign_path")
                    
                    # Skip hidden directories and git directories
                    [[ "$campaign_name" =~ ^\. ]] && continue
                    
                    # Check if already deployed
                    if ! is_campaign_deployed "$campaign_name"; then
                        local campaign_type=$(detect_campaign_type "$campaign_path")
                        
                        if [[ "$campaign_type" != "unknown" ]]; then
                            log_message "INFO" "New $campaign_type campaign detected: $campaign_name"
                            
                            # Deploy in background
                            if deploy_campaign "$campaign_name"; then
                                log_message "SUCCESS" "Auto-deployment completed: $campaign_name"
                            else
                                log_message "ERROR" "Auto-deployment failed: $campaign_name"
                            fi
                        else
                            log_message "WARN" "Unknown campaign type for: $campaign_name (skipping)"
                        fi
                    fi
                fi
            done
        else
            log_message "ERROR" "Campaigns directory not found: $CAMPAIGNS_DIR"
        fi
        
        sleep "$CHECK_INTERVAL"
    done
}

# Daemon control functions
start_daemon() {
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        log_message "WARN" "Auto-deploy daemon is already running (PID: $(cat "$PID_FILE"))"
        return 1
    fi
    
    log_message "INFO" "Starting auto-deploy daemon..."
    
    # Create log file if it doesn't exist
    sudo touch "$LOG_FILE"
    sudo chown www-data:www-data "$LOG_FILE"
    
    # Start daemon in background
    nohup "$0" --monitor > /dev/null 2>&1 &
    local daemon_pid=$!
    
    echo "$daemon_pid" | sudo tee "$PID_FILE" > /dev/null
    log_message "SUCCESS" "Auto-deploy daemon started (PID: $daemon_pid)"
    
    return 0
}

stop_daemon() {
    if [[ ! -f "$PID_FILE" ]]; then
        log_message "WARN" "Auto-deploy daemon is not running"
        return 1
    fi
    
    local pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
        log_message "INFO" "Stopping auto-deploy daemon (PID: $pid)..."
        kill "$pid"
        sudo rm -f "$PID_FILE"
        log_message "SUCCESS" "Auto-deploy daemon stopped"
    else
        log_message "WARN" "Daemon not running, cleaning up PID file"
        sudo rm -f "$PID_FILE"
    fi
    
    return 0
}

status_daemon() {
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        local pid=$(cat "$PID_FILE")
        log_message "SUCCESS" "Auto-deploy daemon is running (PID: $pid)"
        log_message "INFO" "Monitoring: $CAMPAIGNS_DIR"
        log_message "INFO" "Log file: $LOG_FILE"
        return 0
    else
        log_message "WARN" "Auto-deploy daemon is not running"
        return 1
    fi
}

# Show usage
usage() {
    echo "Campaign Auto-Deploy Daemon"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start     Start the auto-deploy daemon"
    echo "  stop      Stop the auto-deploy daemon" 
    echo "  restart   Restart the auto-deploy daemon"
    echo "  status    Show daemon status"
    echo "  logs      Show recent logs"
    echo "  --monitor Internal monitoring mode (do not call directly)"
    echo ""
    echo "The daemon monitors $CAMPAIGNS_DIR for new campaigns and automatically:"
    echo "  • Detects static or Laravel campaigns"
    echo "  • Sets proper permissions (775/664)"
    echo "  • Installs Laravel dependencies if needed"
    echo "  • Generates nginx configuration"
    echo "  • Reloads nginx"
    echo "  • Provides accessible URLs"
}

# Main execution
case "${1:-}" in
    start)
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    restart)
        stop_daemon
        sleep 2
        start_daemon
        ;;
    status)
        status_daemon
        ;;
    logs)
        if [[ -f "$LOG_FILE" ]]; then
            tail -f "$LOG_FILE"
        else
            echo "Log file not found: $LOG_FILE"
        fi
        ;;
    --monitor)
        monitor_campaigns
        ;;
    *)
        usage
        exit 0
        ;;
esac