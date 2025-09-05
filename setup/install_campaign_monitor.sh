#!/bin/bash

# Campaign Monitor Installation Script
# Sets up automatic campaign detection and deployment service

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SERVICE_FILE="$PROJECT_DIR/systemd/campaign-monitor.service"

echo "🚀 Installing Campaign Monitor Service"
echo "======================================"

# Check if running as root or with sudo access
if [[ $EUID -eq 0 ]]; then
    SUDO=""
elif sudo -n true 2>/dev/null; then
    SUDO="sudo"
else
    echo "❌ This script requires sudo access to install systemd service"
    echo "💡 Run with: sudo bash install_campaign_monitor.sh"
    exit 1
fi

# Step 1: Create necessary directories
echo "📁 Creating directories..."
mkdir -p "$PROJECT_DIR/logs"
mkdir -p "$PROJECT_DIR/nginx/backups"

# Step 2: Make scripts executable
echo "🔧 Setting script permissions..."
chmod +x "$PROJECT_DIR/scripts"/*.sh

# Step 3: Install systemd service
echo "⚙️ Installing systemd service..."
$SUDO cp "$SERVICE_FILE" /etc/systemd/system/
$SUDO systemctl daemon-reload

# Step 4: Enable and start service
echo "🎯 Enabling and starting service..."
$SUDO systemctl enable campaign-monitor.service
$SUDO systemctl start campaign-monitor.service

# Step 5: Check service status
echo ""
echo "📊 Service Status:"
$SUDO systemctl status campaign-monitor.service --no-pager -l

# Step 6: Show service info
echo ""
echo "✅ Campaign Monitor Service Installed!"
echo ""
echo "📋 Service Commands:"
echo "   Start:   sudo systemctl start campaign-monitor"
echo "   Stop:    sudo systemctl stop campaign-monitor"
echo "   Status:  sudo systemctl status campaign-monitor"
echo "   Logs:    sudo journalctl -u campaign-monitor -f"
echo ""
echo "📂 Log Files:"
echo "   Service: sudo journalctl -u campaign-monitor"
echo "   App:     tail -f $PROJECT_DIR/logs/campaign_monitor.log"
echo ""
echo "🎯 How it works:"
echo "   1. Service monitors: $PROJECT_DIR/campaigns/"
echo "   2. Detects new static campaigns (folders with index.php)"
echo "   3. Auto-updates nginx configuration"
echo "   4. Makes new URLs available instantly"
echo ""
echo "💡 Test it:"
echo "   1. Create: mkdir campaigns/MyNewCampaign"
echo "   2. Add:    echo '<?php echo \"Hello World\"; ?>' > campaigns/MyNewCampaign/index.php"
echo "   3. Wait:   30 seconds (automatic detection)"
echo "   4. Visit:  https://devpayload.southeastasia.cloudapp.azure.com/MyNewCampaign/"