#!/bin/bash
apt-get update
apt-get install -y nginx

# Create custom HTML page
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
  <head>
    <title>Web Server (lifecycle)</title>
    <style>
      body { font-family: Arial; margin: 40px; }
      .info { background: #f0f0f0; padding: 20px; border-radius: 5px; }
    </style>
  </head>
  <body>
    <h1>🎯 Web Server with Lifecycle Meta-Argument</h1>
    <div class="info">
      <p><strong>Server Name:</strong> <span id="hostname"></span></p>
      <p><strong>Server Time:</strong> <span id="time"></span></p>
      <p><strong>Terraform Meta-Argument:</strong> lifecycle</p>
      <p style="color: green;"><strong>Status:</strong> ✅ Running with lifecycle configuration</p>
    </div>
    
    <h2>Lifecycle Features in This Instance:</h2>
    <ul>
      <li><code>create_before_destroy = true</code> - Zero-downtime updates</li>
      <li><code>ignore_changes = [metadata["instance_version"]]</code> - Don't update on version changes</li>
      <li>Provisioners log creation and destruction events</li>
    </ul>

    <script>
      document.getElementById('hostname').textContent = window.location.hostname;
      setInterval(() => {
        document.getElementById('time').textContent = new Date();
      }, 1000);
    </script>
  </body>
</html>
EOF

systemctl restart nginx
