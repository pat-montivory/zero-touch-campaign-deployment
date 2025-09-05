# 🚀 Zero-Touch Campaign Deployment System

**Automatically deploy static PHP campaigns with zero manual intervention!**

## 🎯 What This System Does

1. **Background service monitors** your campaigns folder 24/7
2. **User drops new campaign** into the campaigns folder
3. **System auto-detects** new static campaigns (within 30 seconds)
4. **Nginx automatically configured** and reloaded
5. **New URL is instantly available** - no manual setup required!

## ⚡ Quick Start

### 1. Install the System
```bash
# Copy this folder to your server
# Update paths in scripts to match your setup
cd scripts/
sudo bash install_campaign_monitor.sh
```

### 2. Test It Works
```bash
# Check service is running
bash campaign_control.sh status

# Create test campaign
mkdir campaigns/TestCampaign
echo '<?php echo "Hello World!"; ?>' > campaigns/TestCampaign/index.php

# Wait 30 seconds, then visit:
# https://your-domain.com/TestCampaign/
```

## 📁 Package Contents

```
zero-touch-campaign-deployment/
├── 📋 README.md                    ← This file
├── 📋 INSTALLATION.md              ← Detailed setup guide
├── 📋 API_REFERENCE.md             ← Technical documentation
├── scripts/
│   ├── 🤖 campaign_monitor_daemon.sh     ← Background monitoring service
│   ├── 🎛️ campaign_control.sh            ← Service management interface
│   ├── ⚙️ install_campaign_monitor.sh    ← One-click installation
│   ├── 🚀 simple_campaign_deploy.sh      ← Manual deployment tool
│   └── 🔍 test_detection.sh              ← Debug campaign detection
├── nginx/
│   ├── 📝 static_campaign.template       ← Nginx config template  
│   └── 📄 example_working.conf           ← Example working configuration
├── systemd/
│   └── ⚙️ campaign-monitor.service        ← Linux service definition
├── docs/
│   ├── 📚 TROUBLESHOOTING.md             ← Common issues & fixes
│   └── 🎯 PRODUCTION_GUIDE.md            ← Production deployment guide
└── examples/
    ├── 📂 sample-static-campaign/        ← Example static campaign
    └── 📂 sample-laravel-campaign/       ← Example Laravel campaign (ignored)
```

## 🎯 How It Works

### For Static Campaigns (Auto-deployed):
```
campaigns/MyCampaign/
├── index.php          ✅ Must have this
├── assets/
├── css/
└── images/
```
**Result**: `https://your-domain.com/MyCampaign/` (automatic!)

### For Laravel Campaigns (Manual setup):
```
campaigns/LaravelCampaign/
├── public/
│   └── index.php      ✅ Laravel indicator
├── app/
└── routes/
```
**Result**: Requires manual nginx configuration

## 🎛️ Management Commands

```bash
# Service control
bash campaign_control.sh start       # Start background monitoring
bash campaign_control.sh stop        # Stop monitoring
bash campaign_control.sh status      # Check service status
bash campaign_control.sh restart     # Restart service

# Monitoring
bash campaign_control.sh logs follow # Watch system work in real-time
bash campaign_control.sh campaigns   # List all current campaigns

# One-time deployment (without service)
bash simple_campaign_deploy.sh       # Detect and show config to add
```

## ✨ Key Features

- ✅ **Zero-touch deployment** - No manual nginx configuration
- ✅ **Real-time detection** - New campaigns detected within 30 seconds  
- ✅ **Automatic backups** - Nginx config backed up before changes
- ✅ **Safe rollback** - Auto-rollback if nginx reload fails
- ✅ **Smart detection** - Distinguishes static vs Laravel campaigns
- ✅ **Production ready** - Systemd service with logging
- ✅ **Easy management** - Simple control interface

## 🛡️ Safety Features

- **Configuration testing** before applying changes
- **Automatic rollback** if something goes wrong  
- **Detailed logging** of all actions
- **Non-destructive** - only adds, never removes campaigns
- **Backup system** - All changes are backed up

## 🚨 Requirements

- Linux server with nginx
- PHP-FPM running
- systemd (for background service)
- sudo access (for installation)

## 📞 Support

Check these files for help:
- `docs/TROUBLESHOOTING.md` - Common issues
- `docs/PRODUCTION_GUIDE.md` - Production setup
- `INSTALLATION.md` - Step-by-step setup

## 🎉 Success Story

**Before**: Manual nginx configuration for every new campaign  
**After**: Drop folder → Wait 30 seconds → URL is ready! 

**Example Production Workflow:**
1. Marketing team uploads `PromoSummer2025/` campaign
2. System detects it automatically  
3. Nginx configured and reloaded
4. `https://your-domain.com/PromoSummer2025/` is live
5. Marketing team notified via monitoring

**Zero developer intervention required!** 🚀