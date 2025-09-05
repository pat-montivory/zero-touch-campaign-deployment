# 🚀 Automatic Campaign Deployment System

This system automatically deploys static websites and Laravel applications when they are copied to the campaigns folder.

## ⚡ Quick Setup

### 1. Install the Auto-Deploy System (First Time Only)
```bash
cd /var/www/campaignmanagerv12/scripts/auto-deploy
sudo ./install_auto_deploy.sh
```

### 2. Deploy Campaigns Automatically
Simply copy or clone campaigns into the campaigns folder:

```bash
cd /var/www/campaignmanagerv12/campaigns

# Deploy static campaign
git clone https://github.com/montivory/VisoPisesLiquidShop.git

# Deploy Laravel campaign  
git clone https://github.com/montivory/KnorrBackToSchool.git
```

**That's it!** 🎉 The system will automatically:
- ✅ Detect campaign type (static or Laravel)
- ✅ Set proper permissions (775/664)
- ✅ Install Laravel dependencies (`composer install`)
- ✅ Generate Laravel `.env` and application key
- ✅ Create nginx configuration files
- ✅ Reload nginx
- ✅ Generate accessible URLs

## 📱 Generated URLs

### Static Campaigns (like VisoPisesLiquidShop)
- `https://devpayload.southeastasia.cloudapp.azure.com/VisoPisesLiquidShop/`
- `https://devpayload.southeastasia.cloudapp.azure.com/VisoPisesLiquidShop/index.php`

### Laravel Campaigns (like KnorrBackToSchool)
- `https://devpayload.southeastasia.cloudapp.azure.com/KnorrBackToSchool/`
- `https://devpayload.southeastasia.cloudapp.azure.com/KnorrBackToSchool/signup`
- `https://devpayload.southeastasia.cloudapp.azure.com/KnorrBackToSchool/signin`

## 🔍 Monitoring & Status

### Check Service Status
```bash
sudo systemctl status campaign-auto-deploy
```

### View Live Logs
```bash
sudo tail -f /var/log/campaign-auto-deploy.log
```

### Manual Daemon Control
```bash
# Check daemon status
sudo /var/www/campaignmanagerv12/scripts/auto-deploy/auto_deploy_daemon.sh status

# Restart daemon
sudo /var/www/campaignmanagerv12/scripts/auto-deploy/auto_deploy_daemon.sh restart

# Stop daemon
sudo /var/www/campaignmanagerv12/scripts/auto-deploy/auto_deploy_daemon.sh stop
```

## 📂 How It Works

1. **File Monitor**: Daemon runs in background checking `/var/www/campaignmanagerv12/campaigns/` every 10 seconds
2. **Auto-Detection**: Identifies static (index.php/html) vs Laravel (composer.json + artisan) campaigns
3. **Smart Setup**: 
   - Static: Sets permissions and creates nginx config
   - Laravel: Runs `composer install`, creates `.env`, generates app key, sets permissions, creates nginx config
4. **Zero-Downtime**: Tests nginx config before reloading
5. **URL Generation**: Automatically provides accessible URLs in logs

## 🛠️ Configuration Files Created

### Static Campaign
- **Config**: `/var/www/campaignmanagerv12/nginx/static_CampaignName.conf`
- **Features**: PHP support, asset caching, security headers

### Laravel Campaign  
- **Config**: `/var/www/campaignmanagerv12/nginx/laravel_CampaignName.conf`
- **Features**: Laravel routing, asset optimization, fallback handling

## 📋 System Requirements

- ✅ Ubuntu/Debian Linux
- ✅ Nginx
- ✅ PHP 8.4 with PHP-FPM
- ✅ Composer (for Laravel campaigns)
- ✅ Git
- ✅ SSL Certificate (Let's Encrypt recommended)

## 🔧 Troubleshooting

### Service Not Starting
```bash
sudo systemctl status campaign-auto-deploy
sudo journalctl -u campaign-auto-deploy -f
```

### Campaign Not Deploying
```bash
# Check if detected
sudo tail -f /var/log/campaign-auto-deploy.log

# Check permissions
ls -la /var/www/campaignmanagerv12/campaigns/

# Manual deploy
cd /var/www/campaignmanagerv12/scripts/setup
./campaign_manager.sh deploy --campaign CampaignName
```

### Nginx Issues
```bash
sudo nginx -t
sudo systemctl reload nginx
```

## 🗑️ Uninstall
```bash
cd /var/www/campaignmanagerv12/scripts/auto-deploy
sudo ./install_auto_deploy.sh uninstall
```

## 📊 Example Deployment Flow

```
User Action: git clone https://github.com/montivory/KnorrBackToSchool.git
     ↓
Daemon detects new Laravel campaign: KnorrBackToSchool
     ↓  
Auto-runs: composer install, .env setup, permissions
     ↓
Creates: /var/www/campaignmanagerv12/nginx/laravel_KnorrBackToSchool.conf
     ↓
Tests and reloads nginx
     ↓
URLs available:
✅ https://devpayload.southeastasia.cloudapp.azure.com/KnorrBackToSchool/
✅ https://devpayload.southeastasia.cloudapp.azure.com/KnorrBackToSchool/signup  
✅ https://devpayload.southeastasia.cloudapp.azure.com/KnorrBackToSchool/signin
```

## 🔒 Security Features

- ✅ Proper file permissions (775 dirs, 664 files)
- ✅ www-data:www-data ownership
- ✅ Secure nginx configurations
- ✅ No root execution (runs as www-data)
- ✅ Configuration validation before reload

---

**Ready to deploy?** Just copy your campaigns to `/var/www/campaignmanagerv12/campaigns/` and watch the magic happen! ✨