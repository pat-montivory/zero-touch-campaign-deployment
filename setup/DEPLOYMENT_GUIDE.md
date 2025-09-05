# Campaign Manager Deployment Guide

This guide explains how to deploy both static and Laravel campaigns to other servers using the `/var/www/campaignmanagerv12/scripts/setup` tools.

## Prerequisites

### Server Requirements
- **OS**: Ubuntu/Debian Linux
- **Web Server**: Nginx
- **PHP**: PHP 8.4 with PHP-FPM
- **Composer**: For Laravel campaigns
- **Git**: For cloning repositories
- **SSL Certificate**: Let's Encrypt recommended

### Directory Structure
```
/var/www/campaignmanagerv12/
├── campaigns/                    # Campaign directories
├── nginx/                       # Nginx configuration files
│   ├── campaignmanagerv12.conf  # Main nginx config
│   ├── static_*.conf           # Static campaign configs
│   └── laravel_*.conf          # Laravel campaign configs
├── public/                     # Main Laravel app public directory
└── scripts/
    └── setup/                  # Deployment scripts
        ├── campaign_manager.sh
        ├── campaign_config.sh
        └── [other scripts...]
```

## Step-by-Step Deployment

### 1. Server Setup

#### Install Dependencies
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y nginx php8.4 php8.4-fpm php8.4-mysql php8.4-xml php8.4-curl php8.4-mbstring php8.4-zip php8.4-gd git composer curl

# Start services
sudo systemctl enable nginx php8.4-fpm
sudo systemctl start nginx php8.4-fpm
```

#### Setup SSL Certificate (Let's Encrypt)
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com
```

### 2. Copy Setup Scripts

Transfer the setup scripts to your new server:

```bash
# On source server - create deployment package
cd /var/www/campaignmanagerv12
tar -czf campaign-manager-scripts.tar.gz scripts/ nginx/campaignmanagerv12.conf

# On target server - extract scripts
sudo mkdir -p /var/www/campaignmanagerv12/scripts
cd /var/www/campaignmanagerv12
sudo tar -xzf campaign-manager-scripts.tar.gz

# Make scripts executable
sudo chmod +x /var/www/campaignmanagerv12/scripts/setup/*.sh
```

### 3. Configure Main Laravel Application

Copy your main Laravel application to the new server:

```bash
# Copy main Laravel app (adjust source path as needed)
sudo cp -r /path/to/main/laravel/app /var/www/campaignmanagerv12/
sudo chown -R www-data:www-data /var/www/campaignmanagerv12/
```

### 4. Deploy Static Campaigns

#### Example: VisoPisesLiquidShop (Static)

```bash
cd /var/www/campaignmanagerv12/scripts/setup

# Clone the static campaign
sudo -u www-data git clone https://github.com/montivory/VisoPisesLiquidShop.git /var/www/campaignmanagerv12/campaigns/VisoPisesLiquidShop

# Detect campaigns
./campaign_manager.sh detect --verbose

# Set proper permissions (775/664)
./campaign_manager.sh permissions --campaign VisoPisesLiquidShop --verbose

# Generate nginx configuration
./campaign_manager.sh configure --separate-config --verbose

# Test and deploy
./campaign_config.sh test
./campaign_config.sh reload
```

**Expected Result:**
- Creates: `/var/www/campaignmanagerv12/nginx/static_VisoPisesLiquidShop.conf`
- URL accessible: `https://yourdomain.com/VisoPisesLiquidShop/index.php`

### 5. Deploy Laravel Campaigns

#### Example: KnorrBackToSchool (Laravel)

```bash
cd /var/www/campaignmanagerv12/scripts/setup

# Clone the Laravel campaign
sudo -u www-data git clone https://github.com/montivory/KnorrBackToSchool.git /var/www/campaignmanagerv12/campaigns/KnorrBackToSchool

# Change to campaign directory and install dependencies
cd /var/www/campaignmanagerv12/campaigns/KnorrBackToSchool
sudo -u www-data composer install --no-dev --optimize-autoloader

# Setup Laravel environment
sudo -u www-data cp .env.example .env
sudo -u www-data php artisan key:generate

# Return to setup directory
cd /var/www/campaignmanagerv12/scripts/setup

# Detect campaigns (should show as Laravel campaign)
./campaign_manager.sh detect --verbose

# Set proper permissions
./campaign_manager.sh permissions --campaign KnorrBackToSchool --verbose

# Generate nginx configuration
./campaign_manager.sh configure --separate-config --verbose

# Test and deploy
./campaign_config.sh test
./campaign_config.sh reload
```

**Expected Result:**
- Creates: `/var/www/campaignmanagerv12/nginx/laravel_KnorrBackToSchool.conf`
- URLs accessible:
  - `https://yourdomain.com/KnorrBackToSchool/`
  - `https://yourdomain.com/KnorrBackToSchool/signup`
  - `https://yourdomain.com/KnorrBackToSchool/signin`

## Configuration Files Generated

### Static Campaign Configuration
**File**: `static_CampaignName.conf`
```nginx
# CampaignName static website configuration

location ^~ /CampaignName/ {
    alias /var/www/campaignmanagerv12/campaigns/CampaignName/;
    index index.php index.html index.htm;
    try_files $uri $uri/ =404;
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $request_filename;
        include fastcgi_params;
    }
}

location ~ ^/CampaignName/(assets|css|js|images|img|fonts)/(.*)$ {
    alias /var/www/campaignmanagerv12/campaigns/CampaignName/;
    expires 30d;
    add_header Cache-Control "public, no-transform";
    try_files /$1/$2 =404;
    access_log off;
}
```

