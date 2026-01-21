# Terraform Data Sources: Querying Cloud Infrastructure

This topic demonstrates **Data Sources** in Terraform. Data sources allow you to query existing infrastructure and external resources, enabling dynamic configurations without hardcoding values. Instead of manually specifying resource properties, data sources fetch real-time information from cloud providers.

---

## Prerequisites & References

This project builds on concepts from earlier modules. For background information, please refer to:
- **VPC & Firewall**: See `3-TF-firewall-vminstance/README.md`
- **VM Instances**: See `3-TF-firewall-vminstance/README.md`
- **Output Values**: See `4-TF-Output-variables-values/README.md`
- **count Meta-Argument**: See `5-TF-Meta-arguements/1.count/README.md`
- **for_each Meta-Argument**: See `5-TF-Meta-arguements/2.for_each/README.md`
- **depends_on Meta-Argument**: See `5-TF-Meta-arguements/3.depends_on/README.md`
- **provider Meta-Argument**: See `5-TF-Meta-arguements/4.provider/README.md`
- **lifecycle Meta-Argument**: See `5-TF-Meta-arguements/5.lifecycle/README.md`

This module focuses on **Data Sources** for querying cloud infrastructure dynamically.

---

## Part 1: What are Data Sources?

### Definition

**Data Sources** are read-only resources that Terraform uses to fetch information about existing infrastructure from your cloud provider. They query cloud APIs and return current data without creating, modifying, or destroying resources.

### Key Differences: Data Sources vs. Resources

```
RESOURCES:
- Create new infrastructure
- Modify existing infrastructure
- Destroy infrastructure
- State is managed by Terraform
- Example: google_compute_instance

DATA SOURCES:
- Query existing infrastructure
- Read-only (never modify anything)
- State is fetched from cloud provider in real-time
- No state management for data sources
- Example: google_compute_image, google_compute_zones
```

### Basic Syntax

```terraform
data "google_compute_image" "debian" {
  family  = "debian-12"
  project = "debian-cloud"
}

data "google_compute_zones" "available" {
  project = var.gcp_project
  region  = var.gcp_region
  status  = "UP"
}

# Use data source values in resources
resource "google_compute_instance" "app" {
  name         = "my-app"
  machine_type = "e2-micro"
  zone         = data.google_compute_zones.available.names[0]  # Use fetched zone
  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link  # Use fetched image
    }
  }
}
```

### When is it Needed?

**Without Data Sources** (hardcoded values):
- Manual lookup of latest image IDs required
- Configuration breaks if cloud provider changes resource IDs
- Maintenance burden: update configs when images deprecate
- Not reproducible across regions

**With Data Sources** (dynamic lookup):
- Automatically fetch latest resources
- Configuration adapts to cloud provider changes
- No manual maintenance required
- Reproducible: always uses latest available resources

---

## Part 2: How Data Sources Work

### Data Source Execution Flow

```
1. terraform plan/apply starts
                ↓
2. Terraform encounters data source block
                ↓
3. Query sent to cloud provider (GCP, AWS, Azure, etc.)
                ↓
4. Cloud provider returns current data
                ↓
5. Data source values stored in memory (NOT in state file)
                ↓
6. Values available for use in resources via data.<type>.<name>.<attribute>
                ↓
7. On next terraform plan, data source re-queried for latest values
```

### Data Source vs. Resource State Management

```
RESOURCES:
┌─────────────────────────────────────┐
│ terraform.tfstate (persistent)      │
│ ├─ Instance: my-vm                  │
│ ├─ ├─ Zone: us-central1-a           │
│ ├─ ├─ Machine type: e2-micro        │
│ └─ └─ Status: RUNNING               │
└─────────────────────────────────────┘
       (Stored on disk / remote state)

DATA SOURCES:
┌─────────────────────────────────────┐
│ Fetched in memory (temporary)       │
│ ├─ Available zones: [a, b, c]       │
│ ├─ Latest image: debian-12-v20250121 │
│ └─ Fetched at: 2025-01-21T10:30:00  │
└─────────────────────────────────────┘
       (Re-fetched on each terraform plan)
```

---

## Part 3: Common Data Sources for Google Cloud

### 1. **google_compute_image** - Latest OS Image

