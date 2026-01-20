# Terraform Meta-Arguments: Understanding `for_each`

This directory demonstrates the **`for_each` meta-argument** in Terraform. Unlike `count` which creates identical resources using numeric indices, `for_each` creates **multiple resources with different configurations** by iterating over a map or set.

---

## Prerequisites & References

This project builds on concepts from earlier modules. For background information, please refer to:
- **VPC & Firewall**: See `3-TF-firewall-vminstance/README.md`
- **VM Instances**: See `3-TF-firewall-vminstance/README.md`
- **Terraform Variables & Precedence**: See `4-TF-Output-variables-values/README.md`
- **Output Values**: See `4-TF-Output-variables-values/README.md`
- **count Meta-Argument**: See `5-TF-Meta-arguements/1.count/README.md`

This module focuses on **`for_each` meta-argument** and how it differs from `count`.

---

## Part 1: What is `for_each`?

### Definition

The **`for_each` meta-argument** tells Terraform to create **multiple resources with different configurations** by iterating over a map or set. Each iteration creates a resource with different properties.

**Key difference from `count`**:
- `count`: Index-based (0, 1, 2...) - good for identical resources
- `for_each`: Key-based - good for different resources with meaningful names

### Real-World Analogy

Think of `for_each` like a **recipe card system**:
- **count**: "Make this recipe 3 times, with ingredient amounts 1x, 2x, 3x"
- **for_each**: "Make Pasta for Alice (2 servings), Pizza for Bob (3 slices), Salad for Carol (1 bowl)"

---

## Part 2: How `for_each` Works

### Syntax

```terraform
resource "resource_type" "name" {
  for_each = variable_or_map    # Map or set to iterate over
  
  property = each.key           # The map key
  property = each.value         # The map value
}
```

### Key Components

1. **`for_each = map_or_set`**: What to iterate over
2. **`each.key`**: Current iteration's key (name)
3. **`each.value`**: Current iteration's value (data)
4. **Resource reference**: `resource_type.name["key"]` (not index!)

### Example: Creating 3 Different Servers

**In this project** (`t5-vminstance.tf`):

```terraform
resource "google_compute_instance" "tech-instance" {
  for_each = var.instances  # ← Use for_each instead of count
  
  name         = each.key                    # web-server-1, web-server-2, db-server
  machine_type = each.value.machine_type    # e2-micro, e2-small, n1-standard-1
  zone         = each.value.zone            # us-central1-a, us-central1-b, us-central1-c
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



**Variable definition** (`t2-variables.tf`):

```terraform
variable "instances" {
  description = "Map of instance configurations"
  type = map(object({
    machine_type = string
    zone         = string
  }))
  default = {
    "web-server-1" = {
      machine_type = "e2-micro"
      zone         = "us-central1-a"
    }
    "web-server-2" = {
      machine_type = "e2-small"
      zone         = "us-central1-b"
    }
    "db-server" = {
      machine_type = "n1-standard-1"
      zone         = "us-central1-c"
    }
  }
}
```

**What this creates**:

```
Iteration 1: each.key = "web-server-1"
  - Instance name: web-server-1
  - machine_type: e2-micro
  - zone: us-central1-a

Iteration 2: each.key = "web-server-2"
  - Instance name: web-server-2
  - machine_type: e2-small
  - zone: us-central1-b

Iteration 3: each.key = "db-server"
  - Instance name: db-server
  - machine_type: n1-standard-1
  - zone: us-central1-c
```

---

## Part 3: `each` Special Objects

### `each.key`

The **key** of the current map item (or the item itself if using a set).

```terraform
variable "instances" {
  default = {
    "web-1" = { ... }
    "web-2" = { ... }
    "db-1"  = { ... }
  }
}

