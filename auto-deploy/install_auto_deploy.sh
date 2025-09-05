#!/bin/bash

# Auto-Deploy Installation Script
# Sets up automatic campaign deployment system

set -e

# Configuration
SETUP_DIR="/var/www/campaignmanagerv12/scripts/setup"
AUTO_DEPLOY_DIR="/var/www/campaignmanagerv12/scripts/auto-deploy"
SERVICE_FILE="/etc/systemd/system/campaign-auto-deploy.service"
LOG_FILE="/var/log/campaign-auto-deploy.log"

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
ROCKET="🚀"

log_info() { echo -e "${INFO} ${BLUE}$1${NC}"; }
log_success() { echo -e "${CHECK} ${GREEN}$1${NC}"; }
log_error() { echo -e "${ERROR} ${RED}$1${NC}"; }
log_warn() { echo -e "${YELLOW}$1${NC}"; }

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if setup directory exists
    if [[ ! -d "$SETUP_DIR" ]]; then
        log_error "Setup directory not found: $SETUP_DIR"
        exit 1
    fi
    
    # Check required scripts in setup directory
    local setup_scripts=("campaign_manager.sh" "campaign_config.sh")
    for script in "${setup_scripts[@]}"; do
        if [[ ! -f "$SETUP_DIR/$script" ]]; then
            log_error "Required setup script not found: $script"
            exit 1
        fi
    done
    
    # Check auto-deploy script
    if [[ ! -f "$AUTO_DEPLOY_DIR/auto_deploy_daemon.sh" ]]; then
        log_error "Auto-deploy daemon script not found"
        exit 1
    fi
    
    # Check required commands
    local required_commands=("nginx" "php" "composer" "git")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "Required command not found: $cmd"
            log_info "Please install: $cmd"
            exit 1
        fi
    done
    
    log_success "Prerequisites check passed"
}

