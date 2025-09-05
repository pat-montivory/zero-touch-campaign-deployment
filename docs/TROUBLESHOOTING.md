# 🚨 Troubleshooting Guide - Zero-Touch Campaign Deployment

## 🔍 Common Issues & Solutions

### 🚨 Service Issues

#### Problem: Service won't start
```bash
# Symptoms:
systemctl status campaign-monitor
# Shows: "Failed to start" or "inactive (dead)"

# Diagnosis:
sudo journalctl -u campaign-monitor -n 20

# Common causes & fixes:
```

**Fix 1: Script permissions**
```bash
ls -la scripts/campaign_monitor_daemon.sh
# Should show: -rwxr-xr-x

# Fix:
chmod +x scripts/campaign_monitor_daemon.sh
```

**Fix 2: Wrong paths in service file**
```bash
# Check service file paths
sudo systemctl cat campaign-monitor

# Update paths:
sudo nano /etc/systemd/system/campaign-monitor.service
sudo systemctl daemon-reload
sudo systemctl restart campaign-monitor
```

**Fix 3: Missing directories**
```bash
# Create missing directories
mkdir -p logs nginx/backups campaigns
chown -R azureuser:www-data campaigns/
```

#### Problem: Service starts but stops immediately
```bash
# Check for script errors
sudo journalctl -u campaign-monitor -f

# Common issues:
```

**Fix 1: Nginx config file not found**
```bash
# Error: "No such file or directory: /path/to/nginx/config.conf"
# Update config path in daemon script:
nano scripts/campaign_monitor_daemon.sh
# Set correct CONFIG_FILE path
```

**Fix 2: PHP-FPM socket wrong**
```bash
# Check your PHP-FPM socket location
sudo find /var/run -name "*php*fpm*.sock" 2>/dev/null

# Update template:
nano nginx/static_campaign.template
# Set correct fastcgi_pass socket path
```

### 🔍 Detection Issues

#### Problem: New campaigns not detected
```bash
# Test detection manually:
bash scripts/test_detection.sh

# Check campaign structure:
ls -la campaigns/YourCampaign/
```

**Fix 1: Wrong campaign structure**
```bash
# ❌ Wrong structure (will be ignored):
campaigns/MyCampaign/
├── public/           # This makes it look like Laravel
│   └── index.php
└── other-files/

# ✅ Correct structure (will be detected):
campaigns/MyCampaign/
├── index.php         # Must be in root
├── assets/
└── css/
```

**Fix 2: File permissions**
```bash
# Check permissions
ls -la campaigns/YourCampaign/index.php

# Fix permissions:
chmod 644 campaigns/YourCampaign/index.php
chown azureuser:www-data campaigns/YourCampaign/index.php
```

**Fix 3: Campaign name invalid**
```bash
# Invalid names (will be ignored):
campaigns/my-campaign-with-spaces/
campaigns/campaign@special/
campaigns/123-start-with-number/

# Valid names:
campaigns/MyCampaign/
campaigns/Summer2025/
campaigns/Promo_Special/
```

#### Problem: Service detects but doesn't configure nginx
```bash
# Check logs for nginx update errors
bash campaign_control.sh logs follow

# Look for these error patterns:
# "Configuration test failed"
# "Failed to reload nginx"
```

**Fix 1: Nginx syntax error**
```bash
# Test nginx config manually
sudo nginx -t

# If errors, check the template:
nano nginx/static_campaign.template

# Common issues:
# - Wrong fastcgi_pass socket path
# - Missing semicolons
# - Wrong alias paths
```

**Fix 2: Nginx config insertion point missing**
```bash
# Check if insertion point exists
grep "Handle Laravel campaign PHP execution" nginx/your-config.conf

# If not found, add this line where you want campaigns inserted:
# Handle Laravel campaign PHP execution
```

**Fix 3: Permissions to modify nginx config**
```bash
# Check if service can write to nginx config
ls -la nginx/your-config.conf

# Fix permissions:
chown azureuser:www-data nginx/your-config.conf
chmod 664 nginx/your-config.conf
```

### 🌐 URL/Access Issues

#### Problem: Campaign URL returns 404
```bash
# Test URL:
curl -I https://your-domain.com/YourCampaign/

# Check if nginx config was actually updated:
grep -A 10 "YourCampaign campaign - static PHP files" nginx/your-config.conf
```

**Fix 1: Nginx config not applied**
```bash
# Check if nginx was reloaded
sudo systemctl status nginx

# Manually reload:
sudo systemctl reload nginx

# Test nginx config:
sudo nginx -t
```

**Fix 2: Wrong document root in template**
```bash
# Check template paths
cat nginx/static_campaign.template

# Make sure alias path is correct:
alias /correct/path/to/campaigns/{{CAMPAIGN_NAME}}/;
```

#### Problem: Campaign URL downloads file instead of executing PHP
```bash
# Check nginx config for PHP handler
grep -A 5 "location ~ \.php$" nginx/your-config.conf

# Make sure FastCGI is configured correctly
```

**Fix 1: PHP-FPM not running**
```bash
# Check PHP-FPM status
sudo systemctl status php8.4-fpm  # or your PHP version

# Start if needed:
sudo systemctl start php8.4-fpm
```