```terraform
data "google_compute_image" "debian_image" {
  # Query for latest Debian 12 image
  family  = "debian-12"
  project = "debian-cloud"  # Official Debian project
}

# Use in resource
resource "google_compute_instance" "app" {
  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian_image.self_link
    }
  }
}
```

**Why Use It**:
- Old images are deprecated → Auto-fetch latest version
- No manual image ID maintenance
- Consistent across environments

**Output**:
```
ID: projects/debian-cloud/global/images/debian-12-bookworm-v20250121
self_link: https://www.googleapis.com/compute/v1/projects/debian-cloud/...
name: debian-12-bookworm-v20250121
```

---

### 2. **google_compute_zones** - Available Zones

```terraform
data "google_compute_zones" "available_zones" {
  project = var.gcp_project
  region  = var.gcp_region
  status  = "UP"  # Only zones that are currently operational
}

# Use first available zone
resource "google_compute_instance" "app" {
  zone = data.google_compute_zones.available_zones.names[0]
}
```

**Why Use It**:
- Different regions have different zones
- Configuration adapts to region changes
- Automatically filters unhealthy zones

**Output**:
```
names = ["us-central1-a", "us-central1-b", "us-central1-c"]
status = "UP"
```

---

### 3. **google_compute_network** - Existing VPC Network

```terraform
data "google_compute_network" "existing_vpc" {
  name = "default"  # Query for existing network
}

# Use in firewall rules
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = data.google_compute_network.existing_vpc.id
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
```

**Why Use It**:
- Reference existing networks without creating new ones
- Share infrastructure across projects
- Avoid network duplication

---

### 4. **google_compute_subnetwork** - Existing Subnet

```terraform
data "google_compute_subnetwork" "existing_subnet" {
  name   = "default"
  region = var.gcp_region
}

# Use in instance configuration
resource "google_compute_instance" "app" {
  network_interface {
    subnetwork = data.google_compute_subnetwork.existing_subnet.id
  }
}
```

---

### 5. **google_client_config** - Current GCP Project

```terraform
data "google_client_config" "current" {
  # Fetches current authentication context
}

# Use to reference current project
output "current_project" {
  value = data.google_client_config.current.project
}
```

**Why Use It**:
- Reference current project dynamically
- Configuration reusable across projects
- No hardcoding of project IDs

---

## Part 4: Real-World Analogy

Think of **Data Sources** like **looking up information in a phonebook**:

- **Resource**: Registering a new business (creates entry in phonebook)
- **Data Source**: Looking up an existing business (reads from phonebook without modifying it)

The phonebook (cloud provider) remains unchanged; you just read the current information.

---

## Part 5: Accessing Data Source Values

### Reference Syntax

```terraform
# Syntax: data.<source_type>.<name>.<attribute>

# Example 1: Get zone names
data "google_compute_zones" "available" {
  region = "us-central1"
}

# Access all zones
zones = data.google_compute_zones.available.names
# Result: ["us-central1-a", "us-central1-b", "us-central1-c"]

# Access specific zone
first_zone = data.google_compute_zones.available.names[0]
# Result: "us-central1-a"

# Example 2: Get image information
data "google_compute_image" "debian" {
  family = "debian-12"
}

image_link = data.google_compute_image.debian.self_link
image_id = data.google_compute_image.debian.id
```

### Example: Using Multiple Data Sources

```terraform
# Fetch latest image
data "google_compute_image" "os_image" {
  family  = "debian-12"
  project = "debian-cloud"
}

# Fetch available zones
data "google_compute_zones" "zones" {
  region = var.gcp_region
  status = "UP"
}

# Create instance using fetched values
resource "google_compute_instance" "server" {
  count   = 3
  name    = "server-${count.index + 1}"
  zone    = data.google_compute_zones.zones.names[count.index % length(data.google_compute_zones.zones.names)]
  
  boot_disk {
    initialize_params {
      image = data.google_compute_image.os_image.self_link
    }
  }
}

# Result: 3 instances with latest Debian image, distributed across available zones
```

---

## Part 6: Directory Structure & File Explanations

### Directory Overview

