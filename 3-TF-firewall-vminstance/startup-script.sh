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
        body { background-color: rgb(250, 210, 210); font-family: Arial; }
    </style>
</head>
<body>
    <h1>Welcome to Web Server</h1>
    <p><strong>Hostname:</strong> $HOSTNAME</p>
    <p><strong>IP Address:</strong> $IP_ADDRESS</p>
</body>
</html>
EOF