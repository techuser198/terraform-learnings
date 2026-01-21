# Terraform Local Values & Instance Templates

This topic demonstrates **Local Values** and **Instance Templates** in Terraform. Local values simplify configurations by computing values once and reusing them throughout your code. Instance templates define standardized VM configurations that can be used to create consistent instances or managed instance groups.

---

## Prerequisites & References

This project builds on concepts from earlier modules. For background information, please refer to:
- **VPC & Firewall**: See `3-TF-firewall-vminstance/README.md`
- **VM Instances**: See `3-TF-firewall-vminstance/README.md`
- **Output Values**: See `4-TF-Output-variables-values/README.md`
- **Meta-Arguments**: See `5-TF-Meta-arguements/*/README.md`
- **Data Sources**: See `6-Data-sources/README.md`

This module focuses on **Local Values** and **Instance Templates** for advanced infrastructure organization.

---

## Part 1: What are Local Values?

### Definition

**Local Values** are intermediate values computed in Terraform that can be referenced multiple times within a configuration. They're similar to variables but are calculated values that simplify code by centralizing commonly used expressions.

### Key Characteristics

- **Computed Values**: Derived from variables, data sources, and resources
- **No State Pollution**: Not stored in terraform.tfstate
- **Centralized Definitions**: All in one place for easy maintenance
- **Reference Only**: Cannot be set via `terraform.tfvars` (unlike variables)
- **Namespace**: Accessed via `local.*` prefix

### Basic Syntax

```terraform
locals {
  # Simple values
  region     = var.gcp_region
  project_id = var.gcp_project
  
  # Computed values
  environment = "production"
  app_name    = "my-app"
  
  # Combined values
  resource_label = "${local.app_name}-${local.environment}"
  
  # Complex structures
  common_tags = {
    "environment" = local.environment
    "application" = local.app_name
    "managed_by"  = "terraform"
  }
}
```

### When to Use Local Values

**Without Local Values** (repeated code):
```terraform
resource "google_compute_instance" "vm1" {
  name    = "app-${var.region}-vm1"
  zone    = "${var.region}-a"
  tags    = ["app", "production"]
  labels {
    environment = "production"
    application = "my-app"
  }
}

resource "google_compute_instance" "vm2" {
  name    = "app-${var.region}-vm2"
  zone    = "${var.region}-b"
  tags    = ["app", "production"]    # Duplicated!
  labels {
    environment = "production"         # Duplicated!
    application = "my-app"             # Duplicated!
  }
}
```

**With Local Values** (DRY principle):
```terraform
locals {
  app_name    = "app"
  environment = "production"
  region      = var.region
}

resource "google_compute_instance" "vm1" {
  name    = "${local.app_name}-${local.region}-vm1"
  zone    = "${local.region}-a"
  tags    = [local.app_name, local.environment]
  labels = {
    environment = local.environment
    application = local.app_name
  }
}

resource "google_compute_instance" "vm2" {
  name    = "${local.app_name}-${local.region}-vm2"
  zone    = "${local.region}-b"
  tags    = [local.app_name, local.environment]
  labels = {
    environment = local.environment
    application = local.app_name
  }
}
```

---

## Part 2: Understanding Local Values in Depth

### Local Value Types

#### 1. **String Locals**

```terraform
locals {
  app_name     = "tech-app"
  environment  = "production"
  cost_center  = "engineering"
}
```

#### 2. **Computed Locals**

```terraform
locals {
  instance_count   = 3
  first_zone       = data.google_compute_zones.available.names[0]
  resource_label   = "${local.app_name}-${local.environment}"
  timestamp_prefix = formatdate("YYYY-MM-DD", timestamp())
}
```

#### 3. **Map Locals**

```terraform
locals {
  labels = {
    "environment"    = "production"
    "application"    = "tech-app"
    "terraform"      = "true"
    "cost_center"    = "engineering"
  }
}

# Usage:
resource "google_compute_instance" "app" {
  labels = local.labels
}
```

#### 4. **Merged Locals**

```terraform
locals {
  base_labels = {
    "managed_by" = "terraform"
    "team"       = "platform"
  }
  
  environment_labels = {
    "environment" = var.environment
  }
  
  # Merge multiple maps
  all_labels = merge(local.base_labels, local.environment_labels)
}
```

#### 5. **Conditional Locals**

```terraform
locals {
  # Based on environment, set different values
  machine_type = var.environment == "production" ? "e2-medium" : "e2-micro"
  replicas     = var.environment == "production" ? 3 : 1
  auto_scale   = var.environment == "production" ? true : false
}
```

#### 6. **List Locals**

```terraform
locals {
  zones = [
    "${var.region}-a",
    "${var.region}-b",
    "${var.region}-c"
  ]
  
  firewall_rules = ["ssh", "http", "https"]
  
  # Extract from data source
  available_zones = data.google_compute_zones.available.names
}
```

---

## Part 3: What are Instance Templates?

### Definition

**Instance Templates** define a blueprint for creating compute instances. They encapsulate all instance configuration (machine type, boot image, metadata, labels, network settings) and can be reused to create individual instances or managed instance groups.

### Key Characteristics

