# Setup Script Improvements

## What's Been Improved

### 1. Permission Management (775/664)
- **Directory permissions**: Now set to 775 (read/write/execute for owner and group, read/execute for others)
- **File permissions**: Now set to 664 (read/write for owner and group, read for others)  
- **Special handling**: Laravel artisan files get 775, storage directories get proper permissions
- **Web server compatibility**: Proper www-data:www-data ownership for all campaigns

### 2. Nginx Config Examples with Proper Naming

The scripts now generate nginx configuration files with standardized naming:

**Static Campaigns:**
- `static_VisoPisesLiquidShop.conf`
- `static_unileverPromo.conf`

**Laravel Campaigns:**  
- `laravel_knorrBackToSchool.conf`
- `laravel_campaignName.conf`

### 3. Enhanced Debugging and Troubleshooting

New debug command provides comprehensive information:
- System information (OS, user, working directory)
- Nginx and PHP-FPM status
- Directory structure analysis
- Campaign-specific analysis (files, permissions, accessibility)
- Configuration file validation
- Troubleshooting tips and common commands

## New Commands Available

### campaign_manager.sh
```bash
# Set proper permissions for all campaigns
./campaign_manager.sh permissions

# Set permissions for specific campaign
./campaign_manager.sh permissions --campaign VisoPisesLiquidShop

# Show comprehensive debug information
./campaign_manager.sh debug --verbose

# Generate configs with proper naming
./campaign_manager.sh configure --separate-config
```

### Usage Examples

```bash
# Quick setup for new VM
cd /var/www/campaignmanagerv12/scripts/setup

# 1. Detect available campaigns
./campaign_manager.sh detect --verbose

# 2. Set proper permissions (775/664)
./campaign_manager.sh permissions

# 3. Generate nginx configs with proper naming
./campaign_manager.sh configure --separate-config

# 4. Test and deploy
./campaign_config.sh test && ./campaign_config.sh reload

# 5. Debug if needed
./campaign_manager.sh debug --verbose
```

## Benefits for VM Migration

1. **Consistent Permissions**: 775 directory permissions work across different VMs and user configurations
2. **Clear Naming**: Config files are clearly named (static_CampaignName.conf, laravel_CampaignName.conf)  
3. **Easy Debugging**: Debug command shows exactly what's wrong and how to fix it
4. **Automated Setup**: One-command deployment with proper error checking

## File Structure After Improvements

```
/var/www/campaignmanagerv12/scripts/setup/
├── campaign_manager.sh          # Main management (enhanced)
├── campaign_config.sh           # Config management (enhanced) 
├── config_examples.md           # Detailed examples and usage
├── README_IMPROVEMENTS.md       # This file
└── [other existing scripts...]
```

## Quick Test

To verify the improvements work:

```bash
# Test the new functionality
./campaign_manager.sh debug
./campaign_manager.sh list
./campaign_manager.sh permissions --dry-run --verbose
```

All scripts are now executable and ready for use on any VM with the same directory structure.