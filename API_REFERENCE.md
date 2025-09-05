# 🔧 API Reference - Zero-Touch Campaign Deployment

## 📋 Script Commands Reference

### Main Control Interface

#### `campaign_control.sh`
**Purpose**: Service management and monitoring interface

**Usage**: `bash campaign_control.sh <command> [options]`

**Commands**:
```bash
start           # Start the campaign monitor service
stop            # Stop the campaign monitor service  
restart         # Restart the campaign monitor service
status          # Show detailed service status
enable          # Enable auto-start on boot
disable         # Disable auto-start on boot
campaigns       # List all current campaigns with URLs
logs <type>     # Show logs (service|app|follow)
```

**Examples**:
```bash
bash campaign_control.sh status
bash campaign_control.sh logs follow
bash campaign_control.sh campaigns
```

**Return Codes**:
- `0` - Success
- `1` - Service not installed
- `2` - Command failed

---

### Installation & Setup

#### `install_campaign_monitor.sh`
**Purpose**: One-time system installation

**Usage**: `sudo bash install_campaign_monitor.sh`

**What it does**:
1. Creates necessary directories
2. Sets script permissions
3. Installs systemd service
4. Enables and starts service
5. Validates installation

**Requirements**:
- Must run with sudo
- Systemd available
- Nginx installed
- PHP-FPM running

---

### Detection & Deployment

#### `simple_campaign_deploy.sh`
**Purpose**: Manual campaign detection and config generation

**Usage**: `bash simple_campaign_deploy.sh`

**Output**:
- Lists current static campaigns
- Shows existing configurations  
- Generates nginx config blocks for new campaigns
- Provides copy-paste ready configurations

**Use Cases**:
- One-time manual deployment
- Debugging campaign detection
- Generating config without installing service

#### `test_detection.sh`
**Purpose**: Debug campaign detection logic

**Usage**: `bash test_detection.sh`

**Output**:
- Lists all directories in campaigns folder
- Shows file structure for each campaign
- Identifies campaign type (Static/Laravel/Unknown)

---

## 🔧 Configuration Files

### `static_campaign.template`
**Purpose**: Nginx configuration template for static campaigns

**Template Variables**:
- `{{CAMPAIGN_NAME}}` - Replaced with actual campaign name

**Template Structure**:
```nginx
# {{CAMPAIGN_NAME}} campaign - static PHP files
location ^~ /{{CAMPAIGN_NAME}}/ {
    alias /path/to/campaigns/{{CAMPAIGN_NAME}}/;
    try_files $uri $uri/ =404;
    
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $request_filename;
    }
}

# {{CAMPAIGN_NAME}} campaign - static assets  
location ~ ^/{{CAMPAIGN_NAME}}/(assets|css|js|images)/(.*)$ {
    alias /path/to/campaigns/{{CAMPAIGN_NAME}}/;
    expires 30d;
    add_header Cache-Control "public, no-transform";
    try_files /$1/$2 =404;
    access_log off;
}
```

### `campaign-monitor.service`
**Purpose**: Systemd service definition

**Key Settings**:
- `Type=simple` - Service runs in foreground
- `Restart=always` - Auto-restart on failure
- `RestartSec=10` - Wait 10s before restart
- `User=azureuser` - Run as specific user
- `Group=www-data` - Web server group access

---

## 🤖 Daemon Process

### `campaign_monitor_daemon.sh`
**Purpose**: Background monitoring daemon

**Configuration Variables**:
```bash
CAMPAIGNS_DIR="/path/to/campaigns"        # Where to look for campaigns
NGINX_DIR="/path/to/nginx"               # Nginx configs location
CONFIG_FILE="$NGINX_DIR/site.conf"       # Main nginx config file
TEMPLATE_FILE="$NGINX_DIR/static_campaign.template"  # Template file
LOG_FILE="/path/to/logs/campaign_monitor.log"        # Log file location
CHECK_INTERVAL=30                        # Check every N seconds
```

**Process Flow**:
1. Initialize monitoring state
2. Detect current static campaigns
3. Compare with previous state
4. Generate nginx config for new campaigns
5. Test nginx configuration
6. Backup current config
7. Apply new configuration
8. Reload nginx
9. Log results
10. Sleep for `CHECK_INTERVAL` seconds
11. Repeat from step 2

**Detection Logic**:
```bash
# Campaign is static if:
- Directory exists in campaigns/
- Has index.php in root directory
- Does NOT have public/index.php (Laravel indicator)
- Name matches regex: ^[A-Za-z0-9_-]+$
```

