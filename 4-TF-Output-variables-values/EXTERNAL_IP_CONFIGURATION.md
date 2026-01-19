# External IP Configuration in Terraform

## The Question: Why External IP in This Project But Not Previous One?

This document explains the key difference between the VM instance configurations in:
- **Project 3** (3-TF-firewall-vminstance): No external IP
- **Project 4** (4-TF-Output-variables-values): Has external IP

---

## The Key Difference: `access_config` Block

### ❌ Previous Configuration (3-TF-firewall-vminstance)

```terraform
resource "google_compute_instance" "tech-instance" {
  name         = "tech-instance"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  tags        = ["ssh-tag","webserver-tag"]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }
  metadata_startup_script = file("${path.module}/startup-script.sh")
  network_interface {
    subnetwork = google_compute_subnetwork.techsubnet.id 
    # ← NO access_config block
  }
}
```

**Result**: VM only gets a **PRIVATE IP**
- Private IP: `10.128.x.x` (from CIDR range 10.128.0.0/20)
- **No external/public IP**
- Cannot be accessed from the internet
- Only accessible from within the VPC

---

### ✅ Current Configuration (4-TF-Output-variables-values)

```terraform
resource "google_compute_instance" "tech-instance" {
  name         = "tech-instance"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  tags        = ["ssh-tag","webserver-tag"]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }
  metadata_startup_script = file("${path.module}/startup-script.sh")
  network_interface {
    subnetwork = google_compute_subnetwork.techsubnet.id 
    access_config {
      # Include this section to give the VM an external IP address
    }
  }
}
```

**Result**: VM gets **BOTH PRIVATE AND PUBLIC IP**
- Private IP: `10.128.x.x` (internal to VPC)
- **External/Public IP: `34.xxx.xxx.xxx` (publicly accessible)**
- Can be accessed from the internet
- Allows SSH, HTTP, and HTTPS access from anywhere

---

## What is `access_config`?

The `access_config` block in the `network_interface` configuration tells Terraform to:

1. **Allocate a public IP address** from GCP's IP pool
2. **Create a NAT mapping** (Network Address Translation)
   - External IP ↔ Private IP
3. **Enable internet connectivity** to the VM
4. **Allow inbound traffic** from the internet to reach the VM

### Syntax

```terraform
network_interface {
  subnetwork = google_compute_subnetwork.techsubnet.id 
  
  access_config {
    # Empty block = automatic ephemeral IP
    # OR specify a static IP:
    # nat_ip = "35.xxx.xxx.xxx"
  }
}
```

---

## Network Architecture Comparison

### Without `access_config`:
```
Internet
   ↓
[Firewall Rules]
   ✗ BLOCKED (no external IP)
   
Inside VPC:
┌─────────────────────────┐
│   google_compute_network│
│        (techvpc1)       │
│                         │
│ ┌─────────────────────┐ │
│ │ Subnet: tech-subnet │ │
│ │ (10.128.0.0/20)     │ │
│ │                     │ │
│ │ ┌─────────────────┐ │ │
│ │ │  tech-instance  │ │ │
│ │ │ Private: 10.x.x │ │ │ ← Only this IP exists
│ │ │ External: NONE  │ │ │
│ │ └─────────────────┘ │ │
│ └─────────────────────┘ │
└─────────────────────────┘
    ↑
    Internal traffic only
```

### With `access_config`:
```
Internet
   ↓
[Firewall Rules]
   ✓ ALLOWED (traffic reaches public IP)
   ↓
┌──────────────────────────┐
│  External IP: 34.xxx.xxx │ ← Traffic enters here
└──────────────────────────┘
         ↓ (NAT)
┌──────────────────────────────┐
│   google_compute_network     │
│        (techvpc1)            │
│                              │
│ ┌────────────────────────┐   │
│ │ Subnet: tech-subnet    │   │
│ │ (10.128.0.0/20)        │   │
│ │                        │   │
│ │ ┌──────────────────┐   │   │
│ │ │  tech-instance   │   │   │
│ │ │ Private: 10.x.x  │   │   │ ← Traffic forwarded here
│ │ │ External: 34.x.x │   │   │ ← Accessible from internet
│ │ └──────────────────┘   │   │
│ └────────────────────────┘   │
└──────────────────────────────┘
    ↑ (Both internal & external)
```