resource "google_compute_instance" "server" {
  for_each = var.instances
  name = each.key  # "web-1", "web-2", "db-1"
}
```

### `each.value`

The **value** of the current map item (or empty for sets).

```terraform
resource "google_compute_instance" "server" {
  for_each = var.instances
  machine_type = each.value.machine_type  # e2-micro, e2-small, etc.
}
```

### Referencing `for_each` Resources

#### Access Specific Instance (by key)

```terraform
# Access instance named "web-server-1"
google_compute_instance.tech-instance["web-server-1"].id

# Access instance named "db-server"
google_compute_instance.tech-instance["db-server"].zone
```

#### Access All Instances

```terraform
# Get all instance IDs
```terraform
# Get all instance IDs as a list
[for instance in google_compute_instance.tech-instance : instance.id]

# Breakdown:
# [...]                                    - List comprehension syntax
# for instance in google_compute_instance.tech-instance  - Loop through all instances
# instance                                 - Current iteration variable
# :                                        - Separator between loop and output
# instance.id                              - Extract ID from each instance
# Result: ["instance-id-1", "instance-id-2", "instance-id-3"]


# Get map of names to IPs
```terraform
# Get map of names to IPs
{
  for name, instance in google_compute_instance.tech-instance :
  name => instance.network_interface[0].access_config[0].nat_ip
}

# Breakdown:
# {...}                                    - Map comprehension syntax
# for name, instance in google_compute_instance.tech-instance  - Loop through all instances
# name                                     - Current iteration key
# instance                                 - Current iteration resource object
# =>                                       - Separator between key and value
# instance.network_interface[0].access_config[0].nat_ip  - Extract external IP from each instance
# Result: {"web-server-1" = "34.x.x.x", "web-server-2" = "35.x.x.x", "db-server" = "36.x.x.x"}


# Result:
# {
#   "web-server-1" = "34.123.45.67"
#   "web-server-2" = "35.234.56.78"
#   "db-server"    = "36.345.67.89"
# }
```

---

## Part 4: `for_each` Use Cases

### Use Case 1: Different Server Configurations

```terraform
variable "servers" {
  default = {
    "web-prod"  = { machine_type = "n1-standard-4" }
    "web-dev"   = { machine_type = "e2-micro" }
    "db-prod"   = { machine_type = "n1-highmem-8" }
  }
}

resource "google_compute_instance" "server" {
  for_each = var.servers
  name = each.key
  machine_type = each.value.machine_type
}
```

**Benefit**: Each server has its own optimal configuration

---

### Use Case 2: Multiple Environments

```terraform
variable "environments" {
  default = {
    "staging" = {
      machine_type = "e2-small"
      network      = "staging-vpc"
    }
    "production" = {
      machine_type = "n1-standard-2"
      network      = "production-vpc"
    }
  }
}

resource "google_compute_instance" "app" {
  for_each = var.environments
  name = "app-${each.key}"
  machine_type = each.value.machine_type
}


# Reference specific environment
google_compute_instance.app["staging"].id

# Reference all environments
[for env, instance in google_compute_instance.app : instance.id]

# Map environment names to IPs
{
  for env, instance in google_compute_instance.app :
  env => instance.network_interface[0].access_config[0].nat_ip
}
```

**Breakdown**:
- `app["staging"]` - Access specific environment by key
- `for env, instance in google_compute_instance.app` - Loop through all created instances
- `env => instance.network_interface[0].access_config[0].nat_ip` - Create map of environment name to external IP


**Benefit**: Easy to manage different environment configs

---

### Use Case 3: Create Resources from External Data

```terraform
variable "team_members" {
  default = {
    "alice" = { project = "data-pipeline" }
    "bob"   = { project = "api-service" }
    "carol" = { project = "ml-models" }
  }
}