# Make scripts executable
setup_permissions() {
    log_info "Setting up script permissions..."
    
    chmod +x "$SETUP_DIR"/*.sh
    chmod +x "$AUTO_DEPLOY_DIR"/*.sh
    chown -R www-data:www-data /var/www/campaignmanagerv12/campaigns/
    
    # Create campaigns directory if it doesn't exist
    mkdir -p /var/www/campaignmanagerv12/campaigns
    chown www-data:www-data /var/www/campaignmanagerv12/campaigns
    
    # Create nginx directory if it doesn't exist
    mkdir -p /var/www/campaignmanagerv12/nginx
    chown www-data:www-data /var/www/campaignmanagerv12/nginx
    
    log_success "Permissions configured"
}

# Create systemd service
create_systemd_service() {
    log_info "Creating systemd service..."
    
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Campaign Auto-Deploy Daemon
After=network.target nginx.service php8.4-fpm.service

[Service]
Type=simple
User=www-data
Group=www-data
ExecStart=$AUTO_DEPLOY_DIR/auto_deploy_daemon.sh --monitor
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=10
StandardOutput=append:$LOG_FILE
StandardError=append:$LOG_FILE

# Environment
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=HOME=/var/www

[Install]
WantedBy=multi-user.target
EOF

    # Create log file with proper permissions
    touch "$LOG_FILE"
    chown www-data:www-data "$LOG_FILE"
    chmod 644 "$LOG_FILE"
    
    # Reload systemd and enable service
    systemctl daemon-reload
    systemctl enable campaign-auto-deploy.service
    
    log_success "Systemd service created and enabled"
}

# Install inotify tools for better file monitoring (optional)
install_monitoring_tools() {
    log_info "Installing monitoring tools..."
    
    if apt-get update >/dev/null 2>&1 && apt-get install -y inotify-tools >/dev/null 2>&1; then
        log_success "Monitoring tools installed"
    else
        log_warn "Could not install inotify-tools (will use polling instead)"
    fi
}

# Create example campaigns directory structure
create_example_structure() {
    log_info "Creating example directory structure..."
    
    # Create README in campaigns directory
    cat > /var/www/campaignmanagerv12/campaigns/README.md << 'EOF'
# Campaigns Directory

Place your campaign folders here for automatic deployment.

## Static Campaigns
Copy or clone static websites (with index.php or index.html) directly into this folder.

Example:
```bash
git clone https://github.com/montivory/VisoPisesLiquidShop.git
```

## Laravel Campaigns  
Copy or clone Laravel applications (with composer.json and artisan) directly into this folder.

Example:
```bash
git clone https://github.com/montivory/KnorrBackToSchool.git
```

## Automatic Deployment
The system automatically:
- Detects new campaigns (static or Laravel)
- Sets proper permissions (775/664)
- Installs Laravel dependencies if needed
- Generates nginx configuration
- Reloads nginx
- Provides accessible URLs

## Check Status
```bash
sudo systemctl status campaign-auto-deploy
sudo /var/www/campaignmanagerv12/scripts/setup/auto_deploy_daemon.sh status
```

## View Logs
```bash
sudo tail -f /var/log/campaign-auto-deploy.log
```
EOF

    chown www-data:www-data /var/www/campaignmanagerv12/campaigns/README.md
    
    log_success "Example structure created"
}

# Start the service
start_service() {
    log_info "Starting auto-deploy service..."
    
    if systemctl start campaign-auto-deploy.service; then
        log_success "Auto-deploy service started"
        
        # Wait a moment and check status
        sleep 2
        if systemctl is-active --quiet campaign-auto-deploy.service; then
            log_success "Service is running successfully"
        else
            log_error "Service failed to start properly"
            systemctl status campaign-auto-deploy.service
        fi
    else
        log_error "Failed to start auto-deploy service"
        exit 1
    fi
}

# Show final instructions
show_instructions() {
    log_success "${ROCKET} Auto-Deploy System Installed Successfully!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    log_success "HOW TO USE:"
    echo ""
    echo "1. Copy or clone campaigns into: /var/www/campaignmanagerv12/campaigns/"
    echo ""
    echo "   Static Campaign Example:"
    echo "   cd /var/www/campaignmanagerv12/campaigns"
    echo "   git clone https://github.com/montivory/VisoPisesLiquidShop.git"
    echo ""
    echo "   Laravel Campaign Example:"
    echo "   cd /var/www/campaignmanagerv12/campaigns" 
    echo "   git clone https://github.com/montivory/KnorrBackToSchool.git"
    echo ""
    echo "2. The system will automatically:"
    echo "   ${CHECK} Detect the campaign type (static or Laravel)"
    echo "   ${CHECK} Set proper permissions (775/664)"
    echo "   ${CHECK} Install Laravel dependencies if needed"
    echo "   ${CHECK} Generate nginx configuration"
    echo "   ${CHECK} Reload nginx"
    echo "   ${CHECK} Provide accessible URLs"
    echo ""
    log_success "MANAGEMENT COMMANDS:"
    echo ""
    echo "   # Check service status"
    echo "   sudo systemctl status campaign-auto-deploy"
    echo ""
    echo "   # View real-time logs"
    echo "   sudo tail -f /var/log/campaign-auto-deploy.log"
    echo ""
    echo "   # Manual daemon control"
    echo "   sudo $AUTO_DEPLOY_DIR/auto_deploy_daemon.sh status"
    echo "   sudo $AUTO_DEPLOY_DIR/auto_deploy_daemon.sh restart"
    echo ""
    log_success "URLs will be automatically generated as:"
    echo "   https://$(hostname -f)/CampaignName/"
    echo "   https://$(hostname -f)/CampaignName/signup (Laravel only)"
    echo "   https://$(hostname -f)/CampaignName/signin (Laravel only)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Main installation process
main() {
    echo ""
    log_info "${ROCKET} Installing Campaign Auto-Deploy System"
    echo ""
    
    check_prerequisites
    setup_permissions
    install_monitoring_tools
    create_systemd_service
    create_example_structure
    start_service
    show_instructions
}

# Handle command line arguments
case "${1:-install}" in
    install)
        main
        ;;
    uninstall)
        log_info "Uninstalling auto-deploy system..."
        systemctl stop campaign-auto-deploy.service 2>/dev/null || true
        systemctl disable campaign-auto-deploy.service 2>/dev/null || true
        rm -f "$SERVICE_FILE"
        systemctl daemon-reload
        log_success "Auto-deploy system uninstalled"
        ;;
    *)
        echo "Usage: $0 [install|uninstall]"
        echo ""
        echo "install   - Install and start auto-deploy system (default)"
        echo "uninstall - Remove auto-deploy system"
        exit 1
        ;;
esac