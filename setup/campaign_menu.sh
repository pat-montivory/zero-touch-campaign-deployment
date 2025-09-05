#!/bin/bash

# Campaign Menu - Simplified Interactive Interface for Consolidated Scripts
# Replaces the complex 18-script menu with 6 core consolidated tools

SCRIPT_DIR="/var/www/campaignmanagerv12/scripts"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🚀 Campaign Manager - Consolidated Menu${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Core Scripts
echo -e "${GREEN}📋 CORE MANAGEMENT:${NC}"
echo " 1) campaign_manager.sh detect    - Detect available campaigns"
echo " 2) campaign_manager.sh deploy    - Deploy campaigns with config"
echo " 3) campaign_manager.sh status    - Show campaign status"
echo " 4) campaign_manager.sh list      - List all campaigns"
echo ""

# Configuration Management
echo -e "${YELLOW}⚙️  CONFIGURATION:${NC}"
echo " 5) campaign_config.sh generate   - Generate nginx configuration"
echo " 6) campaign_config.sh test       - Test nginx configuration"
echo " 7) campaign_config.sh reload     - Reload nginx service"
echo " 8) campaign_config.sh backup     - Backup configuration"
echo ""

# Service Control
echo -e "${PURPLE}🔧 SERVICE CONTROL:${NC}"
echo " 9) campaign_control.sh           - Campaign service control"
echo "10) campaign_monitor.sh           - Background monitoring"
echo "11) campaign_installer.sh         - Install/setup services"
echo ""

# Advanced Options
echo -e "${CYAN}⚡ ADVANCED:${NC}"
echo "12) campaign_manager.sh deploy --separate-config - Deploy with separate configs"
echo "13) campaign_config.sh clean     - Remove all campaign configs"
echo "14) campaign_manager.sh backup   - Backup current setup"
echo ""

# Legacy & Development
echo -e "${BLUE}🔄 LEGACY (Old Scripts):${NC}"
echo "15) Show old scripts menu         - Access original 18 scripts"
echo ""

echo -e "${RED}99) Exit${NC}"
echo ""

# Get user input
read -p "$(echo -e ${GREEN}Enter your choice [1-15, 99]:${NC} )" choice

case $choice in
    1)
        echo -e "${GREEN}🔍 Detecting campaigns...${NC}"
        ./campaign_manager.sh detect --verbose
        ;;
    2)
        echo -e "${GREEN}🚀 Deploying campaigns...${NC}"
        ./campaign_manager.sh deploy
        ;;
    3)
        echo -e "${GREEN}📊 Checking campaign status...${NC}"
        ./campaign_manager.sh status
        ;;
    4)
        echo -e "${GREEN}📋 Listing campaigns...${NC}"
        ./campaign_manager.sh list
        ;;
    5)
        echo -e "${YELLOW}⚙️ Generating nginx configuration...${NC}"
        ./campaign_config.sh generate
        ;;
    6)
        echo -e "${YELLOW}🧪 Testing nginx configuration...${NC}"
        ./campaign_config.sh test
        ;;
    7)
        echo -e "${YELLOW}🔄 Reloading nginx...${NC}"
        ./campaign_config.sh reload
        ;;
    8)
        echo -e "${YELLOW}💾 Backing up configuration...${NC}"
        ./campaign_config.sh backup
        ;;
    9)
        echo -e "${PURPLE}🔧 Opening campaign control...${NC}"
        ./campaign_control.sh
        ;;
    10)
        echo -e "${PURPLE}👁️ Starting campaign monitor...${NC}"
        ./campaign_monitor.sh
        ;;
    11)
        echo -e "${PURPLE}📦 Running campaign installer...${NC}"
        ./campaign_installer.sh
        ;;
    12)
        echo -e "${CYAN}⚡ Deploying with separate configs...${NC}"
        ./campaign_manager.sh deploy --separate-config
        ;;
    13)
        echo -e "${CYAN}🗑️ Cleaning campaign configurations...${NC}"
        ./campaign_config.sh clean
        ;;
    14)
        echo -e "${CYAN}💾 Creating full backup...${NC}"
        ./campaign_manager.sh backup
        ;;
    15)
        echo -e "${BLUE}📜 Showing legacy scripts...${NC}"
        ./menu.sh
        ;;
    99)
        echo -e "${RED}👋 Exiting...${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Invalid choice. Please try again.${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✅ Operation completed.${NC}"
echo ""

# Ask if user wants to return to menu
read -p "$(echo -e ${BLUE}Return to menu? [y/N]:${NC} )" -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    exec $0
fi