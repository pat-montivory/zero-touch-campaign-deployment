#!/bin/bash

CAMPAIGNS_DIR="/home/azureuser/dev/campaignmanagerv12/campaigns"

echo "=== Testing Campaign Detection ==="
echo ""

echo "📁 Campaigns directory contents:"
ls -la "$CAMPAIGNS_DIR"
echo ""

echo "🔍 Checking each directory:"
for dir in "$CAMPAIGNS_DIR"/*; do
    if [[ -d "$dir" ]]; then
        campaign_name=$(basename "$dir")
        echo "  📂 $campaign_name:"
        
        if [[ -f "$dir/index.php" ]]; then
            echo "      ✅ Has index.php"
        else
            echo "      ❌ No index.php"
        fi
        
        if [[ -f "$dir/public/index.php" ]]; then
            echo "      ✅ Has public/index.php (Laravel)"
        else
            echo "      ❌ No public/index.php"
        fi
        
        # Determine type
        if [[ -f "$dir/index.php" && ! -f "$dir/public/index.php" ]]; then
            echo "      🎯 TYPE: Static Campaign"
        elif [[ -f "$dir/public/index.php" ]]; then
            echo "      🎯 TYPE: Laravel Campaign"  
        else
            echo "      🎯 TYPE: Unknown/Not a campaign"
        fi
        echo ""
    fi
done