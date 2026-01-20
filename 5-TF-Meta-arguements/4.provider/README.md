# Terraform Meta-Arguments: Understanding `provider`

This Topic demonstrates the **`provider` meta-argument** in Terraform. It allows you to use multiple provider instances (e.g., same provider in different regions) within a single configuration.

---

## Prerequisites & References

This project builds on concepts from earlier modules. For background information, please refer to:
- **VPC & Firewall**: See `3-TF-firewall-vminstance/README.md`
- **VM Instances**: See `3-TF-firewall-vminstance/README.md`
- **count Meta-Argument**: See `5-TF-Meta-arguements/1.count/README.md`
- **for_each Meta-Argument**: See `5-TF-Meta-arguements/2.for_each/README.md`
- **depends_on Meta-Argument**: See `5-TF-Meta-arguements/3.depends_on/README.md`

This module focuses on **`provider` meta-argument** for multi-region/multi-cloud deployments.

---

## Part 1: What is the `provider` Meta-Argument?

### Definition

The **`provider` meta-argument** tells Terraform which provider configuration to use for creating a resource. This is useful when you have multiple provider instances (e.g., same provider in different regions).

### When is it Needed?

**Single Region** (no provider meta-argument needed):
```terraform
provider "google" {
  project = "my-project"
  region  = "us-central1"
}

resource "google_compute_instance" "server" {
  # Uses default provider
}
```

**Multiple Regions** (provider meta-argument needed):
```terraform
provider "google" {
  alias   = "us-central"
  project = "my-project"
  region  = "us-central1"
}

provider "google" {
  alias   = "asia-southeast"
  project = "my-project"
  region  = "asia-southeast1"
}

resource "google_compute_instance" "central-server" {
  provider = google.us-central  # ← Specify which provider
}

resource "google_compute_instance" "east-server" {
  provider = google.asia-southeast     # ← Different provider
}
```

---

## Part 2: How `provider` Meta-Argument Works

### Syntax

```terraform
# Define multiple providers with aliases
provider "google" {
  alias   = "primary"
  project = var.project
  region  = "us-central1"
}

provider "google" {
  alias   = "secondary"
  project = var.project
  region  = "asia-southeast1"
}

# Use provider in resource
resource "google_compute_instance" "app" {
  provider = google.primary  # ← Use primary
}

resource "google_compute_instance" "backup" {
  provider = google.secondary  # ← Use secondary
}
```

### Key Components

1. **Provider alias**: Name for provider instance (`alias = "primary"`)
2. **Provider reference**: `provider_name.alias`
3. **Meta-argument**: `provider = google.primary`

### Real-World Analogy

Think of it like **delivery drivers for different regions**:
- **Default provider**: One driver covers everything
- **Multiple providers**: Different drivers for different regions/territories

---

## Part 3: Use Cases for `provider` Meta-Argument

### Use Case 1: Multi-Region Deployment

```terraform
# Deploy same infrastructure in multiple regions
provider "google" {
  alias = "us-west"
}

provider "google" {
  alias = "eu-west"
}

# US region resources
resource "google_compute_instance" "app-us" {
  provider = google.us-west
  region   = "us-west1"
}

# EU region resources
resource "google_compute_instance" "app-eu" {
  provider = google.eu-west
  region   = "europe-west1"
}
```

---

### Use Case 2: Multi-Account Deployment

```terraform
# Deploy to multiple GCP projects
provider "google" {
  alias   = "production"
  project = "prod-project-123456"
}

provider "google" {
  alias   = "development"
  project = "dev-project-789012"
}

# Production resources
resource "google_compute_instance" "prod-app" {
  provider = google.production
}

# Development resources
resource "google_compute_instance" "dev-app" {
  provider = google.development
}
```

---

### Use Case 3: Cross-Cloud Deployment

```terraform
# Deploy to multiple cloud providers
provider "google" {
  alias = "gcp"
}

provider "aws" {
  alias = "aws"
}

# GCP resources
resource "google_compute_instance" "gcp-app" {
  provider = google.gcp
}

# AWS resources
resource "aws_instance" "aws-app" {
  provider = aws.aws
}
```

---

## Part 4: Alias and Configuration

### Declaring Provider Aliases

```terraform
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 7.16"
      # Declare aliases upfront (optional but good practice)
      configuration_aliases = [google.primary, google.secondary]
    }
  }
}

# Define primary provider
provider "google" {
  alias   = "primary"
  project = var.gcp_project
  region  = "us-central1"
}

# Define secondary provider
provider "google" {
  alias   = "secondary"
  project = var.gcp_project
  region  = "asia-southeast1"
}
```

### Breaking Down the Code

| Component | Purpose |
|-----------|---------|
| `source = "hashicorp/google"` | Specifies the official Google Cloud provider |
| `version = "~> 7.16"` | Pins to version 7.16+, allows minor updates |
| `configuration_aliases` | Pre-declares aliases for Terraform validation |
| `alias = "primary"` | Names this provider instance |
| `project = var.gcp_project` | GCP project ID (from variables) |
| `region = "us-central1"` | Default region for this provider |

