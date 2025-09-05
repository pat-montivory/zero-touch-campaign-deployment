/**
 * Sample Static Campaign JavaScript
 * Demonstrates interactive features for auto-deployed campaigns
 */

document.addEventListener('DOMContentLoaded', function() {
    console.log('🚀 Sample Static Campaign JavaScript loaded');
    
    // Initialize campaign features
    initializeCampaignStatus();
    setupInteractiveElements();
    displayDeploymentInfo();
});

/**
 * Initialize campaign status indicators
 */
function initializeCampaignStatus() {
    // Create status indicator
    const statusIndicator = document.createElement('div');
    statusIndicator.innerHTML = `
        <div style="
            position: fixed;
            top: 20px;
            right: 20px;
            background: rgba(40, 167, 69, 0.9);
            color: white;
            padding: 10px 15px;
            border-radius: 20px;
            font-size: 14px;
            z-index: 1000;
            backdrop-filter: blur(5px);
            animation: slideIn 0.5s ease-out;
        ">
            ✅ Auto-Deployed Successfully
        </div>
    `;
    
    document.body.appendChild(statusIndicator);
    
    // Add CSS animation
    const style = document.createElement('style');
    style.textContent = `
        @keyframes slideIn {
            from {
                transform: translateX(100%);
                opacity: 0;
            }
            to {
                transform: translateX(0);
                opacity: 1;
            }
        }
    `;
    document.head.appendChild(style);
    
    // Remove status indicator after 5 seconds
    setTimeout(() => {
        statusIndicator.style.animation = 'slideOut 0.5s ease-in forwards';
        setTimeout(() => statusIndicator.remove(), 500);
    }, 5000);
    
    // Add slideOut animation
    style.textContent += `
        @keyframes slideOut {
            from {
                transform: translateX(0);
                opacity: 1;
            }
            to {
                transform: translateX(100%);
                opacity: 0;
            }
        }
    `;
}

/**
 * Setup interactive elements
 */
function setupInteractiveElements() {
    // Add click handlers to info items
    const infoItems = document.querySelectorAll('.info-item');
    infoItems.forEach(item => {
        item.style.cursor = 'pointer';
        item.style.transition = 'transform 0.2s ease, box-shadow 0.2s ease';
        
        item.addEventListener('mouseenter', function() {
            this.style.transform = 'scale(1.02)';
            this.style.boxShadow = '0 10px 20px rgba(0,0,0,0.1)';
        });
        
        item.addEventListener('mouseleave', function() {
            this.style.transform = 'scale(1)';
            this.style.boxShadow = 'none';
        });
        
        item.addEventListener('click', function() {
            const title = this.querySelector('h3').textContent;
            showInfoModal(title, this.innerHTML);
        });
    });
    
    // Add copy button to code blocks
    const codeBlocks = document.querySelectorAll('.code, pre');
    codeBlocks.forEach(block => {
        const copyButton = document.createElement('button');
        copyButton.innerHTML = '📋 Copy';
        copyButton.style.cssText = `
            position: absolute;
            top: 10px;
            right: 10px;
            background: rgba(255,255,255,0.2);
            color: white;
            border: none;
            padding: 5px 10px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 12px;
        `;
        
        block.style.position = 'relative';
        block.appendChild(copyButton);
        
        copyButton.addEventListener('click', () => {
            navigator.clipboard.writeText(block.textContent.replace('📋 Copy', ''));
            copyButton.innerHTML = '✅ Copied!';
            setTimeout(() => copyButton.innerHTML = '📋 Copy', 2000);
        });
    });
}

/**
 * Display deployment information
 */
