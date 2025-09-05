# 🎯 Production Guide - Zero-Touch Campaign Deployment

## 🚀 Production Workflow

### Daily Operations:
1. **Marketing team** uploads campaign folders
2. **System automatically detects** within 30 seconds  
3. **URLs instantly available** - no developer needed
4. **Monitoring alerts** if anything goes wrong

### Example Production Scenario:
```
15:30:00 - Marketing uploads "SummerSale2025/" campaign
15:30:15 - System detects new campaign  
15:30:16 - Nginx config updated automatically
15:30:17 - https://yoursite.com/SummerSale2025/ is LIVE
15:30:18 - Marketing team receives notification
```

## 📊 Monitoring & Alerts

### Real-time Monitoring:
```bash
# Dashboard view - check everything at once
bash campaign_control.sh status
bash campaign_control.sh campaigns  
bash campaign_control.sh logs follow

# Service health check
systemctl is-active campaign-monitor && echo "✅ Running" || echo "❌ Down"
```

### Set Up Alerts:
```bash
# Email alerts for service failures (add to cron)
*/5 * * * * systemctl is-active campaign-monitor >/dev/null || echo "Campaign monitor service is down on $(hostname)" | mail -s "ALERT: Campaign Monitor Down" admin@yoursite.com

# Disk space monitoring (campaigns folder)
0 9 * * * df -h /path/to/campaigns | awk 'NR==2 {if ($5+0 > 80) print "Campaigns disk usage: " $5}' | mail -s "Disk Space Alert" admin@yoursite.com
```

### Log Monitoring:
```bash
# Set up log rotation
sudo nano /etc/logrotate.d/campaign-monitor
# Content:
/path/to/project/logs/campaign_monitor.log {
    weekly
    rotate 8
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}

# Monitor for errors in logs
*/10 * * * * grep -i error /path/to/project/logs/campaign_monitor.log | tail -5 | mail -s "Campaign Monitor Errors" admin@yoursite.com
```

## ⚙️ Performance Optimization

### Tuning Detection Interval:
```bash
# Edit daemon script
nano scripts/campaign_monitor_daemon.sh

# Adjust based on your needs:
CHECK_INTERVAL=30   # Default: Every 30 seconds
CHECK_INTERVAL=60   # Conservative: Every 1 minute  
CHECK_INTERVAL=300  # Low-traffic: Every 5 minutes
```

### Nginx Optimization:
```bash
# Add to nginx.conf for better performance
worker_processes auto;
worker_connections 1024;

# Enable gzip for campaign assets
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_types text/css application/javascript image/svg+xml;

# Optimize campaign asset caching
location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    access_log off;
}
```

### Resource Monitoring:
```bash
# Monitor system resources
# CPU usage
top -p $(pgrep -f campaign_monitor_daemon)

# Memory usage  
ps -o pid,ppid,cmd,%mem,%cpu --sort=-%mem -p $(pgrep -f campaign_monitor_daemon)

# Disk I/O
iotop -p $(pgrep -f campaign_monitor_daemon)
```

## 🔒 Security Considerations

### File Permissions:
```bash
# Campaigns directory - writable by web server group
chown -R azureuser:www-data campaigns/
chmod -R 755 campaigns/
find campaigns/ -type f -name "*.php" -exec chmod 644 {} \;

# Scripts - executable by owner only
chmod 700 scripts/*.sh

# Config files - read-only
chmod 644 nginx/*.conf nginx/*.template
```

### Access Control:
```bash
# Restrict campaign uploads (example with SSH/SFTP)
# Create dedicated user for campaign uploads
sudo useradd -m -s /bin/bash -G www-data campaign-uploader

# Set up restricted directory access
sudo nano /etc/ssh/sshd_config
# Add:
Match User campaign-uploader
    ChrootDirectory /path/to/project
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
```

### Input Validation:
```bash
# The system validates campaign names using regex: [A-Za-z0-9_-]+
# This prevents directory traversal and special characters
# Campaigns with invalid names are automatically ignored
```

## 📈 Scaling Considerations

### Multi-Server Setup:
```bash
# For load-balanced environments:
# 1. Run monitoring service on one server only (master)
# 2. Sync campaign files to all servers
# 3. Update nginx configs on all servers

# Example sync script (run from master):
rsync -avz campaigns/ server2:/path/to/campaigns/
rsync -avz nginx/config.conf server2:/path/to/nginx/
ssh server2 'sudo systemctl reload nginx'
```

### High-Availability:
```bash
# Use shared storage for campaigns
mount -t nfs server:/shared/campaigns /path/to/campaigns

# Monitor multiple services
for server in web1 web2 web3; do
    ssh $server 'systemctl is-active campaign-monitor' || echo "$server monitor down"
done
```

### Database Logging:
```bash
# For enterprise logging, modify daemon to log to database
# Add to campaign_monitor_daemon.sh:
log_to_db() {
    mysql -u logger -p"$DB_PASS" -e "
        INSERT INTO campaign_log (timestamp, level, message, campaign) 
        VALUES (NOW(), '$1', '$2', '$3')
    " campaign_db
}
```