**Signal Handling**:
- `SIGTERM` - Graceful shutdown, cleanup PID file
- `SIGINT` - Graceful shutdown (Ctrl+C)

---

## 📊 Log Format

### Application Log Format
```
[YYYY-MM-DD HH:MM:SS] <LEVEL> <MESSAGE>
```

**Log Levels**:
- `🚀` - Service start/stop
- `🔍` - Campaign detection  
- `🔧` - Configuration updates
- `✅` - Success operations
- `❌` - Error conditions
- `📁` - File operations
- `🔗` - New URLs available

**Example Log Entries**:
```
[2025-09-05 15:30:15] 🚀 Campaign monitor daemon started (PID: 12345)
[2025-09-05 15:30:45] 🔍 New static campaigns detected: NewCampaign
[2025-09-05 15:30:46] 🔧 Updating nginx configuration for campaigns: NewCampaign
[2025-09-05 15:30:47] 📁 Backed up config to: nginx/backups/config.backup.20250905_153047
[2025-09-05 15:30:48] ✅ Configuration test passed
[2025-09-05 15:30:49] ✅ Nginx reloaded successfully
[2025-09-05 15:30:49] 🔗 New URL available: https://domain.com/NewCampaign/
```

---

## 🔄 System Integration

### File System Requirements
```
project/
├── campaigns/          # 755, writable by www-data group
├── scripts/           # 755, executable scripts
├── nginx/            # 755, config files
├── nginx/backups/    # 755, automatic backups
├── logs/             # 755, writable for logging
└── systemd/          # 644, service definitions
```

### Process Integration
```
systemd (campaign-monitor.service)
├── campaign_monitor_daemon.sh (main process)
├── nginx configuration updates
├── nginx reload commands  
└── logging system
```

### Network Requirements
- Nginx must be able to serve from campaigns directory
- PHP-FPM socket must be accessible
- Web server must have read access to campaign files

---

## 🔒 Security Model

### User/Group Model
- **Service User**: `azureuser` (or configured user)
- **Web Group**: `www-data` (nginx/apache group)
- **Permissions**: 755 for directories, 644 for files
- **Sudo Access**: Only for nginx reload

### File Access Control
```bash
# Scripts: Owner execute only
chmod 700 scripts/*.sh

# Campaigns: Group writable
chmod 775 campaigns/
chmod 664 campaigns/*/*.php

# Configs: Group readable
chmod 644 nginx/*.conf

# Logs: Group writable  
chmod 664 logs/*.log
```

### Process Isolation
- Service runs as unprivileged user
- Limited sudo access (only `systemctl reload nginx`)
- Input validation on campaign names
- Configuration syntax testing before application

---

## 🚨 Error Codes & Responses

### Detection Errors
- **Campaign Invalid Name**: Silently ignored, logged
- **No Index.php**: Silently ignored (not a campaign)
- **Laravel Structure**: Silently ignored (manual config needed)

### Configuration Errors  
- **Nginx Test Failed**: Rollback, log error, continue monitoring
- **Nginx Reload Failed**: Rollback to backup, log error, continue
- **File Permission Error**: Log error, skip update, continue

### System Errors
- **Disk Full**: Log critical error, continue monitoring
- **Service Kill Signal**: Graceful shutdown, cleanup PID file
- **Unexpected Exit**: Systemd restarts service automatically

---

## 📡 Monitoring Integration

### Health Check Endpoint
```bash
# Check if service is responsive
systemctl is-active campaign-monitor
echo $?  # 0 = active, non-zero = inactive
```

### Metrics Collection
```bash
# Service uptime
systemctl show campaign-monitor -p ActiveEnterTimestamp

# Campaign count
find campaigns/ -name "index.php" -not -path "*/public/*" | wc -l

# Deployment count (last 24h)
grep -c "$(date -d yesterday '+%Y-%m-%d')" logs/campaign_monitor.log

# Error rate
TOTAL=$(grep -c "New static campaigns detected" logs/campaign_monitor.log)
ERRORS=$(grep -c "❌" logs/campaign_monitor.log)
echo "Error rate: $(echo "scale=2; $ERRORS*100/$TOTAL" | bc)%"
```

### External Monitoring
- **Service Status**: `systemctl is-active campaign-monitor`
- **Log Monitoring**: Monitor for `❌` entries in logs
- **Disk Space**: Monitor campaigns directory disk usage
- **Response Time**: Monitor nginx config update speed

This API reference provides complete technical documentation for integrating, extending, and monitoring the zero-touch campaign deployment system. 🚀