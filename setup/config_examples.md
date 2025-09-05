# Nginx Configuration Examples

This document provides examples of nginx configuration file naming and content for different campaign types.

## File Naming Convention

The setup scripts use the following naming convention for separate nginx configuration files:

```
{type}_{campaignname}.conf
```

Where:
- `type` is either "static" or "laravel"
- `campaignname` is the actual campaign directory name

## Examples

### Static Campaign Examples

#### static_VisoPisesLiquidShop.conf
```nginx
# VisoPisesLiquidShop static website configuration

# VisoPisesLiquidShop static website
location ^~ /VisoPisesLiquidShop/ {
    alias /var/www/campaignmanagerv12/campaigns/VisoPisesLiquidShop/;
    index index.php index.html index.htm;
    try_files $uri $uri/ =404;
    
    # Handle PHP files
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $request_filename;
        include fastcgi_params;
    }
}

# VisoPisesLiquidShop static assets
location ~ ^/VisoPisesLiquidShop/(assets|css|js|images|img|fonts)/(.*)$ {
    alias /var/www/campaignmanagerv12/campaigns/VisoPisesLiquidShop/;
    expires 30d;
    add_header Cache-Control "public, no-transform";
    try_files /$1/$2 =404;
    access_log off;
}
```

#### static_unileverPromo.conf
```nginx
# unileverPromo static website configuration

# unileverPromo static website
location ^~ /unileverPromo/ {
    alias /var/www/campaignmanagerv12/campaigns/unileverPromo/;
    index index.php index.html index.htm;
    try_files $uri $uri/ =404;
    
    # Handle PHP files
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $request_filename;
        include fastcgi_params;
    }
}

# unileverPromo static assets
location ~ ^/unileverPromo/(assets|css|js|images|img|fonts)/(.*)$ {
    alias /var/www/campaignmanagerv12/campaigns/unileverPromo/;
    expires 30d;
    add_header Cache-Control "public, no-transform";
    try_files /$1/$2 =404;
    access_log off;
}
```

### Laravel Campaign Examples

#### laravel_knorrBackToSchool.conf
```nginx
# knorrBackToSchool Laravel application configuration

# knorrBackToSchool Laravel application
location ^~ /knorrBackToSchool/ {
    alias /var/www/campaignmanagerv12/campaigns/knorrBackToSchool/public/;
    index index.php;
    try_files $uri $uri/ @knorrBackToSchool;
    
    # Handle PHP files
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $request_filename;
        include fastcgi_params;
    }
}

# Laravel fallback
location @knorrBackToSchool {
    rewrite ^/knorrBackToSchool/(.*)$ /knorrBackToSchool/index.php?/$1 last;
}

# knorrBackToSchool Laravel assets
location ~ ^/knorrBackToSchool/(css|js|images|img|fonts|assets)/(.*)$ {
    alias /var/www/campaignmanagerv12/campaigns/knorrBackToSchool/public/;
    expires 30d;
    add_header Cache-Control "public, no-transform";
    try_files /$1/$2 =404;
    access_log off;
}
```

## Permission Settings

The setup scripts now automatically set proper permissions:

### Directory Permissions: 775
- Allows read, write, execute for owner and group
- Allows read, execute for others
- Perfect for web directories that need group access

### File Permissions: 664
- Allows read, write for owner and group
- Allows read for others
- Secure for web files

### Special Cases:
- Laravel `artisan` file: 775 (executable)
- Laravel `storage/` directory: 775 (recursive)
- Laravel `bootstrap/cache/` directory: 775 (recursive)

## Usage Commands

### Generate Configuration with Examples Above
```bash
# Generate separate config files (recommended)
./campaign_manager.sh configure --separate-config

# Generate for specific campaign
./campaign_config.sh generate --campaigns "VisoPisesLiquidShop knorrBackToSchool" --separate

# Set proper permissions
./campaign_manager.sh permissions --campaign VisoPisesLiquidShop

# Debug and troubleshoot
./campaign_manager.sh debug --verbose
```

### Test and Deploy
```bash
# Test configuration
./campaign_config.sh test

# Reload nginx if test passes
./campaign_config.sh reload
```

## Debugging Tips

### Common Issues and Solutions

1. **Permission Errors**
   ```bash
   # Fix permissions for all campaigns
   ./campaign_manager.sh permissions
   
   # Fix permissions for specific campaign
   ./campaign_manager.sh permissions --campaign campaignname
   ```

2. **Nginx Configuration Errors**
   ```bash
   # Test configuration
   sudo nginx -t
   
   # Check error logs
   tail -f /var/log/nginx/error.log
   ```

3. **PHP-FPM Issues**
   ```bash
   # Check PHP-FPM status
   systemctl status php8.4-fpm
   
   # Restart if needed
   sudo systemctl restart php8.4-fpm
   ```

4. **Campaign Not Accessible**
   ```bash
   # Check if campaign exists and has proper files
   ./campaign_manager.sh debug --verbose
   
   # Test URL accessibility
   curl -I https://devpayload.southeastasia.cloudapp.azure.com/campaignname/
   ```

## Directory Structure Example

```
/var/www/campaignmanagerv12/
├── campaigns/
│   ├── VisoPisesLiquidShop/          # Static campaign
│   │   ├── index.php
│   │   ├── assets/
│   │   └── css/
│   ├── knorrBackToSchool/            # Laravel campaign
│   │   ├── artisan
│   │   ├── composer.json
│   │   ├── public/
│   │   │   └── index.php
│   │   └── storage/
│   └── unileverPromo/                # Static campaign
│       ├── index.html
│       └── images/
├── nginx/
│   ├── campaignmanagerv12.conf       # Main config
│   ├── static_VisoPisesLiquidShop.conf
│   ├── laravel_knorrBackToSchool.conf
│   └── static_unileverPromo.conf
└── scripts/
    └── setup/
        ├── campaign_manager.sh       # Main management script
        └── campaign_config.sh        # Configuration management
```

This structure ensures proper organization and easy debugging when working with multiple campaigns across different VMs.