```
6-Data-sources/
├── t0-data-sources.tf       # Data source definitions ← KEY FILE
├── t1-providers.tf          # Provider configuration
├── t2-variables.tf          # Variables (region, project, etc.)
├── t3-vpc.tf                # VPC and subnet
├── t4-firewallrules.tf      # Firewall rules
├── t5-vminstance.tf         # Instances using data sources
├── t6-output-values.tf      # Outputs including data source values
├── terraform.tfvars         # Variable values
├── startup-script.sh        # Startup script
└── README.md                # This file
```

### Key File Explanations

#### **t0-data-sources.tf** - Data Source Definitions

```terraform
# Fetch available zones in the region
data "google_compute_zones" "available_zones" {
  project = var.gcp_project
  region  = var.gcp_region1
  status  = "UP"  # Only operational zones
}

# Fetch latest Debian 12 image
data "google_compute_image" "debian_image" {
  family  = "debian-12"
  project = "debian-cloud"  # Official Debian
}

# Usage: data.google_compute_zones.available_zones.names
# Usage: data.google_compute_image.debian_image.self_link
```

**Key Points**:
- No resource created (read-only)
- Queries GCP API for current information
- Results available for use in t5-vminstance.tf and t6-output-values.tf

---

#### **t5-vminstance.tf** - Using Data Source Values

```terraform
resource "google_compute_instance" "data-source-demo" {
  count   = var.instance_count
  name    = "data-source-instance-${count.index + 1}"
  zone    = data.google_compute_zones.available_zones.names[count.index % length(data.google_compute_zones.available_zones.names)]
  
  boot_disk {
    initialize_params {
      # Use fetched image instead of hardcoded ID
      image = data.google_compute_image.debian_image.self_link
    }
  }
  
  # ... rest of configuration ...
}
```

**How It Works**:
- Line: `zone = data.google_compute_zones...`
  - Dynamically assigns zones from available zones list
  - Distributes instances across zones (round-robin with modulo)
  
- Line: `image = data.google_compute_image...`
  - Automatically uses latest Debian image
  - No hardcoded image IDs

---

#### **t6-output-values.tf** - Exposing Data Source Information

```terraform
# Output fetched zones
output "available_zones" {
  value       = data.google_compute_zones.available_zones.names
  description = "Available zones in the region"
}

# Output fetched image
output "debian_image_id" {
  value       = data.google_compute_image.debian_image.id
  description = "Latest Debian 12 image ID"
}

# Output which zones instances are deployed to
output "instance_zones" {
  value = [for instance in google_compute_instance.data-source-demo : instance.zone]
}
```

---

## Part 7: Data Source Workflow

### Initialization to Execution

```
START
  ↓
1. terraform init
   ├─ Download provider plugins
   └─ Initialize backend
  ↓
2. terraform plan
   ├─ Evaluate t0-data-sources.tf
   ├─ Query GCP for zones: "Give me UP zones in us-central1"
   │  └─ GCP responds: ["us-central1-a", "us-central1-b", "us-central1-c"]
   ├─ Query GCP for image: "Give me latest debian-12 image"
   │  └─ GCP responds: "debian-12-bookworm-v20250121"
   ├─ Read t5-vminstance.tf
   ├─ Use data source values to create instances
   ├─ Show plan: "Will create N instances using fetched image in fetched zones"
   └─ DON'T update terraform.tfstate yet (dry-run)
  ↓
3. terraform apply
   ├─ Re-run data sources (fetch fresh data)
   ├─ Create resources using current data source values
   ├─ Update terraform.tfstate with RESOURCE info (not data source info)
   └─ Data source queries not saved in state
  ↓
4. terraform plan (next time)
   ├─ Re-run data sources again (fresh query)
   ├─ Check if resources have changed
   ├─ If zone becomes "DOWN", instances might migrate automatically
   └─ Adapt configuration to latest cloud state
  ↓
END
```

---

## Part 8: Use Cases for Data Sources

### Use Case 1: Multi-Zone Instance Distribution

```terraform
data "google_compute_zones" "available" {
  region = var.region
  status = "UP"
}

resource "google_compute_instance" "balanced_servers" {
  count = var.instance_count
  zone  = data.google_compute_zones.available.names[count.index % length(data.google_compute_zones.available.names)]
  # ... rest of config ...
}

# Result: Instances automatically distributed across zones
# If zone goes down, next terraform plan sees new zone list and can rebalance
```

