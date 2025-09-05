# 📦 Installation Guide - Zero-Touch Campaign Deployment

## 🎯 Overview
This guide will help you install the zero-touch campaign deployment system on your server.

## 🛠️ Prerequisites

### System Requirements:
- ✅ **Linux server** (Ubuntu/Debian/CentOS)
- ✅ **Nginx** web server  
- ✅ **PHP-FPM** (PHP 7.4+ recommended)
- ✅ **systemd** (for background service)
- ✅ **sudo access** (for installation)

### Verify Prerequisites:
```bash
# Check nginx
nginx -v

# Check PHP-FPM
php-fpm -v
systemctl status php8.4-fpm  # or your PHP version

# Check systemd
systemctl --version
```

## 📁 Step 1: Prepare Directories

### Create Project Structure:
```bash
# Choose your installation path
export PROJECT_DIR="/home/azureuser/dev/campaignmanager"

# Create directories
mkdir -p $PROJECT_DIR/{campaigns,nginx,logs,scripts,systemd}
mkdir -p $PROJECT_DIR/nginx/backups
```

### Set Permissions:
```bash
# Set ownership (replace 'azureuser' with your user)
sudo chown -R azureuser:www-data $PROJECT_DIR
chmod -R 755 $PROJECT_DIR
chmod -R 775 $PROJECT_DIR/campaigns  # Campaigns need write access
```

## 📋 Step 2: Copy Files

### Copy System Files:
```bash
# Copy scripts
cp zero-touch-campaign-deployment/scripts/* $PROJECT_DIR/scripts/

# Copy nginx template
cp zero-touch-campaign-deployment/nginx/* $PROJECT_DIR/nginx/

# Copy systemd service
cp zero-touch-campaign-deployment/systemd/* $PROJECT_DIR/systemd/

# Make scripts executable
chmod +x $PROJECT_DIR/scripts/*.sh
```

## ⚙️ Step 3: Configure Scripts

### Update Paths in Scripts:
```bash
# Edit the daemon script to match your paths
nano $PROJECT_DIR/scripts/campaign_monitor_daemon.sh

# Update these variables:
CAMPAIGNS_DIR="$PROJECT_DIR/campaigns"
NGINX_DIR="$PROJECT_DIR/nginx"
CONFIG_FILE="$NGINX_DIR/your-site.conf"  # Your actual nginx config file
```

### Update Control Script:
```bash
# Edit control script
nano $PROJECT_DIR/scripts/campaign_control.sh

# Update this variable:
PROJECT_DIR="/path/to/your/project"
```

### Update Service File:
```bash
# Edit systemd service
nano $PROJECT_DIR/systemd/campaign-monitor.service

# Update paths in ExecStart line:
ExecStart=/bin/bash $PROJECT_DIR/scripts/campaign_monitor_daemon.sh
WorkingDirectory=$PROJECT_DIR
```

## 🔧 Step 4: Configure Nginx

### Update Nginx Config Template:
```bash
# Edit the template to match your setup
nano $PROJECT_DIR/nginx/static_campaign.template

# Update paths and PHP-FPM socket:
fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;  # Your PHP version
alias /path/to/your/campaigns/{{CAMPAIGN_NAME}}/;
```

### Prepare Main Nginx Config:
```bash
# Make sure your main nginx config has the insertion point
grep "# Handle Laravel campaign PHP execution" /etc/nginx/sites-available/your-site

# If not found, add this comment where you want campaigns to be inserted:
# Handle Laravel campaign PHP execution
```

## 🚀 Step 5: Install Service

### Run Installation Script:
```bash
cd $PROJECT_DIR/scripts
sudo bash install_campaign_monitor.sh
```

### Verify Installation:
```bash
# Check service status
sudo systemctl status campaign-monitor

# Check if enabled for auto-start
sudo systemctl is-enabled campaign-monitor

# Check logs
sudo journalctl -u campaign-monitor -f
```

## ✅ Step 6: Test the System