### Why Declare Aliases Upfront?

- **Validation**: Terraform catches alias typos early
- **Module clarity**: Explicit about required provider configurations
- **Best practice**: Prevents runtime errors in consuming modules


---

## Part 5: Directory Structure & File Explanations

### Directory Overview

```
5-TF-Meta-arguements/4.provider/
├── t1-providers.tf          # Multiple provider configurations
├── t2-variables.tf          # Variables for both regions
├── t3-vpc.tf                # VPCs in both regions with provider
├── t4-firewallrules.tf      # Firewall rules in both regions
├── t5-vminstance.tf         # Instances in both regions
├── t6-output-values.tf      # Outputs for both regions
├── terraform.tfvars         # Variable values
├── startup-script.sh        # Startup script
└── README.md                # This file
```

### Key File Differences

#### **t1-providers.tf** - Multiple Providers with Aliases

```terraform
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 7.16"
      configuration_aliases = [google.primary, google.secondary]  # ← Declare aliases
    }
  }
}

provider "google" {
  alias   = "primary"
  project = var.gcp_project
  region  = var.gcp_region_primary  # us-central1
}

provider "google" {
  alias   = "secondary"
  project = var.gcp_project
  region  = var.gcp_region_secondary  # asia-southeast1
}
```

---

#### **t3-vpc.tf** - Resources Using Different Providers

```terraform
# PRIMARY REGION
resource "google_compute_network" "techvpc_primary" {
  provider = google.primary  # ← Use primary provider
  name = "techvpc-primary" 
  # ... created in us-central1
}

# SECONDARY REGION
resource "google_compute_network" "techvpc_secondary" {
  provider = google.secondary  # ← Use secondary provider
  name = "techvpc-secondary" 
  # ... created in asia-southeast1
}
```

---

#### **t5-vminstance.tf** - Multi-Region Instances

```terraform
# PRIMARY REGION INSTANCE
resource "google_compute_instance" "tech-instance-primary" {
  provider = google.primary
  zone     = "${var.gcp_region_primary}-a"  # us-central1-a
  # ...
}

# SECONDARY REGION INSTANCE
resource "google_compute_instance" "tech-instance-secondary" {
  provider = google.secondary
  zone     = "${var.gcp_region_secondary}-b"  # asia-southeast1-b
  # ...
}
```

---

## Part 6: Architecture with Multiple Providers

```
┌─────────────────────────────────────────────────────────────────┐
│                    GCP Project                                   │
│            terraform-project-484318                              │
├─────────────────────────────────────────────────────────────────┤
│  PRIMARY REGION (provider.google.primary)                        │
│  us-central1                                                     │
│                                                                  │
│  ┌──────────────────────────────────────────┐                   │
│  │ VPC: techvpc-primary                     │                   │
│  │ Subnet: primary-subnet (10.128.0.0/20)   │                   │
│  │                                          │                   │
│  │ ┌──────────────────────────────────────┐ │                   │
│  │ │ Instance: tech-instance-primary      │ │                   │
│  │ │ Zone: us-central1-a                  │ │                   │
│  │ │ External IP: 34.x.x.x                │ │                   │
│  │ └──────────────────────────────────────┘ │                   │
│  └──────────────────────────────────────────┘                   │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│  SECONDARY REGION (provider.google.secondary)                   │
│  asia-southeast1                                                       │
│                                                                  │
│  ┌──────────────────────────────────────────┐                   │
│  │ VPC: techvpc-secondary                   │                   │
│  │ Subnet: secondary-subnet (10.129.0.0/20) │                   │
│  │                                          │                   │
│  │ ┌──────────────────────────────────────┐ │                   │
│  │ │ Instance: tech-instance-secondary    │ │                   │
│  │ │ Zone: asia-southeast1-b                     │ │                   │
│  │ │ External IP: 35.x.x.x                │ │                   │
│  │ └──────────────────────────────────────┘ │                   │
│  └──────────────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────────────┘
```


## Part 6.5: `for_each` vs `provider` Meta-Argument

### Key Difference

| Aspect | `for_each` | `provider` |
|--------|-----------|-----------|
| **Purpose** | Iterate over resources | Specify provider instance |
| **Use Case** | Create multiple similar resources | Route to different provider configs |
| **Scope** | Single resource type | Any resource |
| **Example** | Create 3 VMs from a list | Create VMs in different regions |

### When to Use `for_each`

Use `for_each` when you need **multiple instances of the same resource**:

```terraform
variable "vm_names" {
  default = ["web-1", "web-2", "web-3"]
}

resource "google_compute_instance" "app" {
  for_each = toset(var.vm_names)
  name     = each.value
  zone     = "us-central1-a"
  # All in same region, same provider
}
```