---

## Why Both Configurations Exist

### Use Case 1: Internal Services (No External IP)
**When to use**: Databases, internal APIs, microservices

```terraform
network_interface {
  subnetwork = google_compute_subnetwork.techsubnet.id 
  # NO access_config
}
```

**Benefits**:
- More secure (not accessible from internet)
- Lower cost (no public IP allocation)
- Can still communicate with other VMs
- Accessed through Cloud VPN or Cloud IAP

**Example**: MySQL database server, Kubernetes internal service

---

### Use Case 2: Public Services (With External IP)
**When to use**: Web servers, load balancers, APIs for customers

```terraform
network_interface {
  subnetwork = google_compute_subnetwork.techsubnet.id 
  access_config {
    # Allocate public IP
  }
}
```

**Benefits**:
- Accessible from anywhere on internet
- Users can SSH, access web server, API
- Firewall rules work with external traffic

**Example**: Web server (Nginx), SSH jump host, API endpoint

---

## Our Project Needs External IP Because:

1. **Has web server (Nginx)**: Needs to serve web pages to users on the internet
2. **Has SSH access**: Administrators need to SSH in for management
3. **Has firewall rules for ports 22 and 80**: These rules only work if there's an external IP to receive traffic

---

## Practical Example: What Actually Happens

### Scenario 1: Without `access_config`

```bash
# User tries to access the web server
$ curl http://34.123.45.67
# ❌ Connection refused
# Reason: VM doesn't have external IP

# User tries SSH
$ ssh user@34.123.45.67
# ❌ Connection refused
# Reason: VM doesn't have external IP
```

### Scenario 2: With `access_config`

```bash
# After deployment, you get output:
# tech-instance_external_ip = "34.123.45.67"

# User accesses the web server
$ curl http://34.123.45.67
# ✅ Returns HTML from Nginx
# Reason: External IP + Firewall rule for port 80 + Nginx running

# User SSH to server
$ ssh user@34.123.45.67
# ✅ Connected!
# Reason: External IP + Firewall rule for port 22 + SSH daemon running
```

---

## How to Enable External IP

### Option 1: Empty `access_config` (What We Use)
Assigns an **ephemeral IP** (changes on reboot):

```terraform
network_interface {
  subnetwork = google_compute_subnetwork.techsubnet.id 
  access_config {
    # Empty = automatic ephemeral IP
  }
}
```

### Option 2: Static IP (Permanent)
Assigns a **static IP** (persists through reboots):

```terraform
network_interface {
  subnetwork = google_compute_subnetwork.techsubnet.id 
  access_config {
    nat_ip = "35.192.192.192"  # Pre-allocated static IP
  }
}
```

### Option 3: Automatic Static IP
Terraform assigns a static IP from a pool:

```terraform
# First reserve static IP resource
resource "google_compute_address" "static_ip" {
  name   = "tech-static-ip"
  region = "us-central1"
}

# Then use it
network_interface {
  subnetwork = google_compute_subnetwork.techsubnet.id 
  access_config {
    nat_ip = google_compute_address.static_ip.address
  }
}
```

---

## How to Get External IP in Outputs

With `access_config` enabled, you can extract the external IP:

```terraform
output "tech-instance_external_ip" {
  description = "VM External IP"
  value = google_compute_instance.tech-instance.network_interface[0].access_config[0].nat_ip
}
```

**Breaking it down**:
- `google_compute_instance.tech-instance` → The instance resource
- `.network_interface[0]` → First network interface (index 0)
- `.access_config[0]` → First access config (index 0)
- `.nat_ip` → The public/external IP address

**Without `access_config`**: This output would fail because `.access_config[0]` doesn't exist!

---

## Summary Table

| Feature | Without `access_config` | With `access_config` |
|---------|-------------------------|----------------------|
| Private IP | ✅ Yes (10.128.x.x) | ✅ Yes (10.128.x.x) |
| External IP | ❌ No | ✅ Yes (34.x.x.x) |
| Internet Access | ❌ No | ✅ Yes |
| SSH from internet | ❌ No | ✅ Yes |
| Web access | ❌ No | ✅ Yes |
| Cost | Lower | Slightly higher |
| Security | Higher (isolated) | Standard (firewalled) |
| Use Case | Internal services | Public services |

---