- **Immutable**: Cannot be modified after creation (create new one to change)
- **Reusable**: Multiple instances created from same template
- **Consistent**: Ensures all instances have identical base configuration
- **Scalable**: Foundation for managed instance groups with auto-scaling
- **Versioned**: Create new template when configuration changes

### Instance Template vs. Individual Instances

```
INSTANCE TEMPLATE:
├─ Define once
├─ No compute resources used (template definition only)
├─ Reuse for multiple instances
├─ Ideal for managed instance groups
└─ Create new for configuration changes

INDIVIDUAL INSTANCES:
├─ Define for each instance
├─ Compute resources used immediately
├─ Direct management
├─ Ideal for unique configurations
└─ Modify directly
```

### Basic Syntax

```terraform
resource "google_compute_instance_template" "app_template" {
  name_prefix  = "app-template-"
  machine_type = "e2-medium"
  
  disk {
    source_image = "debian-12-image"
    boot         = true
  }
  
  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.subnet.id
    
    access_config {}  # Enable external IP
  }
  
  metadata = {
    "startup-script" = file("startup-script.sh")
  }
  
  labels = {
    "environment" = "production"
  }
  
  tags = ["app", "webserver"]
  
  lifecycle {
    create_before_destroy = true
  }
}
```

---

## Part 4: Directory Structure & File Explanations

### Updated Directory Overview

```
7-Local-values-instance-templates/
├── t0-data-sources.tf           # Data sources for zones and images
├── t1-providers.tf              # Provider configuration
├── t2-locals.tf                 # Local values ← NEW!
├── t3-variables.tf              # Input variables
├── t4-vpc.tf                    # VPC and subnet
├── t5-firewallrules.tf          # Firewall rules
├── t6-instance-template.tf      # Instance template ← NEW!
├── t7-vminstance.tf             # Instances using template ← MODIFIED
├── t8-output-values.tf          # Outputs ← EXPANDED
├── terraform.tfvars             # Variable values
├── startup-script.sh            # Startup script
└── README.md                    # This file
```

### Key Files Explained

#### **t2-locals.tf** - Local Values Definition

```terraform
locals {
  # Project and Region Configuration
  project_id = var.gcp_project
  region     = var.gcp_region1
  
  # Naming Convention Locals
  environment = "production"
  app_name    = "tech-app"
  instance_name = "${local.app_name}-instance"
  
  # Instance Template Configuration
  instance_template_name = "${local.app_name}-template"
  
  # Machine Configuration
  machine_type = var.machine_type
  
  # Zone Configuration (from data source)
  available_zones = data.google_compute_zones.available_zones.names
  instance_zone   = local.available_zones[0]
  
  # Image Configuration (from data source)
  boot_image = data.google_compute_image.debian_image.self_link
 
    # Startup Script Path
  startup_script_path = "${path.module}/startup-script.sh"
 
  # Zone Configuration
  instance_metadata = {
    "environment"    = local.environment
    "application"    = local.app_name
    "created_by"     = "terraform"
    "creation_time"  = timestamp()
    "startup-script" = file(local.startup_script_path)
  }
  
  # Labels for instances
  instance_labels = {
    "environment"    = local.environment
    "application"    = local.app_name
    "terraform"      = "true"
    "managed_by"     = "terraform"
  }
  
  # Networking Configuration
  network_id  = google_compute_network.techvpc.id
  subnet_id   = google_compute_subnetwork.techsubnet.id
  
}
```

**Benefits**:
- Centralized configuration management
- Easy to modify values (one place)
- Reusable across multiple resources
- Clear naming conventions
- Consistent metadata and labels

---

#### **t6-instance-template.tf** - Instance Template Definition

```terraform
resource "google_compute_instance_template" "tech_template" {
  name_prefix  = "${local.app_name}-template-"
  description  = "Instance template for ${local.app_name}"
  machine_type = local.machine_type
  
  # Boot Disk Configuration
  disk {
    source_image = local.boot_image
    boot         = true
    disk_size_gb = 10
    disk_type    = "pd-standard"
    auto_delete  = true
  }
  
  # Networking Configuration
  network_interface {
    network    = local.network_id
    subnetwork = local.subnet_id
    
    access_config {}
  }
  
  # Metadata 
  metadata = local.instance_metadata
  
  # Labels for organization
  labels = local.instance_labels
  
  # Tags for firewall rules targeting
  tags = ["ssh-tag", "webserver-tag"]
}
```

**Key Aspects**:
- Uses local values throughout
- Creates an Instance Template for reusable VM configs
- `name_prefix` ensures unique names automatically
- Boot disk is configured (image, size, type, auto-delete)
- Public IP enabled using `access_config {}`
- Attaches to specific VPC + Subnet
- Metadata is injected into the instance
- Labels used for organization
- Tags used for firewall targeting


---

#### **t7-vminstance.tf** - Instances from Template

```terraform
resource "google_compute_instance_from_template" "tech_app" {
  name = local.instance_name
  zone = local.instance_zone
  
  # Reference the instance template
  source_instance_template = google_compute_instance_template.tech_template.id
  
  depends_on = [
    google_compute_firewall.fw_ssh,
    google_compute_firewall.fw_http
  ]
}

```