resource "google_compute_instance" "team_projects" {
  for_each = var.team_members
  name = "${each.key}-${each.value.project}-vm"
}
```

**Breakdown**:
- `each.key`: Team member name ("alice", "bob", "carol")
- `each.value.project`: Assigned project ("data-pipeline", "api-service", "ml-models")
- `name = "${each.key}-${each.value.project}-vm"`: Creates meaningful instance names
  - Iteration 1: "alice-data-pipeline-vm"
  - Iteration 2: "bob-api-service-vm"
  - Iteration 3: "carol-ml-models-vm"

**Benefit**: Each team member gets a dedicated VM for their project
             Scale based on team/organization structure

---

## Part 5: `count` vs `for_each` - Detailed Comparison

### When to Use `count`

```terraform
# ✅ Count is good here - identical resources
variable "web_server_count" { default = 3 }

resource "google_compute_instance" "web-servers" {
  count = var.web_server_count
  name = "web-server-${count.index}"  # 0, 1, 2
}
```

**Advantages**:
- Simpler syntax for identical resources
- Easy to scale by changing count value
- Natural numeric ordering

**Disadvantages**:
- Using indices (0, 1, 2) is less meaningful
- Adding/removing middle items causes recreation of all items after
- Hard to reference specific servers by name

---

### When to Use `for_each`

```terraform
# ✅ for_each is good here - different configurations
variable "servers" {
  default = {
    "web-1" = { machine_type = "e2-micro" }
    "db-1"  = { machine_type = "n1-standard-1" }
  }
}

resource "google_compute_instance" "servers" {
  for_each = var.servers
  name = each.key
  machine_type = each.value.machine_type
}
```

**Advantages**:
- Meaningful names (not indices)
- Different configs per resource
- Adding/removing items doesn't affect others
- Can reference by key: `servers["db-1"]`
- Better for scaling based on names

**Disadvantages**:
- Slightly more complex syntax
- Less intuitive for truly identical resources
- Must be careful with map keys

---

### Side-by-Side Table

| Feature | `count` | `for_each` |
|---------|---------|-----------|
| **Best for** | N identical resources | Different resources |
| **Reference** | By index: `[0]`, `[1]` | By key: `["name"]` |
| **Iteration** | `count.index` | `each.key`, `each.value` |
| **Readability** | Less readable | More readable |
| **Adding items** | Risky (indices shift) | Safe (keys don't change) |
| **Scale method** | Change count value | Add to map |
| **Use case** | Replicas | Environments/teams |

---

## Part 6: Removing/Adding Items

### Danger with `count`

```terraform
# Original
count = 3
# Creates: [0], [1], [2]

# Someone deletes item 1 and only keeps 2 items
count = 2
# Creates: [0], [1]
# Problem: [2] got deleted, but [0] and [1] remain same
# Result: Confusing state!
```

### Safe with `for_each`

```terraform
# Original
servers = {
  "web-1" = { ... }
  "web-2" = { ... }
  "db-1"  = { ... }
}
# Creates: servers["web-1"], servers["web-2"], servers["db-1"]

# Someone removes "web-2"
servers = {
  "web-1" = { ... }
  "db-1"  = { ... }
}
# Only servers["web-2"] gets destroyed
# servers["web-1"] and servers["db-1"] unaffected ✅
```

---

## Part 7: Accessing `for_each` Resources in Outputs

In this project (`t6-output-values.tf`):

```terraform
# Output all instances as a list
output "all_instance_names" {
  description = "Names of all instances"
  value = [for name, instance in google_compute_instance.tech-instance : instance.name]
}

# Output as a map
output "all_instance_ips" {
  description = "External IPs of all instances (map)"
  value = {
    for name, instance in google_compute_instance.tech-instance :
    name => instance.network_interface[0].access_config[0].nat_ip
  }
}

# Output detailed information
output "all_instance_details" {
  description = "Detailed information about all instances"
  value = {
    for name, instance in google_compute_instance.tech-instance :
    name => {
      name         = instance.name
      machine_type = instance.machine_type
      zone         = instance.zone
      ip           = instance.network_interface[0].access_config[0].nat_ip
    }
  }
}
```

**Example Output**:

```
all_instance_names = [
  "web-server-1",
  "web-server-2",
  "db-server"
]

