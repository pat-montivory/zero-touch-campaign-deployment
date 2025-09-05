#!/bin/bash

# Simple Campaign Deploy Script
# Automatically detects and configures static campaigns

CAMPAIGNS_DIR="/home/azureuser/dev/campaignmanagerv12/campaigns"
CONFIG_FILE="/home/azureuser/dev/campaignmanagerv12/nginx/campaignmanagerv12.conf"
TEMPLATE_FILE="/home/azureuser/dev/campaignmanagerv12/nginx/static_campaign.template"

echo "🎯 Simple Campaign Deploy Script"
echo "================================="

# Function to check if campaign is static
is_static_campaign() {
    local dir="$1"
    [[ -f "$dir/index.php" && ! -f "$dir/public/index.php" ]]
}

# Function to get campaign name from comment in config
get_existing_campaigns() {
    grep -oP "# \K[A-Za-z0-9_-]+(?= campaign - static PHP files)" "$CONFIG_FILE"
}

echo "🔍 Detecting static campaigns..."
static_campaigns=()

for dir in "$CAMPAIGNS_DIR"/*; do
    if [[ -d "$dir" ]]; then
        campaign_name=$(basename "$dir")
        
        # Skip Laravel campaigns
        if [[ "$campaign_name" == "KnorrBackToSchool" ]]; then
            continue
        fi
        
        if is_static_campaign "$dir"; then
            static_campaigns+=("$campaign_name")
            echo "   📂 Found static campaign: $campaign_name"
        fi
    fi
done

echo ""
echo "📊 Current static campaigns: ${static_campaigns[*]}"
echo "📊 Existing in config: $(get_existing_campaigns | tr '\n' ' ')"

# Check what needs to be added
existing=($(get_existing_campaigns))
new_campaigns=()

for campaign in "${static_campaigns[@]}"; do
    if [[ ! " ${existing[*]} " =~ " ${campaign} " ]]; then
        new_campaigns+=("$campaign")
    fi
done

if [[ ${#new_campaigns[@]} -gt 0 ]]; then
    echo ""
    echo "🔧 New campaigns to add: ${new_campaigns[*]}"
    echo ""
    
    # Generate configuration for new campaigns
    for campaign in "${new_campaigns[@]}"; do
        echo "Adding configuration for: $campaign"
        
        # Generate config from template
        config_block=$(sed "s/{{CAMPAIGN_NAME}}/$campaign/g" "$TEMPLATE_FILE")
        
        # Find insertion point and add config
        # For now, just show what would be added
        echo "Configuration block:"
        echo "$config_block"
        echo ""
    done
    
    echo "✅ Manual step needed: Add the above configuration blocks to your nginx config"
    echo "   Insert them before the '# Handle Laravel campaign PHP execution' line"
else
    echo ""
    echo "✅ All static campaigns are already configured!"
fi

echo ""
echo "🎯 Summary:"
echo "   Total static campaigns: ${#static_campaigns[@]}"
echo "   Already configured: ${#existing[@]}"  
echo "   Need configuration: ${#new_campaigns[@]}"

if [[ ${#new_campaigns[@]} -gt 0 ]]; then
    echo ""
    echo "🔗 URLs that will be available after configuration:"
    for campaign in "${new_campaigns[@]}"; do
        echo "   https://devpayload.southeastasia.cloudapp.azure.com/$campaign/"
    done
fi