#!/bin/bash
sudo apt update
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -I | awk '{print $1}')

sudo tee /var/www/html/index.html > /dev/null <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Welcome</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
            text-align: center;
            max-width: 500px;
        }
        h1 { color: #333; margin-bottom: 30px; font-size: 2.5em; }
        p { color: #666; margin: 15px 0; font-size: 1.1em; }
        strong { color: #667eea; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Web Server (depends_on)</h1>
        <p><strong>Hostname:</strong> $HOSTNAME</p>
        <p><strong>IP Address:</strong> $IP_ADDRESS</p>
    </div>
</body>
</html>
EOF
