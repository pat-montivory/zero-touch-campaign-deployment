<?php
/**
 * Sample Static Campaign
 * This demonstrates a typical static campaign structure
 * that will be automatically detected and deployed
 */

// Basic campaign info
$campaignName = "Sample Static Campaign";
$deployedAt = date('Y-m-d H:i:s');
$campaignUrl = "https://" . $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI'];

// Simple campaign HTML
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo $campaignName; ?></title>
    <link rel="stylesheet" href="assets/css/style.css">
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
        }
        .container {
            background: rgba(255,255,255,0.1);
            padding: 30px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .badge {
            background: #28a745;
            color: white;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 14px;
            display: inline-block;
            margin-bottom: 20px;
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-top: 30px;
        }
        .info-item {
            background: rgba(255,255,255,0.1);
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #28a745;
        }
        .code {
            background: rgba(0,0,0,0.3);
            padding: 15px;
            border-radius: 8px;
            font-family: 'Courier New', monospace;
            margin: 15px 0;
            overflow-x: auto;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="badge">✅ Auto-Deployed!</div>
            <h1><?php echo $campaignName; ?></h1>
            <p>This campaign was automatically detected and configured by the Zero-Touch Deployment System</p>
        </div>

        <div class="info-grid">
            <div class="info-item">
                <h3>📅 Deployment Info</h3>
                <p><strong>Deployed:</strong> <?php echo $deployedAt; ?></p>
                <p><strong>URL:</strong> <br><small><?php echo $campaignUrl; ?></small></p>
            </div>
            
            <div class="info-item">
                <h3>🎯 Campaign Type</h3>
                <p><strong>Type:</strong> Static PHP Campaign</p>
                <p><strong>Detection:</strong> Automatic</p>
                <p><strong>Configuration:</strong> Zero-touch</p>
            </div>
            
            <div class="info-item">
                <h3>📊 System Status</h3>
                <p><strong>PHP Version:</strong> <?php echo phpversion(); ?></p>
                <p><strong>Server:</strong> <?php echo $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown'; ?></p>
                <p><strong>Method:</strong> <?php echo $_SERVER['REQUEST_METHOD']; ?></p>
            </div>
            
            <div class="info-item">
                <h3>🔗 Available Assets</h3>
                <p><a href="assets/css/style.css" style="color: #90EE90;">CSS Files</a></p>
                <p><a href="assets/js/script.js" style="color: #90EE90;">JavaScript Files</a></p>
                <p><a href="assets/images/" style="color: #90EE90;">Images</a></p>
            </div>
        </div>

        <div class="code">
            <h3>📂 Campaign Structure:</h3>
            <pre>sample-static-campaign/
├── index.php          ← Main file (you are here!)
├── assets/
│   ├── css/
│   │   └── style.css
│   ├── js/
│   │   └── script.js
│   └── images/
│       └── banner.jpg
├── data.php           ← Additional PHP files
└── contact.php        ← More pages</pre>
        </div>

        <div style="text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid rgba(255,255,255,0.2);">
            <h3>🎉 Campaign Successfully Deployed!</h3>
            <p>This demonstrates how the Zero-Touch Deployment System automatically:</p>
            <ul style="text-align: left; max-width: 500px; margin: 0 auto;">
                <li>✅ Detected this static campaign</li>
                <li>✅ Generated nginx configuration</li>
                <li>✅ Updated and reloaded nginx</li>
                <li>✅ Made this URL instantly available</li>
            </ul>
        </div>
    </div>
    
    <script src="assets/js/script.js"></script>
</body>
</html>