### Create Test Campaign:
```bash
# Create test campaign
mkdir $PROJECT_DIR/campaigns/TestCampaign

# Add test PHP file
cat > $PROJECT_DIR/campaigns/TestCampaign/index.php << 'EOF'
<?php
echo "<h1>Test Campaign</h1>";
echo "<p>Auto-deployed at: " . date('Y-m-d H:i:s') . "</p>";
echo "<p>Campaign: TestCampaign</p>";
?>
EOF
```

### Monitor Detection:
```bash
# Watch the system detect and configure the campaign
bash $PROJECT_DIR/scripts/campaign_control.sh logs follow

# Should see output like:
# [2025-09-05 15:30:15] 🔍 New static campaigns detected: TestCampaign
# [2025-09-05 15:30:16] ✅ Nginx reloaded successfully
# [2025-09-05 15:30:16] 🔗 New URL available: https://your-domain.com/TestCampaign/
```

### Test URL:
```bash
# Test the new campaign URL (replace with your domain)
curl https://your-domain.com/TestCampaign/

# Should return the test HTML
```

## 🎛️ Step 7: Management

### Service Control:
```bash
# Start/stop/restart
bash campaign_control.sh start
bash campaign_control.sh stop
bash campaign_control.sh restart

# Check status
bash campaign_control.sh status

# View current campaigns
bash campaign_control.sh campaigns
```

### Monitoring:
```bash
# Watch logs in real-time
bash campaign_control.sh logs follow

# View recent service logs
bash campaign_control.sh logs service

# View application logs
bash campaign_control.sh logs app
```

## 🔧 Step 8: Production Configuration

### Adjust Monitoring Interval:
```bash
# Edit daemon script for production
nano $PROJECT_DIR/scripts/campaign_monitor_daemon.sh

# Change check interval (in seconds):
CHECK_INTERVAL=30  # Default: 30 seconds
# For high-traffic: CHECK_INTERVAL=60  # 1 minute  
# For low-traffic:  CHECK_INTERVAL=300 # 5 minutes
```

### Configure Log Rotation:
```bash
# Create logrotate config
sudo nano /etc/logrotate.d/campaign-monitor

# Add content:
/path/to/your/project/logs/campaign_monitor.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}
```

### Set Up Monitoring Alerts:
```bash
# Monitor service status
# Add to cron: */5 * * * * systemctl is-active campaign-monitor >/dev/null || echo "Campaign monitor is down" | mail -s "Alert" admin@domain.com
```

## 🚨 Troubleshooting

### Service Won't Start:
```bash
# Check service logs
sudo journalctl -u campaign-monitor -n 50

# Check script permissions  
ls -la $PROJECT_DIR/scripts/campaign_monitor_daemon.sh

# Check paths in service file
sudo systemctl cat campaign-monitor
```

### Campaigns Not Detected:
```bash
# Run detection test
bash $PROJECT_DIR/scripts/test_detection.sh

# Check directory permissions
ls -la $PROJECT_DIR/campaigns/

# Check campaign structure
ls -la $PROJECT_DIR/campaigns/YourCampaign/
```

### Nginx Not Updating:
```bash
# Check nginx config syntax
sudo nginx -t

# Check if insertion point exists
grep "Handle Laravel campaign PHP execution" $PROJECT_DIR/nginx/your-config.conf

# Check permissions
ls -la $PROJECT_DIR/nginx/
```

## ✅ Success Criteria

After installation, you should have:
- ✅ Service running: `systemctl is-active campaign-monitor`
- ✅ Auto-start enabled: `systemctl is-enabled campaign-monitor`  
- ✅ Test campaign working: `curl https://your-domain.com/TestCampaign/`
- ✅ Logs showing activity: `journalctl -u campaign-monitor`

## 🎉 You're Ready!

Your zero-touch campaign deployment system is now installed and ready for production use!

**Next steps:**
1. Remove test campaign: `rm -rf $PROJECT_DIR/campaigns/TestCampaign`
2. Add your real campaigns to `$PROJECT_DIR/campaigns/`
3. Watch them get automatically deployed!

**For ongoing management, see:** `docs/PRODUCTION_GUIDE.md`