### When to Use `provider`

Use `provider` when you need **same resource in different regions/accounts**:

```terraform
provider "google" {
  alias  = "us-central"
  region = "us-central1"
}

provider "google" {
  alias  = "asia-southeast"
  region = "asia-southeast1"
}

resource "google_compute_instance" "primary" {
  provider = google.us-central
  zone     = "us-central1-a"
}

resource "google_compute_instance" "secondary" {
  provider = google.asia-southeast
  zone     = "asia-southeast1-b"
}
```

### Combining Both

Use `for_each` AND `provider` for **multiple resources across multiple regions**:

```terraform
variable "regions" {
  default = ["us-central1", "asia-southeast1"]
}

variable "vm_count_per_region" {
  default = 2
}

# Create providers for each region
provider "google" {
  for_each = toset(var.regions)
  alias    = each.value
  region   = each.value
}

# Create multiple VMs across multiple regions
resource "google_compute_instance" "app" {
  for_each = {
    for region in var.regions : region => {
      for i in range(var.vm_count_per_region) : "${region}-vm-${i}" => i
    }
  }
  
  provider = google[each.value.region]
  name     = each.key
  zone     = "${each.value.region}-a"
}
```

### Code Breakdown

| Line | Purpose |
|------|---------|
| `for region in var.regions` | Loop through each region |
| `for i in range(var.vm_count_per_region)` | Create 2 VMs per region |
| `"${region}-vm-${i}"` | Unique VM name (e.g., `us-central1-vm-0`) |
| `provider = google[each.value.region]` | Route to correct regional provider |

**Result**: Creates 4 VMs total (2 regions × 2 VMs each), each in their respective region using the correct provider.

### Decision Tree

```
Need multiple resources?
├─ YES → Same region/account?
│        ├─ YES → Use for_each
│        └─ NO → Use provider (or combine both)
└─ NO → Use provider
```


---

## Part 7: Workflow with Multiple Providers

### Deployment Steps

```bash
# 1. Initialize (downloads provider plugins)
terraform init

# 2. Plan (shows resources in both regions)
terraform plan
# Shows:
# google_compute_network.techvpc_primary (us-central1)
# google_compute_network.techvpc_secondary (asia-southeast1)
# google_compute_instance.tech-instance-primary (us-central1-a)
# google_compute_instance.tech-instance-secondary (asia-southeast1-b)

# 3. Apply (creates resources in both regions in parallel)
terraform apply

# 4. View outputs
terraform output
# primary_instance_ip = 34.x.x.x
# secondary_instance_ip = 35.x.x.x
```

---

## Part 8: Default Provider

### When No Provider Specified

```terraform
# If no "provider" meta-argument specified, uses DEFAULT
resource "google_compute_instance" "app" {
  # Uses first/default provider defined
}
```

### Making Provider Default

```terraform
# Without alias = first provider is default
provider "google" {
  project = "my-project"
  region  = "us-central1"
  # This is the DEFAULT provider
}

provider "google" {
  alias   = "eu"
  project = "my-project"
  region  = "europe-west1"
}

resource "google_compute_instance" "app1" {
  # Uses default (first provider)
}

resource "google_compute_instance" "app2" {
  provider = google.eu  # Uses EU provider
}
```

---

## Part 9: Common Patterns

### Pattern 1: Active-Passive Multi-Region

```terraform
provider "google" {
  alias  = "active"
  region = "us-central1"
}

provider "google" {
  alias  = "passive"
  region = "us-west1"
}

# Active: Full infrastructure
resource "google_compute_instance" "active-app" {
  provider = google.active
  count    = 3
}

# Passive: Standby infrastructure
resource "google_compute_instance" "passive-app" {
  provider = google.passive
  count    = 1  # Smaller, standby setup
}
```

---

### Pattern 2: Per-Region Configuration

```terraform
variable "regions" {
  default = ["us-central1", "us-west1", "asia-southeast1"]
}

# Create providers dynamically
provider "google" {
  for_each = toset(var.regions)
  alias    = each.value
  region   = each.value
}
```

---

## Part 10: Viewing Multi-Provider Graph

```bash
# See all resources and their providers
terraform graph | dot -Tsvg > graph.svg

# Each resource shows which provider it's associated with
```

---

## Key Takeaways

✅ **provider meta-argument**: Specify which provider instance to use
✅ **Aliases**: Name different provider configurations
✅ **Multi-region**: Deploy same infrastructure in different regions
✅ **Multi-account**: Work with multiple AWS/GCP accounts
✅ **Cross-cloud**: Manage resources across different cloud providers
✅ **Default**: First provider used if none specified

---

## Next Steps

- Add more regions (add another provider alias)
- Create provider variables for dynamic configuration
- Deploy to 3+ regions
- Combine with `for_each` for dynamic provider usage
- Explore `5-TF-Meta-arguements/5.lifecycle` for resource lifecycle management
