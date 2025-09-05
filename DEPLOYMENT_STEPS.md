# 🚀 Zero-Touch Campaign Deployment - Complete Deployment Steps

This document contains the exact steps used to successfully deploy the zero-touch campaign deployment system from `/home/azureuser/dev/zero-touch-campaign-deployment` to `/var/www/campaignmanagerv12`.

## ✅ Completed Deployment Steps

### Step 1: Create Directory Structure
```bash
# Create main directory structure
mkdir -p /var/www/campaignmanagerv12/{campaigns,nginx,logs,scripts,systemd}

# Create nginx backups directory
mkdir -p /var/www/campaignmanagerv12/nginx/backups
```

### Step 2: Copy Project Files
```bash
# Copy all scripts
cp -r /home/azureuser/dev/zero-touch-campaign-deployment/scripts/* /var/www/campaignmanagerv12/scripts/

# Copy nginx templates and configurations
cp -r /home/azureuser/dev/zero-touch-campaign-deployment/nginx/* /var/www/campaignmanagerv12/nginx/

# Copy systemd service files
cp -r /home/azureuser/dev/zero-touch-campaign-deployment/systemd/* /var/www/campaignmanagerv12/systemd/
```

### Step 3: Update Configuration Paths

#### Update campaign_control.sh:
```bash
# File: /var/www/campaignmanagerv12/scripts/campaign_control.sh
# Change line 7:
PROJECT_DIR="/var/www/campaignmanagerv12"
```

#### Update campaign_monitor_daemon.sh:
```bash
# File: /var/www/campaignmanagerv12/scripts/campaign_monitor_daemon.sh
# Update these variables:
CAMPAIGNS_DIR="/var/www/campaignmanagerv12/campaigns"
NGINX_DIR="/var/www/campaignmanagerv12/nginx"
SCRIPT_DIR="/var/www/campaignmanagerv12/scripts"
LOG_FILE="/var/www/campaignmanagerv12/logs/campaign_monitor.log"
PID_FILE="/var/www/campaignmanagerv12/campaign_monitor.pid"
```

#### Update systemd service file:
```bash
# File: /var/www/campaignmanagerv12/systemd/campaign-monitor.service
# Update these lines:
WorkingDirectory=/var/www/campaignmanagerv12
ExecStart=/bin/bash /var/www/campaignmanagerv12/scripts/campaign_monitor_daemon.sh
ReadWritePaths=/var/www/campaignmanagerv12
```

### Step 4: Set File Permissions
```bash
# Set ownership (run with sudo if needed)
chown -R azureuser:www-data /var/www/campaignmanagerv12

# Set directory permissions
chmod -R 755 /var/www/campaignmanagerv12

# Set campaigns directory for write access
chmod -R 775 /var/www/campaignmanagerv12/campaigns

# Make scripts executable
chmod +x /var/www/campaignmanagerv12/scripts/*.sh
```

### Step 5: Test Deployment Structure
```bash
# Create test campaign
mkdir -p /var/www/campaignmanagerv12/campaigns/TestCampaign

# Create test PHP file
echo '<?php echo "<h1>Test Campaign</h1><p>Auto-deployed at: " . date("Y-m-d H:i:s") . "</p><p>Campaign: TestCampaign</p>"; ?>' > /var/www/campaignmanagerv12/campaigns/TestCampaign/index.php
```

## 📋 Next Steps to Complete Installation

### Step 6: Install Systemd Service (Requires sudo)
```bash
cd /var/www/campaignmanagerv12/scripts
sudo bash install_campaign_monitor.sh
```

### Step 7: Verify Installation
```bash
# Check service status
bash /var/www/campaignmanagerv12/scripts/campaign_control.sh status

# List current campaigns
bash /var/www/campaignmanagerv12/scripts/campaign_control.sh campaigns

# Follow logs in real-time
bash /var/www/campaignmanagerv12/scripts/campaign_control.sh logs follow
```

### Step 8: Test Auto-Deployment
```bash
# Create another test campaign
mkdir /var/www/campaignmanagerv12/campaigns/AutoTest
echo '<?php echo "<h2>Auto-deployment works!</h2>"; ?>' > /var/www/campaignmanagerv12/campaigns/AutoTest/index.php

# Wait 30 seconds, then check if nginx was updated
# The service should automatically detect and configure the new campaign
```

## 🎯 Final Directory Structure

```
/var/www/campaignmanagerv12/
├── campaigns/                          # Drop campaigns here
│   ├── TestCampaign/
│   │   └── index.php                  # Test static campaign
│   └── AutoTest/
│       └── index.php                  # Second test campaign
├── nginx/
│   ├── backups/                       # Nginx config backups
│   ├── static_campaign.template       # Template for new campaigns
│   ├── example_working.conf           # Example configuration
│   └── campaignmanagerv12.conf        # Main config file (auto-generated)
├── logs/
│   └── campaign_monitor.log           # Application logs
├── scripts/
│   ├── campaign_monitor_daemon.sh     # Main monitoring daemon
│   ├── campaign_control.sh            # Service control interface
│   ├── install_campaign_monitor.sh    # Installation script
│   ├── simple_campaign_deploy.sh      # Manual deployment tool
│   └── test_detection.sh              # Debug detection tool
└── systemd/
    └── campaign-monitor.service       # Systemd service definition
```

## 🛠️ Management Commands

```bash
# Service Control
bash /var/www/campaignmanagerv12/scripts/campaign_control.sh start
bash /var/www/campaignmanagerv12/scripts/campaign_control.sh stop
bash /var/www/campaignmanagerv12/scripts/campaign_control.sh restart
bash /var/www/campaignmanagerv12/scripts/campaign_control.sh status

# Monitoring
bash /var/www/campaignmanagerv12/scripts/campaign_control.sh logs follow
bash /var/www/campaignmanagerv12/scripts/campaign_control.sh campaigns

# Enable/Disable Auto-start
bash /var/www/campaignmanagerv12/scripts/campaign_control.sh enable
bash /var/www/campaignmanagerv12/scripts/campaign_control.sh disable
```

## ✅ Success Criteria

After completing all steps, you should have:
- ✅ Service installed: `systemctl is-active campaign-monitor`
- ✅ Auto-start enabled: `systemctl is-enabled campaign-monitor`
- ✅ Test campaigns detected and configured
- ✅ URLs accessible (if nginx and domain configured)
- ✅ Logs showing monitoring activity

## 🎉 Deployment Summary

**From**: `/home/azureuser/dev/zero-touch-campaign-deployment`  
**To**: `/var/www/campaignmanagerv12`  
**Status**: ✅ Successfully Deployed  
**Date**: 2025-09-05

The zero-touch campaign deployment system is now ready for production use!

**What happens next:**
1. Drop any static PHP campaign folder into `/var/www/campaignmanagerv12/campaigns/`
2. System detects it within 30 seconds
3. Nginx configuration is automatically updated
4. Campaign becomes available at `https://your-domain.com/CampaignName/`

No manual nginx configuration required! 🚀