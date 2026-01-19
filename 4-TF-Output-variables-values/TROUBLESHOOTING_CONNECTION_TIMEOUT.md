# Troubleshooting: External IP Exists But Web Page Not Opening

## The Error
```
This site can't be reached
34.42.234.20 took too long to respond.
ERR_CONNECTION_TIMED_OUT
```

**What this means**: Your external IP is allocated and reachable, but traffic to port 80 (HTTP) is being blocked or the web server isn't responding.

---

## Quick Checklist (Try These First)

- [ ] **Wait 3-5 minutes** - Startup script might still be running
- [ ] **Try with HTTP** - Not HTTPS: `http://34.42.234.20` (not https://)
- [ ] **Check tags on VM** - Must have `webserver-tag` for HTTP firewall rule
- [ ] **Verify firewall rules exist** - Both SSH and HTTP rules should be created

---

## Step-by-Step Troubleshooting

### Step 1: Wait for Startup Script to Complete (Most Common Issue)

When your VM first boots, the startup script runs automatically. This takes **2-5 minutes** to:
1. Update package lists (`apt update`)
2. Install Nginx (`apt install -y nginx`)
3. Start Nginx service (`systemctl start nginx`)
4. Create the welcome page

**What to do**:
- Wait 3-5 minutes after applying Terraform
- Then try accessing the IP again

**How to check if it's done**:
Open GCP Console → Compute Engine → Instances → Click your instance → Scroll to "Serial port 1 (console)" and check if it finished

---

### Step 2: Verify Firewall Rules Are Created

Check if the HTTP and SSH firewall rules were actually created:

```bash
# List all firewall rules in your project
gcloud compute firewall-rules list

# You should see:
# tech-fw-allow-http80    (allows port 80)
# tech-fw-allow-ssh22     (allows port 22)
```

**If they're missing**:
```bash
# Re-apply Terraform to create them
terraform apply
```

---

### Step 3: Check If Tags Match Firewall Rules

**Firewall rules target instances using TAGS**.

Your setup has:
- **Firewall rule for HTTP**: targets instances with tag `webserver-tag`
- **Firewall rule for SSH**: targets instances with tag `ssh-tag`

**Check if VM has the tags**:

```bash
# Go to GCP Console → Compute Engine → Instances
# Click your VM (tech-instance)
# Look for "Network tags" section - should show:
# - ssh-tag
# - webserver-tag
```

**If tags are missing**:
```bash
# Add tags via gcloud
gcloud compute instances add-tags tech-instance \
  --tags=ssh-tag,webserver-tag \
  --zone=us-central1-a
```

---

### Step 4: Verify HTTP Firewall Rule Details

Check the actual firewall rule configuration:

```bash
gcloud compute firewall-rules describe tech-fw-allow-http80
```

**Output should show**:
```
name: tech-fw-allow-http80
network: projects/terraform-project-484318/global/networks/techvpc1
priority: 1000
sourceRanges:
- 0.0.0.0/0
allowed:
- ports:
  - '80'
  protocol: tcp
direction: INGRESS
sourceServiceAccounts: []
targetTags:
- webserver-tag
```

**Common issues**:
- ❌ `targetTags` is empty → Rule doesn't know which VMs to apply to
- ❌ `sourceRanges` is not `0.0.0.0/0` → Rule doesn't allow all IPs
- ❌ Port is not `80` → Wrong port configured

---

### Step 5: Check Network Interface Configuration

Your VM must have `access_config` block (public IP):

```bash
# Check in Terraform file (t5-vminstance.tf)
# Should have:
network_interface {
  subnetwork = google_compute_subnetwork.techsubnet.id 
  access_config {
    # This enables external IP
  }
}
```

If missing, add it:
```terraform
network_interface {
  subnetwork = google_compute_subnetwork.techsubnet.id 
  access_config {
    # Allocate public IP
  }
}
```

Then:
```bash
terraform apply
```

---

### Step 6: SSH Into VM and Check Nginx Status

This is the **best way to diagnose**:

```bash
# SSH into your VM
gcloud compute ssh tech-instance --zone=us-central1-a

# Inside the VM, check if Nginx is running
sudo systemctl status nginx

# Output should show:
# ● nginx.service - A high performance web server and a reverse proxy server
#    Loaded: loaded (/lib/systemd/nginx.service; enabled; vendor preset: enabled)
#    Active: active (running)
```

**If NOT running**:
```bash
# Start Nginx
sudo systemctl start nginx

# Check the web page
curl http://localhost
# Should return HTML content
```

**If startup script didn't run**:
```bash
# Check if the file exists
ls -la /var/www/html/index.html

# If missing, run startup commands manually
sudo apt update
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Create welcome page
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
```

**If all working in SSH**:
```bash
curl http://localhost
# Returns HTML ✅
```

But browser can't reach it → **Firewall issue** (go to Step 4)

---

### Step 7: Test Connectivity with SSH First

SSH uses **port 22** which should also be firewalled. If SSH doesn't work either:

```bash
# Try to SSH
gcloud compute ssh tech-instance --zone=us-central1-a
# Connection refused?
```

**If SSH fails**:
- Check SSH firewall rule (`tech-fw-allow-ssh22`)
- Check if `ssh-tag` is on the VM
- Follow Step 4 & 5 above

**If SSH works but HTTP doesn't**:
- Both traffic must pass through firewall
- Nginx might not be running
- Do Step 6 above

---

## Common Solutions Summary

### Issue 1: "Waiting for Nginx Installation"
**Symptom**: Just created VM, tried immediately to access
**Solution**: **Wait 3-5 minutes** for startup script to complete
```bash
# Check startup script progress in GCP Console
# Compute Engine → Instances → Click VM → Scroll to Serial port 1
```

---

### Issue 2: "Firewall Rules Blocking Traffic"
**Symptom**: VM has external IP, but connection times out
**Solution**: Ensure firewall rules are created and targeting your VM
```bash
# Re-apply Terraform
terraform apply

# Or manually verify
gcloud compute firewall-rules describe tech-fw-allow-http80
```

---

### Issue 3: "VM Tags Missing"
**Symptom**: Firewall rules exist but traffic still blocked
**Solution**: Add tags to match firewall rule targets
```bash
gcloud compute instances add-tags tech-instance \
  --tags=ssh-tag,webserver-tag \
  --zone=us-central1-a
```

---

### Issue 4: "No access_config Block"
**Symptom**: No external IP shown, can't reach from internet
**Solution**: Add `access_config` to network_interface in `t5-vminstance.tf`
```terraform
network_interface {
  subnetwork = google_compute_subnetwork.techsubnet.id 
  access_config {
    # Allocate public IP
  }
}
```

---

### Issue 5: "Nginx Didn't Install"
**Symptom**: SSH into VM works, but no web page
**Solution**: Manually install Nginx (see Step 6)

---

## Complete Diagnostic Command

Run this script to check everything:

```bash
#!/bin/bash
echo "=== Checking VM ==="
gcloud compute instances describe tech-instance --zone=us-central1-a | grep -E "name:|status:|tags:"

echo -e "\n=== Checking External IP ==="
gcloud compute instances describe tech-instance --zone=us-central1-a | grep -A 5 "networkInterfaces"

echo -e "\n=== Checking HTTP Firewall Rule ==="
gcloud compute firewall-rules describe tech-fw-allow-http80 2>/dev/null || echo "Firewall rule not found!"

echo -e "\n=== Checking SSH Firewall Rule ==="
gcloud compute firewall-rules describe tech-fw-allow-ssh22 2>/dev/null || echo "Firewall rule not found!"

echo -e "\n=== Trying SSH to check Nginx ==="
gcloud compute ssh tech-instance --zone=us-central1-a \
  --command="sudo systemctl status nginx" 2>/dev/null || echo "SSH failed!"
```

---

## Expected Result After Fix

```bash
# From your browser
$ curl http://34.42.234.20

<!DOCTYPE html>
<html>
<head>
    <title>Welcome</title>
    ...
</head>
<body>
    <h1>Welcome to Web Server</h1>
    <p><strong>Hostname:</strong> tech-instance</p>
    <p><strong>IP Address:</strong> 10.128.0.2</p>
</body>
</html>

# ✅ Success!
```

---

## Common Port Issues

If you changed the port or configuration:

| Service | Port | Protocol | Firewall Rule |
|---------|------|----------|---------------|
| HTTP | 80 | TCP | `tech-fw-allow-http80` |
| HTTPS | 443 | TCP | Need separate rule |
| SSH | 22 | TCP | `tech-fw-allow-ssh22` |

---

## Still Not Working?

Try these in order:

1. **Wait longer** - Startup script can take up to 10 minutes
2. **Check GCP Console** - Compute Engine → Instances → Click your instance
3. **SSH into VM** - Run `sudo systemctl status nginx`
4. **Re-apply Terraform** - `terraform apply` (recreates resources)
5. **Check project ID** - Make sure using correct GCP project
6. **Check firewall rules** - In GCP Console → VPC Network → Firewall Rules

---

## Most Likely Fix

Based on the error, **try this first**:

```bash
# 1. Wait 5 minutes (if just created)

# 2. SSH in and verify Nginx
gcloud compute ssh tech-instance --zone=us-central1-a
sudo systemctl status nginx
sudo systemctl start nginx  # if not running
exit

# 3. Try accessing again
# http://34.42.234.20

# 4. If still not working, re-apply Terraform
terraform apply
```

**Most of the time, it's just the startup script still running!** ⏱️