---

### Use Case 2: Latest OS Image Management

```terraform
data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2404-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_instance" "web_server" {
  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
    }
  }
}

# Result: Always uses latest Ubuntu LTS patch
# When Ubuntu releases v20250121, automatically picked up
# No manual intervention needed
```

---

### Use Case 3: Referencing Existing Network Infrastructure

```terraform
# Assume VPC "shared-network" exists in GCP (created manually or by different team)
data "google_compute_network" "shared" {
  name = "shared-network"
}

data "google_compute_subnetwork" "prod" {
  name   = "prod-subnet"
  region = var.region
}

resource "google_compute_firewall" "app_rules" {
  network = data.google_compute_network.shared.id
}

resource "google_compute_instance" "app" {
  network_interface {
    subnetwork = data.google_compute_subnetwork.prod.id
  }
}

# Result: Reuses existing network resources without duplication
```

---

### Use Case 4: Dynamic Project Configuration

```terraform
data "google_client_config" "current" {}

output "deploying_to" {
  value = "Project: ${data.google_client_config.current.project}"
}

resource "google_compute_instance" "app" {
  project = data.google_client_config.current.project
}

# Result: Configuration automatically adapts to project credentials used
# Deploy to different projects with same Terraform code
```

---

## Part 9: Data Source Patterns

### Pattern 1: Conditional Zones Based on Availability

```terraform
data "google_compute_zones" "available" {
  region = var.region
  status = "UP"  # Filter unhealthy zones automatically
}

locals {
  # Always use first available zone
  primary_zone = data.google_compute_zones.available.names[0]
  # Use second zone if available (high availability)
  secondary_zone = length(data.google_compute_zones.available.names) > 1 ? data.google_compute_zones.available.names[1] : data.google_compute_zones.available.names[0]
}

resource "google_compute_instance" "primary" {
  zone = local.primary_zone
}

resource "google_compute_instance" "standby" {
  zone = local.secondary_zone
}
```

---

### Pattern 2: Versioned Image Selection

```terraform
variable "os_version" {
  type    = string
  default = "debian-12"  # Change to "debian-11" to use older version
}

data "google_compute_image" "selected_os" {
  family  = var.os_version
  project = "debian-cloud"
}

resource "google_compute_instance" "app" {
  boot_disk {
    initialize_params {
      image = data.google_compute_image.selected_os.self_link
    }
  }
}
```

---

### Pattern 3: Existing Infrastructure Reuse

```terraform
# Query existing resources created manually or by other teams
data "google_compute_network" "existing" {
  name = "production-network"
}

data "google_compute_subnetwork" "existing" {
  name   = "prod-tier-1"
  region = var.region
}

# Deploy new resources into existing infrastructure
resource "google_compute_instance" "new_app" {
  network_interface {
    subnetwork = data.google_compute_subnetwork.existing.id
  }
}

# Result: Terraform doesn't try to manage existing network (read-only)
```

---

## Part 10: Data Source vs. Resource Comparison

### Practical Comparison

```terraform
# WRONG WAY - Hardcoded image ID
resource "google_compute_instance" "app" {
  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/debian-12-bookworm-v20250101"
      # Problem: Image deprecated after few months
      # Fix: Manually update config periodically
    }
  }
}

# RIGHT WAY - Data source
data "google_compute_image" "debian" {
  family  = "debian-12"
  project = "debian-cloud"
}

resource "google_compute_instance" "app" {
  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
      # Benefit: Always latest version
      # Auto-updated by GCP
    }
  }
}
```

### Data Sources vs. External Data

```
DATA SOURCES (Recommended):
- Specialized query for cloud resources
- Built-in error handling
- Provider-native integration
- Example: google_compute_image, google_compute_zones
- Risk: Low

EXTERNAL DATA SOURCE:
- Query external APIs or scripts
- More flexible but complex
- Requires custom script
- Example: Custom API calls, database queries
- Risk: Higher (script dependencies)

# Use built-in data sources whenever available!
```

---

## Part 11: Best Practices for Data Sources

### ✅ DO:

