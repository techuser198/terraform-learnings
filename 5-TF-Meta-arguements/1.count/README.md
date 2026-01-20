# Terraform Meta-Arguments: Understanding `count`

This Topic demonstrates the **`count` meta-argument** in Terraform. Instead of creating one VM instance, we use `count` to create **multiple instances with a single resource block**.

---

## Prerequisites & References

This project builds on concepts from earlier modules. For background information, please refer to:
- **VPC & Firewall**: See `3-TF-firewall-vminstance/README.md`
- **VM Instances**: See `3-TF-firewall-vminstance/README.md`
- **Terraform Variables & Precedence**: See `4-TF-Output-variables-values/README.md`
- **Output Values**: See `4-TF-Output-variables-values/README.md`

This module focuses on **Meta-Arguments** and specifically the **`count` meta-argument**.

---

## Part 1: What is a Meta-Argument?

### Definition

A **meta-argument** is a special Terraform argument that changes **how** a resource is created, rather than **what configuration** the resource has.

**Real-world analogy**: If resource arguments are like "ingredients in a recipe," meta-arguments are like "instructions on how many batches to make."

### Regular Arguments vs Meta-Arguments

```terraform
# Regular arguments - Configure the resource
resource "google_compute_instance" "my-vm" {
  name         = "my-server"      # Regular argument
  machine_type = "e2-micro"       # Regular argument
  zone         = "us-central1-a"  # Regular argument
}

# Meta-arguments - Control HOW resources are created
resource "google_compute_instance" "my-vm" {
  count = 3                        # Meta-argument: create 3 instances
  depends_on = [google_compute_network.vpc]  # Meta-argument: dependency
  for_each = var.instances         # Meta-argument: iterate over map
  provider = google.us-east1       # Meta-argument: use specific provider
  
  name = "server-${count.index}"   # Use meta-argument data
  machine_type = "e2-micro"
}
```

---

## Part 2: Understanding `count` Meta-Argument

### What is `count`?

The **`count` meta-argument** tells Terraform to create **multiple instances of the same resource**. Instead of writing the same resource block multiple times, you use `count` to generate them.

**Simple example**:

```terraform
# WITHOUT count - Must repeat code 3 times ❌
resource "google_compute_instance" "server1" {
  name = "server-1"
}
resource "google_compute_instance" "server2" {
  name = "server-2"
}
resource "google_compute_instance" "server3" {
  name = "server-3"
}

# WITH count - One block, creates 3 instances ✅
resource "google_compute_instance" "my-server" {
  count = 3
  name = "server-${count.index}"
}
```

### How `count` Works

#### Syntax

```terraform
resource "resource_type" "name" {
  count = number_of_instances    # How many to create
  
  # Reference count data
  property = "value-${count.index}"
}
```

#### Key Components

1. **`count = n`**: Creates n instances (n = 2, 3, 10, etc.)
2. **`count.index`**: Zero-based index (0, 1, 2, ...)
3. **Resource reference**: `resource_type.name[index]` or `resource_type.name[*]`

### Example: Creating 2 VM Instances

**In this project** (`t5-vminstance.tf`):

```terraform
resource "google_compute_instance" "tech-instance" {
  count = 2  # ← Creates 2 instances
  
  name         = "${var.machine_name}-${count.index}"  # tech-instance-0, tech-instance-1
  machine_type = var.machine_type
  zone         = "${var.gcp_region1}-a"
  tags        = ["ssh-tag","webserver-tag"]
  boot_disk {
    initialize_params {
      image = var.machine_image
    }
  }
  metadata_startup_script = file("${path.module}/startup-script.sh")
  network_interface {
    subnetwork = google_compute_subnetwork.techsubnet.id 
    access_config {
      # External IP for each instance
    }
  }
}
```

**What this creates**:

```
Iteration 0 (count.index = 0):
  - Instance name: tech-instance-0
  - Gets its own external IP
  - All other config same

Iteration 1 (count.index = 1):
  - Instance name: tech-instance-1
  - Gets its own external IP
  - All other config same
```

