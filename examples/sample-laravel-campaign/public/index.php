<?php
/**
 * Sample Laravel Campaign Structure
 * This demonstrates a Laravel campaign that will be IGNORED by auto-deployment
 * (Requires manual nginx configuration)
 */
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sample Laravel Campaign</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%);
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
        .badge {
            background: #e74c3c;
            color: white;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 14px;
            display: inline-block;
            margin-bottom: 20px;
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
        <div class="badge">⚠️ Manual Configuration Required</div>
        <h1>Sample Laravel Campaign</h1>
        <p>This is a Laravel-style campaign structure that will be <strong>ignored</strong> by the auto-deployment system.</p>

        <h3>📂 Laravel Structure:</h3>
        <div class="code">
            <pre>sample-laravel-campaign/
├── public/
│   └── index.php      ← Laravel indicator (causes auto-ignore)
├── app/
│   ├── Controllers/
│   ├── Models/
│   └── Views/
├── routes/
│   └── web.php
├── config/
├── database/
└── composer.json</pre>
        </div>

        <h3>🔍 Detection Logic:</h3>
        <ul>
            <li>✅ Auto-deployment detects <code>public/index.php</code></li>
            <li>🚫 Recognizes this as Laravel structure</li>
            <li>⏭️ Skips auto-configuration</li>
            <li>📝 Requires manual nginx setup</li>
        </ul>

        <h3>⚙️ Manual Configuration Needed:</h3>
        <div class="code">
            <pre># Add to nginx config manually:
location ^~ /sample-laravel-campaign/ {
    root /path/to/campaigns/sample-laravel-campaign/public;
    try_files $uri $uri/ /index.php?$query_string;
    
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.4-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $request_filename;
    }
}</pre>
        </div>

        <p><strong>Why Manual?</strong> Laravel campaigns require sophisticated routing, middleware, and framework bootstrapping that can't be generically auto-configured.</p>
    </div>
</body>
</html>