- Use data sources for dynamic values (zones, images, networks)
- Filter data sources with status conditions (`status = "UP"`)
- Reference data sources in variables/locals for reusability
- Use data sources for values that change frequently
- Document why you're using each data source
- Test across multiple regions to ensure portability

### ❌ DON'T:

- Hardcode values that change (image IDs, zone names)
- Create multiple data sources for same information
- Use data sources as substitute for proper module design
- Assume data source values never change
- Query data sources inside provisioners (causes edge cases)
- Forget that data sources re-query on each terraform plan

---

## Part 12: Testing Data Sources

### Test 1: Verify Data Source Query

```bash
# View what data sources will fetch
terraform plan -json | jq '.prior_state'

# Or use refresh to just query data sources
terraform apply -refresh-only

# Or check terraform state (data sources don't appear there)
terraform state list
# Notice: No data.* entries in state!
```

---

### Test 2: Use Different Regions

```bash
# Test with different region
terraform plan -var="gcp_region=europe-west1"

# Output should show:
# - Different zones: [europe-west1-b, europe-west1-c, europe-west1-d]
# - Same image (latest Debian still used)
```

---

### Test 3: Verify Dynamic Behavior

```bash
# Initial apply
terraform apply -auto-approve

# View current data
terraform state show data.google_compute_zones.available_zones

# If you wait for new image release and run again:
terraform apply -refresh-only

# New image version automatically picked up!
```

---

## Part 13: Troubleshooting Data Sources

### Issue: Data Source Returns Empty

```bash
# Error: Could not find image matching family "debian-12"

# Causes:
# 1. Wrong project specified
# 2. Image family doesn't exist
# 3. Authentication not working

# Debug:
terraform console

# In console:
> data.google_compute_image.debian_image
# Shows what was queried and returned

# Fix:
# - Verify project ID
# - Check image family name (use: gcloud compute images list)
# - Verify authentication
```

---

### Issue: Zone List Changes Between Runs

```bash
# Problem: Plan shows different zones each run

# Causes:
# 1. Zone status changed (UP → DOWN)
# 2. New zones added to region
# 3. GCP infrastructure changes

# This is NORMAL - data sources adapt to current cloud state

# To investigate:
gcloud compute zones list --filter="region:us-central1"

# Data sources will adapt configuration automatically
```

---

### Issue: Data Source Query Performance

```bash
# Problem: terraform plan takes long time

# Causes:
# Data sources must query cloud APIs
# Multiple data source queries = multiple API calls

# Optimization:
# 1. Use filters (status = "UP")
# 2. Cache data using locals
# 3. Avoid querying same data multiple times

# Example optimization:
locals {
  available_zones = data.google_compute_zones.available.names
  selected_zone   = local.available_zones[0]  # Cache in local
}

resource "google_compute_instance" "vm1" {
  zone = local.selected_zone
}

resource "google_compute_instance" "vm2" {
  zone = local.selected_zone  # Reuse cached value
}
```

---

## Key Takeaways

✅ **Data Sources**: Query existing cloud resources (read-only)
✅ **Dynamic Configuration**: No hardcoding of image IDs, zones, networks
✅ **Automatic Updates**: Use latest OS images automatically
✅ **Multi-Zone Distribution**: Balance instances across available zones
✅ **Existing Infrastructure**: Reference resources created outside Terraform
✅ **No State Pollution**: Data sources not saved in terraform.tfstate
✅ **Re-Query Always**: Data sources fetch fresh data on each plan/apply
✅ **Production-Ready**: Essential for adaptable, maintainable infrastructure

---

## Quick Reference: Common Data Sources

| Data Source | Purpose | Example |
|-------------|---------|---------|
| `google_compute_image` | Latest OS image | `debian-12`, `ubuntu-2404` |
| `google_compute_zones` | Available zones | `us-central1-a`, `us-central1-b` |
| `google_compute_network` | Existing VPC | Reference existing network |
| `google_compute_subnetwork` | Existing subnet | Reference existing subnet |
| `google_client_config` | Current project | Get authenticated project ID |
| `google_compute_address` | Reserved IP | Reference static IPs |
| `google_service_account` | Existing service account | Reference existing IAM |

---