all_instance_ips = {
  "web-server-1" = "34.123.45.67"
  "web-server-2" = "35.234.56.78"
  "db-server"    = "36.345.67.89"
}

all_instance_details = {
  "web-server-1" = {
    ip           = "34.123.45.67"
    machine_type = "e2-micro"
    name         = "web-server-1"
    zone         = "us-central1-a"
  }
  "web-server-2" = {
    ip           = "35.234.56.78"
    machine_type = "e2-small"
    name         = "web-server-2"
    zone         = "us-central1-b"
  }
  "db-server" = {
    ip           = "36.345.67.89"
    machine_type = "n1-standard-1"
    name         = "db-server"
    zone         = "us-central1-c"
  }
}
```

---

## Part 8: Directory Structure & File Explanations

### Directory Overview

```
5-TF-Meta-arguements/2.for_each/
├── t1-providers.tf          # Provider configuration
├── t2-variables.tf          # Variable declarations with MAP variable
├── t3-vpc.tf                # VPC and Subnet resources
├── t4-firewallrules.tf      # Firewall rules
├── t5-vminstance.tf         # VM instances WITH for_each meta-argument
├── t6-output-values.tf      # Output declarations
├── terraform.tfvars         # Variable values (MAP structure)
├── startup-script.sh        # Startup script for VMs
└── README.md                # This file
```

### Key File Differences from `1.count`

#### **t2-variables.tf** - NEW MAP Variable

```terraform
variable "instances" {
  description = "Map of instance configurations"
  type = map(object({
    machine_type = string
    zone         = string
  }))
  default = {
    "web-server-1" = {
      machine_type = "e2-micro"
      zone         = "us-central1-a"
    }
    "web-server-2" = {
      machine_type = "e2-small"
      zone         = "us-central1-b"
    }
    "db-server" = {
      machine_type = "n1-standard-1"
      zone         = "us-central1-c"
    }
  }
}
```

**What's new**:
- **`type = map(object({...}))`**: Defines a map where each value is an object
- **Keys**: "web-server-1", "web-server-2", "db-server"
- **Values**: Each has `machine_type` and `zone`

---

#### **t5-vminstance.tf** - USES for_each Instead of count

```terraform
resource "google_compute_instance" "tech-instance" {
  for_each = var.instances  # ← Changed from count = 2
  
  name         = each.key                    # Uses map key
  machine_type = each.value.machine_type    # Gets from map value
  zone         = each.value.zone            # Gets from map value
  # ... rest same
}
```

**Changes from count version**:
- `count = 2` → `for_each = var.instances`
- `"${var.machine_name}-${count.index}"` → `each.key`
- Direct variable → `each.value.machine_type`

---

#### **t6-output-values.tf** - Uses `for` Loop Syntax

```terraform
output "all_instance_ips" {
  value = {
    for name, instance in google_compute_instance.tech-instance :
    name => instance.network_interface[0].access_config[0].nat_ip
  }
}
```

**Syntax breakdown**:
- `for name, instance in resource : expression`
- `name`: The key
- `instance`: The resource
- `=> value`: What to output

---

#### **terraform.tfvars** - MAP Structure

```terraform
instances = {
  "web-server-1" = {
    machine_type = "e2-micro"
    zone         = "us-central1-a"
  }
  "web-server-2" = {
    machine_type = "e2-small"
    zone         = "us-central1-b"
  }
  "db-server" = {
    machine_type = "n1-standard-1"
    zone         = "us-central1-c"
  }
}
```

**Structure**: Map with meaningful keys and nested values

---

## Part 9: Architecture with for_each

```
┌─────────────────────────────────────────────────────────────┐
│              GCP Project                                     │
│          terraform-project-484318                            │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │  VPC: techvpc1                                     │    │
│  │                                                    │    │
│  │  Subnet: us-central1-subnet (10.128.0.0/20)       │    │
│  │                                                    │    │
│  │  ┌──────────────────────────────────────────┐    │    │
│  │  │  Instance["web-server-1"]                │    │    │
│  │  │  machine_type: e2-micro                  │    │    │
│  │  │  zone: us-central1-a                     │    │    │
│  │  │  External IP: 34.x.x.x                   │    │    │
│  │  └──────────────────────────────────────────┘    │    │
│  │                                                    │    │
│  │  ┌──────────────────────────────────────────┐    │    │
│  │  │  Instance["web-server-2"]                │    │    │
│  │  │  machine_type: e2-small                  │    │    │
│  │  │  zone: us-central1-b                     │    │    │
│  │  │  External IP: 35.x.x.x                   │    │    │
│  │  └──────────────────────────────────────────┘    │    │
│  │                                                    │    │
│  │  ┌──────────────────────────────────────────┐    │    │
│  │  │  Instance["db-server"]                   │    │    │
│  │  │  machine_type: n1-standard-1             │    │    │
│  │  │  zone: us-central1-c                     │    │    │
│  │  │  External IP: 36.x.x.x                   │    │    │
│  │  └──────────────────────────────────────────┘    │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## Part 10: Common `for_each` Patterns