function displayDeploymentInfo() {
    // Add deployment statistics
    const deploymentStats = {
        detectionTime: '< 30 seconds',
        configGeneration: '< 5 seconds',
        nginxReload: '< 2 seconds',
        totalDeployTime: '< 37 seconds'
    };
    
    // Create floating info panel
    const infoPanel = document.createElement('div');
    infoPanel.id = 'deployment-info';
    infoPanel.innerHTML = `
        <div style="
            position: fixed;
            bottom: 20px;
            left: 20px;
            background: rgba(0,0,0,0.8);
            color: white;
            padding: 15px;
            border-radius: 10px;
            font-size: 12px;
            max-width: 250px;
            z-index: 999;
            backdrop-filter: blur(5px);
            transform: translateY(100%);
            transition: transform 0.3s ease;
        ">
            <h4 style="margin: 0 0 10px 0; color: #90EE90;">⚡ Deployment Stats</h4>
            <div>Detection: ${deploymentStats.detectionTime}</div>
            <div>Config Gen: ${deploymentStats.configGeneration}</div>
            <div>Nginx Reload: ${deploymentStats.nginxReload}</div>
            <div style="border-top: 1px solid #333; margin-top: 8px; padding-top: 8px; font-weight: bold;">
                Total: ${deploymentStats.totalDeployTime}
            </div>
            <button onclick="this.parentElement.style.transform='translateY(100%)'" 
                    style="position: absolute; top: 5px; right: 8px; background: none; border: none; color: white; cursor: pointer;">×</button>
        </div>
    `;
    
    document.body.appendChild(infoPanel);
    
    // Show panel after 3 seconds
    setTimeout(() => {
        infoPanel.firstElementChild.style.transform = 'translateY(0)';
    }, 3000);
}

/**
 * Show information modal
 */
function showInfoModal(title, content) {
    const modal = document.createElement('div');
    modal.innerHTML = `
        <div style="
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.8);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 10000;
            animation: fadeIn 0.3s ease;
        " onclick="this.remove()">
            <div style="
                background: white;
                padding: 30px;
                border-radius: 15px;
                max-width: 500px;
                width: 90%;
                max-height: 80%;
                overflow: auto;
                position: relative;
            " onclick="event.stopPropagation()">
                <button onclick="this.closest('[style*=\"position: fixed\"]').remove()" 
                        style="position: absolute; top: 15px; right: 15px; background: none; border: none; font-size: 20px; cursor: pointer;">×</button>
                <h2 style="color: #333; margin-bottom: 20px;">${title}</h2>
                <div style="color: #666; line-height: 1.6;">${content}</div>
            </div>
        </div>
    `;
    
    document.body.appendChild(modal);
    
    // Add fade animation
    const fadeStyle = document.createElement('style');
    fadeStyle.textContent = `
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
    `;
    document.head.appendChild(fadeStyle);
}

/**
 * Campaign-specific functionality
 */
const CampaignManager = {
    // Track page views
    trackView: function() {
        const viewData = {
            timestamp: new Date().toISOString(),
            url: window.location.href,
            userAgent: navigator.userAgent,
            referrer: document.referrer
        };
        
        console.log('📊 Campaign view tracked:', viewData);
        // In a real campaign, this would send data to analytics
    },
    
    // Handle form submissions (if any)
    handleForm: function(formElement) {
        formElement.addEventListener('submit', function(e) {
            e.preventDefault();
            console.log('📝 Form submitted:', new FormData(this));
            // Handle form data
        });
    },
    
    // Social sharing functionality
    share: function(platform, url = window.location.href) {
        const shareUrls = {
            facebook: `https://facebook.com/sharer/sharer.php?u=${encodeURIComponent(url)}`,
            twitter: `https://twitter.com/intent/tweet?url=${encodeURIComponent(url)}&text=Check out this auto-deployed campaign!`,
            linkedin: `https://linkedin.com/sharing/share-offsite/?url=${encodeURIComponent(url)}`
        };
        
        if (shareUrls[platform]) {
            window.open(shareUrls[platform], '_blank', 'width=600,height=400');
        }
    }
};

// Initialize campaign tracking
CampaignManager.trackView();

// Global utilities
window.CampaignUtils = {
    // Test campaign connectivity
    testConnectivity: async function() {
        try {
            const response = await fetch(window.location.href);
            const status = response.ok ? '✅ Online' : '⚠️ Issues detected';
            console.log('🌐 Campaign connectivity:', status);
            return response.ok;
        } catch (error) {
            console.error('❌ Campaign connectivity error:', error);
            return false;
        }
    },
    
    // Get campaign info
    getCampaignInfo: function() {
        return {
            name: document.title,
            url: window.location.href,
            deploymentType: 'Zero-Touch Static',
            status: 'Active',
            lastModified: document.lastModified
        };
    },
    
    // Debug mode
    enableDebug: function() {
        document.body.style.outline = '2px dashed #ff0000';
        console.log('🐛 Debug mode enabled for campaign');
        
        // Show all clickable elements
        document.querySelectorAll('a, button, [onclick]').forEach(el => {
            el.style.outline = '1px solid #00ff00';
        });
    }
};

console.log('✅ Campaign JavaScript initialization complete');
console.log('🔧 Available utilities:', Object.keys(window.CampaignUtils));