## 🔧 Maintenance Tasks

### Weekly Maintenance:
```bash
#!/bin/bash
# weekly_maintenance.sh

# Clean old backups (keep last 30)
find nginx/backups/ -name "*.backup.*" -mtime +30 -delete

# Rotate logs manually if needed
logrotate -f /etc/logrotate.d/campaign-monitor

# Check disk space
df -h /path/to/project | awk 'NR==2 {print "Disk usage: " $5}'

# Validate all campaign configs
for campaign in campaigns/*/; do
    if [[ -f "$campaign/index.php" ]]; then
        echo "Checking $(basename "$campaign")..."
        php -l "$campaign/index.php" || echo "⚠️  Syntax error in $campaign"
    fi
done
```

### Monthly Maintenance:
```bash
#!/bin/bash
# monthly_maintenance.sh

# Archive old campaigns (if needed)
find campaigns/ -maxdepth 1 -type d -mtime +90 -exec mv {} archived_campaigns/ \;

# Cleanup orphaned nginx configs
# Compare campaigns in filesystem vs nginx config
# Remove configs for non-existent campaigns

# Performance report
echo "=== Monthly Performance Report ===" 
echo "Total campaigns: $(find campaigns/ -maxdepth 1 -type d | wc -l)"
echo "Service uptime: $(systemctl show campaign-monitor -p ActiveEnterTimestamp)"
echo "Recent deployments: $(grep -c "New URL available" logs/campaign_monitor.log)"
```

## 📊 Metrics & Reporting

### Key Performance Indicators:
```bash
# Campaign deployment speed
grep "New URL available" logs/campaign_monitor.log | tail -10

# Success rate
TOTAL=$(grep -c "New static campaigns detected" logs/campaign_monitor.log)
SUCCESS=$(grep -c "Nginx reloaded successfully" logs/campaign_monitor.log)  
echo "Success rate: $(($SUCCESS*100/$TOTAL))%"

# Average detection time
grep "New static campaigns detected\|Nginx reloaded successfully" logs/campaign_monitor.log | 
    tail -20 | awk '{print $2}' | # Extract timestamps and calculate differences
```

### Dashboard Metrics:
```bash
#!/bin/bash
# dashboard_metrics.sh

echo "=== Campaign Deployment Dashboard ==="
echo "Date: $(date)"
echo ""
echo "📊 Service Status:"
systemctl is-active campaign-monitor && echo "  ✅ Service: Running" || echo "  ❌ Service: Down"
echo "  📈 Uptime: $(systemctl show campaign-monitor -p ActiveEnterTimestamp --value)"
echo ""
echo "📂 Campaign Summary:"
echo "  Total Static: $(find campaigns/ -name "index.php" -not -path "*/public/*" | wc -l)"
echo "  Total Laravel: $(find campaigns/ -path "*/public/index.php" | wc -l)"
echo ""
echo "⚡ Recent Activity:"
echo "  Last 24h deployments: $(grep -c "$(date -d yesterday '+%Y-%m-%d')" logs/campaign_monitor.log)"
echo "  Last deployment: $(grep "New URL available" logs/campaign_monitor.log | tail -1 | cut -d']' -f1)"
```

## 🚨 Incident Response

### Service Down:
```bash
# 1. Check service status
systemctl status campaign-monitor

# 2. Check logs for errors
journalctl -u campaign-monitor -n 50

# 3. Restart service
systemctl restart campaign-monitor

# 4. Verify recovery
bash campaign_control.sh status
```

### Nginx Config Corruption:
```bash
# 1. Check nginx syntax
nginx -t

# 2. Restore from backup
cp nginx/backups/campaignmanagerv12.conf.backup.LATEST nginx/config.conf

# 3. Reload nginx
systemctl reload nginx

# 4. Restart monitoring
systemctl restart campaign-monitor
```

### Disk Space Full:
```bash
# 1. Clean old backups
find nginx/backups/ -mtime +7 -delete

# 2. Compress old logs
gzip logs/*.log

# 3. Archive old campaigns
tar -czf archived_campaigns_$(date +%Y%m%d).tar.gz campaigns/old_*
rm -rf campaigns/old_*
```

## 🎉 Success Metrics

**Production Success Indicators:**
- ✅ 99%+ uptime for monitoring service
- ✅ <60 second deployment time for new campaigns  
- ✅ Zero manual nginx configuration changes
- ✅ Automated error recovery
- ✅ Complete audit trail of all deployments

**Team Productivity Gains:**
- 📈 Marketing team: Self-service campaign deployment
- 📈 DevOps team: Eliminated manual deployment tasks  
- 📈 Development team: Focus on features, not deployments
- 📈 Business: Faster time-to-market for campaigns

Your production system is now optimized for scale, reliability, and zero-touch operations! 🚀