### Pattern 1: Create Resources from Variable Map

```terraform
variable "tags" {
  default = {
    "prod"  = "Environment: Production"
    "dev"   = "Environment: Development"
    "test"  = "Environment: Testing"
  }
}

resource "google_compute_instance" "env-servers" {
  for_each = var.tags
  name = each.key
  tags = [each.value]
}
```

---

### Pattern 2: Create from List (Convert to Map)

```terraform
variable "server_names" {
  default = ["web-1", "web-2", "db-1"]
}

resource "google_compute_instance" "servers" {
  for_each = toset(var.server_names)  # Convert list to set
  name = each.value
}
```

---

### Pattern 3: Conditional Creation per Key

```terraform
variable "servers" {
  default = {
    "web-1"  = { enabled = true, type = "e2-micro" }
    "web-2"  = { enabled = false, type = "e2-micro" }
    "db-1"   = { enabled = true, type = "n1-standard-1" }
  }
}

resource "google_compute_instance" "conditional-servers" {
  for_each = {for name, config in var.servers : name => config if config.enabled}
  name = each.key
  machine_type = each.value.type
}

# Only creates web-1 and db-1 (web-2 has enabled=false)
```

---

## Part 11: Workflow with for_each

### Deployment Steps

```bash
# 1. Initialize
terraform init

# 2. Review plan
terraform plan
# Shows: google_compute_instance.tech-instance["web-server-1"] will be created
#        google_compute_instance.tech-instance["web-server-2"] will be created
#        google_compute_instance.tech-instance["db-server"] will be created

# 3. Apply
terraform apply
# Creates all three instances with different configs

# 4. View outputs
terraform output
# Shows all_instance_ips with keys and values
```

### Modifying `for_each` Map

```bash
# Add new server (just update terraform.tfvars)
# Add to instances map:
# "web-server-3" = { machine_type = "e2-medium", zone = "us-central1-a" }

terraform apply
# Only creates new server, doesn't affect existing ones!

# Remove server (remove from map)
# Delete "web-server-2" from map
terraform apply
# Only destroys web-server-2, leaves others intact!
```

---

## Key Takeaways

✅ **for_each**: Create multiple resources with different configurations
✅ **each.key & each.value**: Access map data in iterations
✅ **Key-based references**: `resource["key"]` is meaningful
✅ **Safer modifications**: Adding/removing doesn't affect others
✅ **Better for**: Different configs, environments, teams
✅ **Use with**: Maps, sets, or converted lists

---

## Next Steps

- Change the instances map to add more servers
- Modify each server's machine_type independently
- Try converting a list to a map with `for k, v in ...`
- Create outputs that filter by machine type
- Combine with conditional expressions: `if each.value.enabled`
- Explore `5-TF-Meta-arguements/3.depends_on` for explicit dependencies