**Key Aspects**:
- Creates a VM instance from an existing Instance Template
- Uses local values for instance name and zone
- References the template using `source_instance_template`
- Uses `depends_on` to ensure firewall rules are created before the VM

---

## Part 5: Local Values Workflow

### Evaluation Order

```
1. Variables Defined (t3-variables.tf)
   ↓
2. Data Sources Queried (t0-data-sources.tf)
   - Fetch zones
   - Fetch latest image
   ↓
3. Local Values Computed (t2-locals.tf)
   - Uses variables
   - Uses data source outputs
   - Creates computed values
   ↓
4. Resources Created Using Locals
   - Instance template
   - Instances
   - Network resources
   ↓
5. Outputs Generated
   - Expose selected values
```

---

## Part 6: Instance Template Workflow

### Template Creation to Instance Deployment

```
STEP 1: Define Template
┌─────────────────────────────────────┐
│ google_compute_instance_template    │
│ ├─ Machine type: e2-micro           │
│ ├─ Boot image: Debian 12            │
│ ├─ Network: techvpc                 │
│ ├─ Metadata: startup-script         │
│ └─ Labels: environment, app         │
└─────────────────────────────────────┘
      ↓
   (Template stored in GCP)
      ↓
STEP 2: Create Instances from Template
┌─────────────────────────────────────┐
│ Instance 1 (Zone: us-central1-a)    │
│ Instance 2 (Zone: us-central1-b)    │
│ Instance 3 (Zone: us-central1-c)    │
│ (All with template configuration)   │
└─────────────────────────────────────┘
      ↓
   (Instances running with same config)
      ↓
STEP 3: Optional - Create Instance Group
┌─────────────────────────────────────┐
│ Instance Group Manager              │
│ ├─ Template: tech_template          │
│ ├─ Target size: 3 (auto-managed)   │
│ ├─ Auto-scaling: 2-5 replicas      │
│ └─ Health checks: enabled           │
└─────────────────────────────────────┘
```

---

## Part 7: Real-World Use Cases

### Use Case 1: Standardized Web Application

```terraform
locals {
  app_name    = "web-app"
  environment = "production"
  
  web_config = {
    machine_type = "e2-standard-2"
    disk_size    = 50
    replicas     = 3
  }
  
  web_labels = {
    "app-tier"     = "frontend"
    "scaling-mode" = "auto"
    "backup"       = "daily"
  }
}

resource "google_compute_instance_template" "web_template" {
  machine_type = local.web_config.machine_type
  labels       = local.web_labels
}
```

### Use Case 2: Environment-Specific Configuration

```terraform
locals {
  environments = {
    production = {
      machine_type = "e2-standard-4"
      replicas     = 5
      auto_scale   = true
    }
    staging = {
      machine_type = "e2-medium"
      replicas     = 2
      auto_scale   = false
    }
  }
  
  current_env_config = local.environments[var.environment]
}
```

### Use Case 3: Centralized Tagging Strategy

```terraform
locals {
  # Organizational standards
  base_tags = {
    "managed_by"  = "terraform"
    "team"        = "platform"
    "cost_center" = "engineering"
  }
  
  environment_tags = {
    "production" = merge(local.base_tags, { "environment" = "prod" })
    "staging"    = merge(local.base_tags, { "environment" = "staging" })
  }
}
```

---

## Part 8: Best Practices

### ✅ DO:

- **Centralize Common Values**: Group related values together
- **Use Descriptive Names**: `primary_zone` is better than `zone1`
- **Merge Maps**: Use `merge()` for combining default and custom values
- **Reference Other Locals**: Build complex values from simpler ones
- **Comment Purpose**: Explain why local exists
- **Use for Derived Values**: Computed values based on variables/data sources

### ❌ DON'T:

- **Hardcode Values**: Use variables instead
- **Create Locals for Everything**: Only use for computed/reused values
- **Deep Nesting**: Keep local structure understandable
- **Duplicate Locals**: Create new local instead of repeating values

---

## Part 9: Testing

### Test Local Values

```bash
# View local values during planning
terraform console

# In console:
> local.app_name
"tech-app"

> local.instance_labels
{
  "application" = "tech-app"
  "environment" = "production"
}
```

### Test Instance Template

```bash
# Check template created
gcloud compute instance-templates describe tech_template_name

# List templates
gcloud compute instance-templates list
```

### Test Instances

```bash
# Check instances
terraform state show google_compute_instance.tech_instance_from_template[0]

# SSH into instance
gcloud compute ssh tech-app-instance-1 --zone=us-central1-a
```

---

## Key Takeaways

✅ **Local Values**: Compute once, reuse throughout configuration
✅ **DRY Principle**: Eliminate code duplication
✅ **Centralized Configuration**: Single source for common values
✅ **Instance Templates**: Blueprint for consistent instance creation
✅ **Immutable Templates**: Create new to change configuration
✅ **Scalable Infrastructure**: Foundation for managed instance groups
✅ **Better Maintenance**: Changes in one place affect all resources
✅ **Production-Ready**: Essential for large-scale infrastructure

---
