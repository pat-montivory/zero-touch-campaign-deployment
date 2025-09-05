#!/bin/bash

# Campaign Monitor Control Script
# Easy interface to manage the campaign monitoring service

SERVICE_NAME="campaign-monitor"
PROJECT_DIR="/home/azureuser/dev/campaignmanagerv12"
LOG_FILE="$PROJECT_DIR/logs/campaign_monitor.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_status() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Function to check if service exists
service_exists() {
    systemctl list-unit-files | grep -q "^${SERVICE_NAME}.service"
}

# Function to show service status
show_status() {
    if service_exists; then
        print_status "$BLUE" "📊 Campaign Monitor Service Status:"
        sudo systemctl status "$SERVICE_NAME" --no-pager
        
        echo ""
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            print_status "$GREEN" "✅ Service is running"
        else
            print_status "$RED" "❌ Service is not running"
        fi
        
        if systemctl is-enabled --quiet "$SERVICE_NAME"; then
            print_status "$GREEN" "✅ Service auto-start enabled"
        else
            print_status "$YELLOW" "⚠️ Service auto-start disabled"
        fi
    else
        print_status "$RED" "❌ Service not installed"
        echo "💡 Run: bash install_campaign_monitor.sh"
    fi
}

# Function to show logs
show_logs() {
    local log_type="$1"
    
    case "$log_type" in
        "service"|"systemd")
            print_status "$BLUE" "📋 Systemd Service Logs (last 50 lines):"
            sudo journalctl -u "$SERVICE_NAME" -n 50 --no-pager
            ;;
        "app"|"application")
            if [[ -f "$LOG_FILE" ]]; then
                print_status "$BLUE" "📋 Application Logs (last 50 lines):"
                tail -50 "$LOG_FILE"
            else
                print_status "$YELLOW" "⚠️ Application log file not found: $LOG_FILE"
            fi
            ;;
        "follow"|"tail")
            if [[ -f "$LOG_FILE" ]]; then
                print_status "$BLUE" "📋 Following Application Logs (Ctrl+C to stop):"
                tail -f "$LOG_FILE"
            else
                print_status "$YELLOW" "⚠️ Application log file not found: $LOG_FILE"
            fi
            ;;
        *)
            echo "📋 Available log options:"
            echo "   service  - Show systemd service logs"
            echo "   app      - Show application logs"
            echo "   follow   - Follow application logs in real-time"
            ;;
    esac
}

# Function to show current campaigns
show_campaigns() {
    print_status "$BLUE" "📂 Current Campaign Status:"
    
    if [[ -d "$PROJECT_DIR/campaigns" ]]; then
        echo ""
        echo "Static Campaigns:"
        for dir in "$PROJECT_DIR/campaigns"/*; do
            if [[ -d "$dir" ]]; then
                local campaign_name=$(basename "$dir")
                
                # Skip Laravel campaigns
                if [[ "$campaign_name" == "KnorrBackToSchool" ]]; then
                    continue
                fi
                
                # Check if it's a static campaign
                if [[ -f "$dir/index.php" && ! -f "$dir/public/index.php" ]]; then
                    local url="https://devpayload.southeastasia.cloudapp.azure.com/$campaign_name/"
                    echo "  ✅ $campaign_name → $url"
                fi
            fi
        done
        
        echo ""
        echo "Laravel Campaigns:"
        for dir in "$PROJECT_DIR/campaigns"/*; do
            if [[ -d "$dir" ]]; then
                local campaign_name=$(basename "$dir")
                
                # Check if it's a Laravel campaign
                if [[ -f "$dir/public/index.php" ]]; then
                    local url="https://devpayload.southeastasia.cloudapp.azure.com/$campaign_name/"
                    echo "  🌟 $campaign_name → $url (Laravel)"
                fi
            fi
        done
    else
        print_status "$YELLOW" "⚠️ Campaigns directory not found: $PROJECT_DIR/campaigns"
    fi
}

# Main script logic
case "$1" in
    "start")
        if service_exists; then
            print_status "$BLUE" "🚀 Starting Campaign Monitor..."
            sudo systemctl start "$SERVICE_NAME"
            show_status
        else
            print_status "$RED" "❌ Service not installed. Run: bash install_campaign_monitor.sh"
        fi
        ;;
    
    "stop")
        if service_exists; then
            print_status "$BLUE" "🛑 Stopping Campaign Monitor..."
            sudo systemctl stop "$SERVICE_NAME"
            show_status
        else
            print_status "$RED" "❌ Service not installed"
        fi
        ;;
    
    "restart")
        if service_exists; then
            print_status "$BLUE" "🔄 Restarting Campaign Monitor..."
            sudo systemctl restart "$SERVICE_NAME"
            show_status
        else
            print_status "$RED" "❌ Service not installed"
        fi
        ;;
    
    "status")
        show_status
        ;;
    
    "logs")
        show_logs "$2"
        ;;
    
    "campaigns")
        show_campaigns
        ;;
    
    "enable")
        if service_exists; then
            print_status "$BLUE" "⚙️ Enabling auto-start..."
            sudo systemctl enable "$SERVICE_NAME"
            print_status "$GREEN" "✅ Auto-start enabled"
        else
            print_status "$RED" "❌ Service not installed"
        fi
        ;;
    
    "disable")
        if service_exists; then
            print_status "$BLUE" "⚙️ Disabling auto-start..."
            sudo systemctl disable "$SERVICE_NAME"
            print_status "$YELLOW" "⚠️ Auto-start disabled"
        else
            print_status "$RED" "❌ Service not installed"
        fi
        ;;
    
    *)
        echo "🎯 Campaign Monitor Control Script"
        echo "================================="
        echo ""
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  start        Start the campaign monitor service"
        echo "  stop         Stop the campaign monitor service"  
        echo "  restart      Restart the campaign monitor service"
        echo "  status       Show service status"
        echo "  enable       Enable auto-start on boot"
        echo "  disable      Disable auto-start on boot"
        echo "  campaigns    Show current campaign status"
        echo "  logs         Show logs (service|app|follow)"
        echo ""
        echo "Examples:"
        echo "  $0 status"
        echo "  $0 logs follow"
        echo "  $0 campaigns"
        echo ""
        show_status
        ;;
esac