### Laravel Campaign Configuration
**File**: `laravel_CampaignName.conf`
```nginx
# CampaignName Laravel application configuration

location ^~ /CampaignName/ {
    alias /var/www/campaignmanagerv12/campaigns/CampaignName/public/;
    index index.php;
    try_files $uri $uri/ @campaignName;
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $request_filename;
        include fastcgi_params;
    }
}

location @campaignName {
    rewrite ^/CampaignName/(.*)$ /CampaignName/index.php?/$1 last;
}

location ~ ^/CampaignName/(assets|css|js|images|img|fonts)/(.*)$ {
    alias /var/www/campaignmanagerv12/campaigns/CampaignName/public/;
    expires 30d;
    add_header Cache-Control "public, no-transform";
    try_files /$1/$2 =404;
    access_log off;
}
```

## Available Commands

### campaign_manager.sh
```bash
# Detect campaigns
./campaign_manager.sh detect --verbose

# Deploy with auto-configuration
./campaign_manager.sh deploy --campaign CampaignName

# Set permissions (775 directories, 664 files)
./campaign_manager.sh permissions [--campaign CampaignName]

# Show comprehensive debug information
./campaign_manager.sh debug --verbose

# List all campaigns
./campaign_manager.sh list

# Show status
./campaign_manager.sh status
```

### campaign_config.sh
```bash
# Generate nginx configurations
./campaign_config.sh generate --separate

# Test nginx configuration
./campaign_config.sh test

# Reload nginx
./campaign_config.sh reload

# Backup configuration
./campaign_config.sh backup

# Clean configurations
./campaign_config.sh clean
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Permission Errors
```bash
# Fix permissions for all campaigns
./campaign_manager.sh permissions

# Fix specific campaign
./campaign_manager.sh permissions --campaign CampaignName
```

#### 2. Nginx Configuration Errors
```bash
# Test configuration
sudo nginx -t

# Check error logs
sudo tail -f /var/log/nginx/error.log

# Reload configuration
./campaign_config.sh reload
```

#### 3. PHP-FPM Issues
```bash
# Check PHP-FPM status
sudo systemctl status php8.4-fpm

# Restart PHP-FPM
sudo systemctl restart php8.4-fpm
```

#### 4. Laravel Specific Issues
```bash
# Laravel permissions
sudo chown -R www-data:www-data /var/www/campaignmanagerv12/campaigns/CampaignName/storage
sudo chown -R www-data:www-data /var/www/campaignmanagerv12/campaigns/CampaignName/bootstrap/cache

# Clear Laravel cache
cd /var/www/campaignmanagerv12/campaigns/CampaignName
php artisan cache:clear
php artisan config:clear
php artisan view:clear
```

### Debug Information
```bash
# Get comprehensive system information
./campaign_manager.sh debug --verbose

# This will show:
# - System information
# - Nginx and PHP status
# - Directory structure
# - Campaign analysis
# - Configuration validation
# - Troubleshooting tips
```

## Automated Deployment Script

Create an automated deployment script for new servers:

```bash
#!/bin/bash
# auto-deploy.sh

DOMAIN="your-domain.com"
GITHUB_CAMPAIGNS=(
    "static:VisoPisesLiquidShop:https://github.com/montivory/VisoPisesLiquidShop.git"
    "laravel:KnorrBackToSchool:https://github.com/montivory/KnorrBackToSchool.git"
)

# Setup base system
sudo apt update && sudo apt install -y nginx php8.4 php8.4-fpm composer git

# Setup directories
sudo mkdir -p /var/www/campaignmanagerv12/{campaigns,nginx,scripts}

# Deploy campaigns
cd /var/www/campaignmanagerv12/scripts/setup

for campaign_info in "${GITHUB_CAMPAIGNS[@]}"; do
    IFS=':' read -r type name repo <<< "$campaign_info"
    
    echo "Deploying $type campaign: $name"
    
    # Clone repository
    sudo -u www-data git clone "$repo" "/var/www/campaignmanagerv12/campaigns/$name"
    
    # Handle Laravel setup
    if [[ "$type" == "laravel" ]]; then
        cd "/var/www/campaignmanagerv12/campaigns/$name"
        sudo -u www-data composer install --no-dev
        sudo -u www-data cp .env.example .env
        sudo -u www-data php artisan key:generate
        cd /var/www/campaignmanagerv12/scripts/setup
    fi
    
    # Set permissions and configure
    ./campaign_manager.sh permissions --campaign "$name"
    ./campaign_manager.sh configure --separate-config
done

# Test and reload
./campaign_config.sh test && ./campaign_config.sh reload

echo "Deployment completed!"
echo "Check campaigns at:"
for campaign_info in "${GITHUB_CAMPAIGNS[@]}"; do
    IFS=':' read -r type name repo <<< "$campaign_info"
    echo "  https://$DOMAIN/$name/"
done
```

## Best Practices

1. **Always backup** before deployment:
   ```bash
   ./campaign_config.sh backup
   ```

2. **Test configurations** before reload:
   ```bash
   ./campaign_config.sh test
   ```

3. **Use separate config files** for easier management:
   ```bash
   ./campaign_manager.sh configure --separate-config
   ```

4. **Set proper permissions** after cloning:
   ```bash
   ./campaign_manager.sh permissions --campaign CampaignName
   ```

5. **Monitor logs** during deployment:
   ```bash
   sudo tail -f /var/log/nginx/error.log
   ```

6. **Use debug mode** for troubleshooting:
   ```bash
   ./campaign_manager.sh debug --verbose
   ```

This deployment system ensures consistent, reliable deployment of both static and Laravel campaigns across different servers while maintaining proper security and performance configurations.