---

## Part 3: `count` Use Cases

### Use Case 1: Create Multiple Identical Instances

```terraform
# Create 3 web servers for load balancing
resource "google_compute_instance" "web-server" {
  count = 3
  name = "web-server-${count.index}"
  # ... all same config
}
```

**Benefits**:
- All servers identical (consistent configuration)
- Easy to scale (change `count = 3` to `count = 5`)
- DRY principle (Don't Repeat Yourself)

---

### Use Case 2: Conditional Resource Creation

```terraform
variable "enable_backup_server" {
  type = bool
  default = false
}

# Create server only if enabled
resource "google_compute_instance" "backup-server" {
  count = var.enable_backup_server ? 1 : 0  # 1 if true, 0 if false
  name = "backup-server"
}
```

**Benefits**:
- Create resources conditionally
- No need for separate modules

---

### Use Case 3: Dynamic Networks

```terraform
variable "subnet_count" {
  default = 3  # Create 3 subnets
}

resource "google_compute_subnetwork" "subnets" {
  count = var.subnet_count
  name = "subnet-${count.index}"
# CIDR Range Generation with Count Index
Dynamically generates CIDR blocks by incrementing the second octet.
- Uses count.index to create sequential IP ranges
- Example output: 10.10.0.0/16, 10.11.0.0/16, etc.
- Useful for creating multiple subnets with predictable IP allocation
  ip_cidr_range = "10.${10 + count.index}.0.0/16" 
}
```

**Benefits**:
- Scale infrastructure easily
- Create resources based on variables

---

## Part 4: `count` Special Objects

### `count.index`

The **zero-based index** of the current iteration.

```terraform
count = 3  # Creates instances at index 0, 1, 2

resource "google_compute_instance" "server" {
  count = 3
  name = "server-${count.index}"  # server-0, server-1, server-2
}
```

### `count.each`

Not valid! (Use `for_each` for this - see Part 6)

### Referencing Count Resources

#### Access Specific Instance

```terraform
# Access instance at index 0
google_compute_instance.tech-instance[0].name

# Access instance at index 1
google_compute_instance.tech-instance[1].id
```

#### Access All Instances

```terraform
# Get list of all instance IDs
google_compute_instance.tech-instance[*].id
# Result: ["id-0", "id-1", "id-2"]

# Get list of names
google_compute_instance.tech-instance[*].name
# Result: ["server-0", "server-1", "server-2"]

# Get list of external IPs
google_compute_instance.tech-instance[*].network_interface[0].access_config[0].nat_ip
```

#### Get Specific Attribute From All

```terraform
# This is what we do in outputs
output "all_instance_ips" {
  value = google_compute_instance.tech-instance[*].network_interface[0].access_config[0].nat_ip
}

# Result:
# all_instance_ips = ["34.123.45.67", "35.234.56.78"]
```

---

## Part 5: All Terraform Meta-Arguments

Terraform supports several meta-arguments. Here's a complete overview:

### 1. `count` - Create Multiple Resources

```terraform
resource "google_compute_instance" "server" {
  count = 3  # Create 3 instances
  name = "server-${count.index}"
}
```

**Use when**: You need multiple identical resources

---

### 2. `for_each` - Create Multiple Resources from Map/Set

```terraform
variable "servers" {
  default = {
    "web-1" = "e2-micro"
    "web-2" = "e2-small"
    "db-1"  = "n1-standard-1"
  }
}

resource "google_compute_instance" "server" {
  for_each = var.servers
  name = each.key           # web-1, web-2, db-1
  machine_type = each.value # e2-micro, e2-small, n1-standard-1
}

# Access: google_compute_instance.server["web-1"]
```

**Use when**: 
- Resources have different configurations
- You want to reference by name instead of index
- Creating from lists/maps

**Comparison with count**:
```
count:    Index-based (0, 1, 2...)      Ref: resource[0], resource[1]
for_each: Key-based (name)              Ref: resource["name"]
```

---

### 3. `depends_on` - Explicit Dependencies

```terraform
resource "google_compute_network" "vpc" {
  name = "my-vpc"
}

resource "google_compute_instance" "server" {
  depends_on = [google_compute_network.vpc]  # Create VPC first
  # ... rest of config
}
```

**Use when**: Dependencies aren't automatically detected

---

### 4. `provider` - Use Specific Provider Configuration

```terraform
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      configuration_aliases = [google.us-east1]
    }
  }
}

provider "google" "us-east1" {
  alias = "us-east1"
  region = "us-east1"
}

resource "google_compute_instance" "server" {
  provider = google.us-east1  # Use us-east1 provider
  # ... rest of config
}
```

**Use when**: Managing resources in multiple regions/providers

---

### 5. `lifecycle` - Control Resource Behavior

```terraform
resource "google_compute_instance" "server" {
  lifecycle {
    create_before_destroy = true      # New before delete
    ignore_changes = [labels]         # Don't update if labels change
    prevent_destroy = true            # Prevent accidental deletion
  }
  # ... rest of config
}
```

**Use when**:
- Need to protect resources
- Want specific update behavior
- Need zero-downtime updates

---

### 6. `trigger` and `version` (for modules)

See module documentation for details.

---

## Part 6: `count` vs `for_each`

### Side-by-Side Comparison

| Feature | `count` | `for_each` |
|---------|---------|-----------|
| **Reference Style** | Index-based: `[0]`, `[1]` | Key-based: `["name"]` |
| **Iteration** | Over numbers | Over map/set items |
| **Readability** | Less readable for named items | More readable |
| **Adding/Removing** | Risky (indices shift) | Safe (keys don't change) |
| **Complex Configs** | Less suitable | More suitable |
| **Performance** | Slightly faster | Slightly slower |

### Example: When to Use Each

**Use `count` for**:
```terraform
# Create N identical servers
resource "google_compute_instance" "server" {
  count = var.server_count
  name = "server-${count.index}"
  # All same config
}
```

**Use `for_each` for**:
```terraform
# Create different servers with different configs
variable "servers" {
  default = {
    "web-prod" = { machine_type = "n1-standard-4", disk_size = 100 }
    "web-dev"  = { machine_type = "e2-micro", disk_size = 20 }
    "db-prod"  = { machine_type = "n1-highmem-8", disk_size = 500 }
  }
}

resource "google_compute_instance" "server" {
  for_each = var.servers
  name = each.key
  machine_type = each.value.machine_type
  # ...
}
```

---

## Part 7: Accessing Count Resources in Outputs

In this project (`t6-output-values.tf`):

```terraform
# Get each instance separately (index-based access)
output "instance_0_name" {
  description = "VM Name"
  value = google_compute_instance.tech-instance[0].name
}

output "instance_1_name" {
  description = "VM Name"
  value = google_compute_instance.tech-instance[1].name
}
```

**Better approach - Get all dynamically**:

```terraform
# Works regardless of count value
output "all_instance_names" {
  description = "Names of all instances"
  value = google_compute_instance.tech-instance[*].name
}

output "all_instance_ips" {
  description = "External IPs of all instances"
  value = google_compute_instance.tech-instance[*].network_interface[0].access_config[0].nat_ip
}
```

**Even better - Output specific format**:

```terraform
output "instances_info" {
  description = "All instance information"
  value = [
    for instance in google_compute_instance.tech-instance :
    {
      name = instance.name
      ip   = instance.network_interface[0].access_config[0].nat_ip
      zone = instance.zone
    }
  ]
}

# Output:
# instances_info = [
#   {
#     ip   = "34.123.45.67"
#     name = "tech-instance-0"
#     zone = "us-central1-a"
#   },
#   {
#     ip   = "35.234.56.78"
#     name = "tech-instance-1"
#     zone = "us-central1-a"
#   },
# ]
```

---

## Part 8: Directory Structure & File Explanations

### Directory Overview

```
5-TF-Meta-arguements/1.count/
├── t1-providers.tf          # Provider configuration
├── t2-variables.tf          # Variable declarations
├── t3-vpc.tf                # VPC and Subnet resources
├── t4-firewallrules.tf      # Firewall rules
├── t5-vminstance.tf         # VM instances WITH count meta-argument
├── t6-output-values.tf      # Output declarations
├── terraform.tfvars         # Variable values
├── startup-script.sh        # Startup script for VMs
├── 5-1-count.jpg            # Visual diagram (reference image)
└── README.md                # This file
```

### File-by-File Explanation

#### **t1-providers.tf** - Provider Configuration

```terraform
terraform {
  required_version = ">= 1.8.5"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 7.16"
    }
  }
}

provider "google" {
  project = var.gcp_project
  region = var.gcp_region1
}
```

**What it does**: Sets up Google Cloud Provider
**Key change**: Uses `var.gcp_project` and `var.gcp_region1` (from variables)
**Note**: Same as previous projects (see 3-TF-firewall-vminstance or 4-TF-Output-variables-values)

---

#### **t2-variables.tf** - Variable Declarations

```terraform
variable "gcp_project" {
  description = "Project in which GCP Resources to be created"
  type = string
  default = "terraform-project-484318"
}

variable "gcp_region1" {
  description = "Region in which GCP Resources to be created"
  type = string
  default = "us-central1"
}

variable "machine_type" {
  description = "Compute Engine Machine Type"
  type = string
  default = "e2-small"
}

variable "ip_cidr" {
  description = "CIDR range for the VPC network"
  type = string
  default = "10.128.0.0/20"
}

variable "machine_name" {
  description = "Name of the VM Instance"
  type = string
  default = "tech-instance"
}

variable "machine_image" {
  description = "The image to use for the boot disk"
  type = string
  default = "debian-cloud/debian-12"
}
```

**Purpose**: Declares all variables used in this project
**Key variables for count**:
- `machine_name`: Base name for instances (will add index)
- `machine_type`: Type of machine for all instances

**Flexibility**: All infrastructure is parameterized (no hardcoded values)

---

#### **t3-vpc.tf** - Network Infrastructure

```terraform
resource "google_compute_network" "techvpc" {
  name = "techvpc1" 
  auto_create_subnetworks = false    
}

resource "google_compute_subnetwork" "techsubnet" {
  name          = "${var.gcp_region1}-subnet"
  region        = var.gcp_region1
  ip_cidr_range = var.ip_cidr
  network       = google_compute_network.techvpc.id 
}
```

**Purpose**: Creates VPC and Subnet
**Uses variables**: 
- `var.gcp_region1` for region and subnet naming
- `var.ip_cidr` for IP range

**Note**: Same as previous projects (see 3-TF-firewall-vminstance)

---

#### **t4-firewallrules.tf** - Security Rules

```terraform
# Firewall Rule: SSH
resource "google_compute_firewall" "fw_ssh" {
  name = "tech-fw-allow-ssh22"
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.techvpc.id 
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-tag"]
}

# Firewall Rule: HTTP Port 80
resource "google_compute_firewall" "fw_http" {
  name = "tech-fw-allow-http80"
  allow {
    ports    = ["80"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.techvpc.id 
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["webserver-tag"]
}
```

**Purpose**: Firewall rules for SSH and HTTP traffic
**Note**: These rules apply to ALL instances (both created by count)
**Reason**: Target tags `ssh-tag` and `webserver-tag` apply to all instances

---

#### **t5-vminstance.tf** - THE KEY FILE (With `count`)

```terraform
resource "google_compute_instance" "tech-instance" {
  count = 2  # ← THIS IS THE META-ARGUMENT
  
  name         = "${var.machine_name}-${count.index}"
  machine_type = var.machine_type
  zone         = "${var.gcp_region1}-a"
  tags        = ["ssh-tag","webserver-tag"]
  boot_disk {
    initialize_params {
      image = var.machine_image
    }
  }
  metadata_startup_script = file("${path.module}/startup-script.sh")
  network_interface {
    subnetwork = google_compute_subnetwork.techsubnet.id 
    access_config {
      # External IP for each instance
    }
  }
}
```

**Key points**:

1. **`count = 2`**: Creates 2 instances
2. **`${count.index}`**: Used to make each instance unique
   - First iteration: count.index = 0 → name = "tech-instance-0"
   - Second iteration: count.index = 1 → name = "tech-instance-1"
3. **Both instances get**:
   - Same machine type
   - Same zone
   - Same tags (so firewall rules apply to both)
   - Same startup script (Nginx installed on both)
   - Each gets its own external IP (via access_config)

**What Terraform Creates**:
```
google_compute_instance.tech-instance[0]
  └─ name: tech-instance-0
  └─ external IP: 34.x.x.x
  └─ Nginx running

google_compute_instance.tech-instance[1]
  └─ name: tech-instance-1
  └─ external IP: 35.x.x.x
  └─ Nginx running
```

---

#### **t6-output-values.tf** - Outputs (Index-Based Access)

```terraform
# Get each list item separately
output "instance_0_name" {
  description = "VM Name"
  value = google_compute_instance.tech-instance[0].name
}

# Get each list item separately
output "instance_1_name" {
  description = "VM Name"
  value = google_compute_instance.tech-instance[1].name
}
```

**Current approach**: Hard-coded output for each index
**Limitation**: Must know exact count value (doesn't work if count changes)

**Better approach** (what you could use):

```terraform
# Dynamic output - works with any count value
output "all_instance_names" {
  value = google_compute_instance.tech-instance[*].name
}

output "all_instance_external_ips" {
  value = google_compute_instance.tech-instance[*].network_interface[0].access_config[0].nat_ip
}

# Result when count = 2:
# all_instance_names = ["tech-instance-0", "tech-instance-1"]
# all_instance_external_ips = ["34.123.45.67", "35.234.56.78"]
```

---

#### **terraform.tfvars** - Variable Values

```terraform
gcp_project   = "terraform-project-484318"
gcp_region1   = "us-central1"
machine_type  = "n1-standard-1"
```

**Purpose**: Provides values for variables (see 4-TF-Output-variables-values for details)

---

#### **startup-script.sh** - VM Initialization

```bash
#!/bin/bash
sudo apt update
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Create fancy welcome page with server info
sudo tee /var/www/html/index.html > /dev/null <<EOF
<!DOCTYPE html>
...styled HTML with hostname and IP...
EOF
```

**Purpose**: Runs on both instances when they boot
**Result**: Both instances automatically have Nginx running with welcome page

---

## Part 9: How It All Works Together

### Architecture with Count

```
┌─────────────────────────────────────────────────────────┐
│              GCP Project                                 │
│          terraform-project-484318                        │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │  VPC: techvpc1                                 │    │
│  │                                                │    │
│  │  ┌──────────────────────────────────────────┐ │    │
│  │  │  Subnet: us-central1-subnet              │ │    │
│  │  │  (10.128.0.0/20)                         │ │    │
│  │  │                                          │ │    │
│  │  │  ┌─────────────────────────────────┐   │ │    │
│  │  │  │  Instance[0]: tech-instance-0   │   │ │    │
│  │  │  │  External: 34.x.x.x             │   │ │    │
│  │  │  │  Nginx running                  │   │ │    │
│  │  │  └─────────────────────────────────┘   │ │    │
│  │  │                                        │ │    │
│  │  │  ┌─────────────────────────────────┐   │ │    │
│  │  │  │  Instance[1]: tech-instance-1   │   │ │    │
│  │  │  │  External: 35.x.x.x             │   │ │    │
│  │  │  │  Nginx running                  │   │ │    │
│  │  │  └─────────────────────────────────┘   │ │    │
│  │  └──────────────────────────────────────────┘ │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
│  Firewall Rules (Apply to BOTH):                        │
│  ┌─────────────────────────────────────────────┐       │
│  │ SSH Rule (Port 22)   ─→  [ssh-tag]          │       │
│  │ HTTP Rule (Port 80)  ─→  [webserver-tag]    │       │
│  │ (Both instances have both tags)             │       │
│  └─────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────┘
```

---

## Part 10: Common Count Patterns

### Pattern 1: Create N Instances

```terraform
variable "instance_count" {
  default = 3
}

resource "google_compute_instance" "web-server" {
  count = var.instance_count
  name = "web-server-${count.index}"
}

# Deploy 3 servers:
terraform apply

# Deploy 5 servers:
terraform apply -var='instance_count=5'
```

---

### Pattern 2: Conditional Creation (Count 0 or 1)

```terraform
variable "create_backup" {
  type = bool
  default = false
}

resource "google_compute_instance" "backup" {
  count = var.create_backup ? 1 : 0  # 1 if true, 0 if false
  name = "backup-server"
}

# Don't create:
terraform apply -var='create_backup=false'

# Create:
terraform apply -var='create_backup=true'
```

---

### Pattern 3: Create One Per Item in List

```terraform
variable "zones" {
  default = ["us-central1-a", "us-central1-b", "us-central1-c"]
}

resource "google_compute_instance" "zoned-server" {
  count = length(var.zones)
  name = "server-${var.zones[count.index]}"
  zone = var.zones[count.index]
}

# Creates 3 servers, one in each zone
```

---

## Part 11: Workflow with Count

### Deployment Steps

```bash
# 1. Initialize
terraform init

# 2. Review plan
terraform plan
# Shows: google_compute_instance.tech-instance[0] will be created
#        google_compute_instance.tech-instance[1] will be created

# 3. Apply
terraform apply
# Creates both instances

# 4. View outputs
terraform output
# Shows both instance names
```

### Modifying Count

```bash
# View current state
terraform state list
# google_compute_instance.tech-instance[0]
# google_compute_instance.tech-instance[1]

# Increase to 3 instances (add t2-variables.tf: count = 3)
# OR use command line:
terraform apply -var='count=3'  # (if count was a variable)

# View new state
terraform state list
# Shows 3 instances now

# Decrease to 1 instance
# Terraform removes extra instances
```

---

## Key Takeaways

✅ **count meta-argument**: Creates multiple instances of same resource
✅ **count.index**: Zero-based index (0, 1, 2, ...)
✅ **Use `[index]` to access**: `resource[0]`, `resource[1]`
✅ **Use `[*]` to get all**: `resource[*].attribute`
✅ **Ideal for identical resources**: All servers same config
✅ **`for_each` is alternative**: Better for different configs
✅ **Meta-arguments control HOW**: Regular arguments control WHAT

---

## Meta-Arguments Quick Reference

| Meta-Arg | Purpose | Example |
|----------|---------|---------|
| **count** | Create N identical resources | `count = 3` |
| **for_each** | Create resources from map/set | `for_each = var.instances` |
| **depends_on** | Explicit dependency | `depends_on = [resource.id]` |
| **provider** | Use specific provider | `provider = google.us-east1` |
| **lifecycle** | Control creation/update/delete | `lifecycle { prevent_destroy = true }` |

---

## Next Steps

- Change `count = 2` to `count = 3` and deploy more instances
- Create a variable like `instance_count` and use `count = var.instance_count`
- Try conditional creation: `count = var.enable_servers ? 2 : 0`
- Modify outputs to use `[*]` syntax for dynamic results
- Explore `for_each` in directory `5-TF-Meta-arguements/2.for_each`