**Fix 2: Wrong FastCGI configuration**
```bash
# Check template has correct FastCGI setup:
nano nginx/static_campaign.template

# Should include:
location ~ \.php$ {
    fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $request_filename;
}
```

### 📝 Logging Issues

#### Problem: No logs appearing
```bash
# Check log file permissions
ls -la logs/campaign_monitor.log

# Check log directory exists
ls -la logs/
```

**Fix 1: Create log directory**
```bash
mkdir -p logs
touch logs/campaign_monitor.log
chown azureuser:www-data logs/campaign_monitor.log
```

**Fix 2: Check systemd logs instead**
```bash
# Service logs are in systemd
sudo journalctl -u campaign-monitor -f

# If you need file logs, redirect in service:
sudo nano /etc/systemd/system/campaign-monitor.service
# Add:
StandardOutput=append:/path/to/logs/campaign_monitor.log
StandardError=append:/path/to/logs/campaign_monitor.log
```

### 🔧 Configuration Issues

#### Problem: Multiple instances running
```bash
# Check for multiple processes
ps aux | grep campaign_monitor_daemon

# Kill extra processes:
sudo pkill -f campaign_monitor_daemon
sudo systemctl restart campaign-monitor
```

#### Problem: Service using too much CPU/Memory
```bash
# Check resource usage
top -p $(pgrep -f campaign_monitor_daemon)

# If high CPU usage, increase check interval:
nano scripts/campaign_monitor_daemon.sh
# Change: CHECK_INTERVAL=60  # from 30 to 60 seconds
```

## 🛠️ Diagnostic Commands

### Full System Health Check:
```bash
#!/bin/bash
# health_check.sh

echo "=== Campaign Monitor Health Check ==="
echo ""

# Service status
echo "1. Service Status:"
systemctl is-active campaign-monitor && echo "   ✅ Active" || echo "   ❌ Inactive"
systemctl is-enabled campaign-monitor && echo "   ✅ Auto-start enabled" || echo "   ⚠️  Auto-start disabled"

# Process check
echo ""
echo "2. Process Status:"
if pgrep -f campaign_monitor_daemon >/dev/null; then
    echo "   ✅ Daemon running (PID: $(pgrep -f campaign_monitor_daemon))"
else
    echo "   ❌ Daemon not running"
fi

# Permissions check
echo ""
echo "3. Permissions:"
[[ -x scripts/campaign_monitor_daemon.sh ]] && echo "   ✅ Script executable" || echo "   ❌ Script not executable"
[[ -w logs/ ]] && echo "   ✅ Log directory writable" || echo "   ❌ Log directory not writable"
[[ -w campaigns/ ]] && echo "   ✅ Campaigns directory writable" || echo "   ❌ Campaigns not writable"

# Configuration check
echo ""
echo "4. Configuration:"
[[ -f nginx/static_campaign.template ]] && echo "   ✅ Template exists" || echo "   ❌ Template missing"
nginx -t &>/dev/null && echo "   ✅ Nginx config valid" || echo "   ❌ Nginx config invalid"

# Campaign detection test
echo ""
echo "5. Campaign Detection:"
STATIC_COUNT=$(find campaigns/ -name "index.php" -not -path "*/public/*" 2>/dev/null | wc -l)
echo "   📊 Static campaigns found: $STATIC_COUNT"

echo ""
echo "=== Health Check Complete ==="
```

### Debug Mode:
```bash
# Run daemon in debug mode (foreground)
bash scripts/campaign_monitor_daemon.sh

# This will show real-time output and help identify issues
```

### Reset Everything:
```bash
#!/bin/bash
# reset_system.sh

echo "🔄 Resetting Campaign Monitor System..."

# Stop service
sudo systemctl stop campaign-monitor

# Clean up
rm -f campaign_monitor.pid
rm -f logs/campaign_monitor.log

# Recreate log file
touch logs/campaign_monitor.log
chown azureuser:www-data logs/campaign_monitor.log

# Restart service
sudo systemctl restart campaign-monitor

echo "✅ System reset complete"
bash campaign_control.sh status
```

## 📞 Getting Help

### Before Requesting Support:
1. ✅ Run the health check script above
2. ✅ Check recent logs: `bash campaign_control.sh logs app`  
3. ✅ Check systemd logs: `sudo journalctl -u campaign-monitor -n 50`
4. ✅ Test campaign structure: `bash scripts/test_detection.sh`
5. ✅ Test nginx config: `sudo nginx -t`

### Information to Include:
- Operating system and version
- Nginx version and configuration
- PHP version and FPM status  
- Service logs and error messages
- Campaign folder structure
- Any recent changes made

### Quick Fixes Checklist:
- [ ] Service is running: `systemctl is-active campaign-monitor`
- [ ] Scripts are executable: `ls -la scripts/*.sh`
- [ ] Directories exist: `ls -la logs/ campaigns/ nginx/`
- [ ] Permissions correct: `ls -la campaigns/`
- [ ] Nginx config valid: `nginx -t`
- [ ] PHP-FPM running: `systemctl is-active php*-fpm`
- [ ] Campaign structure correct: Has `index.php` in root, not in `public/`

Most issues can be resolved by checking these basic requirements! 🚀