# Terraform Meta-Arguments: Understanding `depends_on`

This Topic demonstrates the **`depends_on` meta-argument** in Terraform. It allows you to explicitly specify dependencies between resources, controlling the order in which they're created and destroyed.

---

## Prerequisites & References

This project builds on concepts from earlier modules. For background information, please refer to:
- **VPC & Firewall**: See `3-TF-firewall-vminstance/README.md`
- **VM Instances**: See `3-TF-firewall-vminstance/README.md`
- **Terraform Variables & Precedence**: See `4-TF-Output-variables-values/README.md`
- **Output Values**: See `4-TF-Output-variables-values/README.md`
- **count Meta-Argument**: See `5-TF-Meta-arguements/1.count/README.md`
- **for_each Meta-Argument**: See `5-TF-Meta-arguements/2.for_each/README.md`

This module focuses on **`depends_on` meta-argument** for managing resource dependencies.

---

## Part 1: What is `depends_on`?

### Definition

The **`depends_on` meta-argument** tells Terraform to wait for specific resources to be created **before** creating the current resource, even if there's no implicit reference.

**Key concept**: Terraform automatically detects dependencies through references. `depends_on` is for **explicit dependencies**.

### When is it Needed?

**Implicit dependencies** (automatic):
```terraform
# Terraform AUTOMATICALLY sees the dependency
resource "google_compute_subnetwork" "subnet" {
  network = google_compute_network.vpc.id  # ← Reference detected
}
# Creates VPC first, then subnet
```

**Explicit dependencies** (manual, using `depends_on`):
```terraform
# Terraform can't see the dependency automatically
resource "google_compute_instance" "server" {
  depends_on = [google_storage_bucket.backup]  # ← No reference, but need ordering
}
# Creates bucket first, then instance
```

---

## Part 2: How `depends_on` Works

### Syntax

```terraform
resource "resource_type" "name" {
  depends_on = [
    other_resource.name,
    another_resource.name
  ]
  
  # Regular configuration
}
```

### Real-World Analogy

Think of `depends_on` like a **construction project**:
- **Implicit dependency**: "Build foundation because I reference concrete from foundation"
- **Explicit dependency**: "Wait for building permits (invisible) before starting construction"

---

## Part 3: Examples in This Project

### Example 1: Firewall Depends on VPC

```terraform
resource "google_compute_firewall" "fw_ssh" {
  name = "tech-fw-allow-ssh22"
  depends_on = [google_compute_network.techvpc]  # ← Explicit wait
  
  network = google_compute_network.techvpc.id
  # ... rest of config
}
```

**Why it matters**:
- Even though we reference the VPC ID, explicitly stating the dependency makes the intention clear
- Ensures firewall rules are applied to a fully initialized network

---

### Example 2: Instance Depends on Multiple Resources

```terraform
resource "google_compute_instance" "tech-instance" {
  depends_on = [
    google_storage_bucket.backup-bucket,
    google_compute_firewall.fw_ssh,
    google_compute_firewall.fw_http
  ]
  
  count = 2
  name = "${var.machine_name}-${count.index}"
  # ... rest of config
}
```

**What this ensures**:
1. Storage bucket created first (for backups)
2. Firewall rules created (to allow traffic)
3. Then instances created

**If not specified**: Terraform might create instances before firewall rules, causing temporary access issues

---

## Part 4: Use Cases for `depends_on`

### Use Case 1: Wait for Setup Resources

```terraform
# Create setup script
resource "null_resource" "setup" {
  provisioner "local-exec" {
    command = "scripts/setup.sh"
  }
}

# Wait for setup to complete
resource "google_compute_instance" "app" {
  depends_on = [null_resource.setup]
  # ... config
}
```

**Use**: When some resources need preparation time

---

### Use Case 2: Ensure Service Initialization

```terraform
# Create database
resource "google_sql_database_instance" "db" {
  database_version = "MYSQL_8_0"
}

# Wait for database to be ready
resource "google_sql_database" "app_db" {
  depends_on = [google_sql_database_instance.db]
  instance   = google_sql_database_instance.db.name
  name       = "appdb"
}

# Wait for database initialization
resource "google_compute_instance" "app" {
  depends_on = [google_sql_database.app_db]
  # ... config
}
```

**Use**: When resources need to fully initialize before dependents can use them

---

### Use Case 3: Multi-Module Dependencies

```terraform
# Module A
module "networking" {
  source = "./modules/networking"
}

# Module B depends on Module A
module "compute" {
  source = "./modules/compute"
  depends_on = [module.networking]
  
  vpc_id = module.networking.vpc_id
}
```

**Use**: When modules have cross-dependencies

---

### Use Case 4: Backup Before Modification

```terraform
# Create backup
resource "google_compute_snapshot" "backup" {
  name             = "backup-${timestamp()}"
  source_disk      = google_compute_disk.data.name
}

# Wait for backup before destroying
resource "google_compute_disk" "new-data" {
  depends_on = [google_compute_snapshot.backup]
  name       = "new-data-disk"
}
```

**Use**: Ensure backups before critical operations

---

## Part 5: Implicit vs Explicit Dependencies

### Implicit Dependencies (Automatic)

Terraform **automatically detects** these dependencies:

```terraform
# Terraform sees the reference automatically
resource "google_compute_network" "vpc" {
  name = "my-vpc"
}

resource "google_compute_subnetwork" "subnet" {
  network = google_compute_network.vpc.id  # ← Dependency detected!
}

# Terraform creates: VPC → Subnet (automatically)
```

**Detected through**:
- Direct references: `.id`, `.name`, `.address`
- Variable references to resources
- Attribute access

---

### Explicit Dependencies (Manual)

You **manually specify** these dependencies:

```terraform
# No reference - but dependency exists
resource "google_storage_bucket" "logs" {
  name = "logs-bucket"
}

resource "google_compute_instance" "app" {
  depends_on = [google_storage_bucket.logs]  # ← Manual dependency
  
  # No reference to bucket, but need it ready first
}
```

**Use when**:
- Dependency isn't captured through references
- Setup/cleanup needs ordering
- Safety: Explicitly stating intent

---

## Part 6: Dependency Graph

### Example: Resource Creation Order

```
Without depends_on:
┌─────────────────────┐
│ Terraform can create│
│ these in any order: │
├─────────────────────┤
│ VPC                 │ ┐
│ Firewall Rules      │ ├─ Parallel (depends_on not specified)
│ Subnet              │ ├─ VPC must exist for firewall/subnet
│ Instances           │ ├─ Firewall/Subnet before instances
└─────────────────────┘ └─ But interdependencies handled implicitly


With depends_on:
┌──────────────────────────────────────────┐
│ Forced creation order:                   │
├──────────────────────────────────────────┤
│ 1. google_compute_network.techvpc        │ (nothing depends on this)
│    ↓                                      │
│ 2. google_storage_bucket.backup-bucket   │ (depends_on nothing, but explicit)
│    ↓                                      │
│ 3. google_compute_firewall.fw_ssh        │ (depends_on: vpc)
│    google_compute_firewall.fw_http       │ (parallel to fw_ssh)
│    ↓                                      │
│ 4. google_compute_instance.tech-instance │ (depends_on: bucket, fw_ssh, fw_http)
└──────────────────────────────────────────┘
```

---

## Part 7: Directory Structure & File Explanations

### Directory Overview

```
5-TF-Meta-arguements/3.depends_on/
├── t1-providers.tf          # Provider configuration
├── t2-variables.tf          # Variable declarations
├── t3-vpc.tf                # VPC, Subnet, and Storage Bucket
├── t4-firewallrules.tf      # Firewall rules with depends_on
├── t5-vminstance.tf         # VM instances with depends_on
├── t6-output-values.tf      # Output declarations
├── terraform.tfvars         # Variable values
├── startup-script.sh        # Startup script for VMs
└── README.md                # This file
```

### Key File Differences

#### **t3-vpc.tf** - NEW: Storage Bucket

```terraform
# New resource: Cloud Storage Bucket (for demonstration)
resource "google_storage_bucket" "backup-bucket" {
  name = "${var.gcp_project}-backup-bucket-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  location = var.gcp_region1
}
```

**Purpose**: Shows a resource that has no implicit dependency with VPC/firewall/instances

---

#### **t4-firewallrules.tf** - Uses `depends_on`

```terraform
resource "google_compute_firewall" "fw_ssh" {
  name = "tech-fw-allow-ssh22"
  depends_on = [google_compute_network.techvpc]  # ← Explicit dependency
  
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  direction = "INGRESS"
  network   = google_compute_network.techvpc.id
  # ...
}
```

**Why**: Even though we reference the VPC, `depends_on` makes the ordering explicit

---

#### **t5-vminstance.tf** - Multiple Dependencies

```terraform
resource "google_compute_instance" "tech-instance" {
  depends_on = [
    google_storage_bucket.backup-bucket,
    google_compute_firewall.fw_ssh,
    google_compute_firewall.fw_http
  ]
  
  count = 2
  name = "${var.machine_name}-${count.index}"
  # ...
}
```

**Why**: Ensures:
1. Backup storage ready (for instance configuration)
2. Firewall rules ready (before instances can serve traffic)
3. Then instances created

---

## Part 8: Common Mistakes with `depends_on`

### ❌ Mistake 1: Forgetting Implicit Dependencies Still Apply

```terraform
resource "google_compute_instance" "app" {
  depends_on = [google_storage_bucket.backup]
  
  network = google_compute_network.vpc.id  # ← Implicit dependency still exists!
  # VPC must be created BEFORE this, even without explicit depends_on
}
```

**Lesson**: `depends_on` doesn't replace implicit dependencies, it adds to them

---

### ❌ Mistake 2: Over-specifying Dependencies

```terraform
resource "google_compute_instance" "app" {
  # WRONG: Too many dependencies specified
  depends_on = [
    google_compute_network.vpc,
    google_compute_subnetwork.subnet,
    google_compute_firewall.fw1,
    google_compute_firewall.fw2,
    google_storage_bucket.logs,
    google_compute_route.routes,
    google_compute_security_policy.policy
  ]
}
```

**Better**: Only specify dependencies not captured through references

---

### ✅ Good Practice: Minimal Explicit Dependencies

```terraform
resource "google_compute_instance" "app" {
  # Only explicit when necessary
  depends_on = [
    google_storage_bucket.config-bucket  # No reference to this
  ]
  
  # Implicit dependency (has reference)
  network = google_compute_network.vpc.id
  subnet  = google_compute_subnetwork.subnet.id
}
```

---

## Part 9: Checking Dependency Graph

### View Terraform Graph

```bash
# Generate dependency graph
terraform graph

#example: 
#terraform graph
#digraph G {
#  rankdir = "RL";
#  node [shape = rect, fontname = "sans-serif"];
#  "google_compute_firewall.fw_http" [label="google_compute_firewall.fw_http"];
#  "google_compute_firewall.fw_ssh" [label="google_compute_firewall.fw_ssh"];
#  "google_compute_instance.tech-instance" [label="google_compute_instance.tech-instance"];
#  "google_compute_network.techvpc" [label="google_compute_network.techvpc"];
#  "google_compute_subnetwork.techsubnet" [label="google_compute_subnetwork.techsubnet"];
#  "google_storage_bucket.backup-bucket" [label="google_storage_bucket.backup-bucket"];
#  "google_compute_firewall.fw_http" -> "google_compute_network.techvpc";
#  "google_compute_firewall.fw_ssh" -> "google_compute_network.techvpc";
#  "google_compute_instance.tech-instance" -> "google_compute_firewall.fw_http";
#  "google_compute_instance.tech-instance" -> "google_compute_firewall.fw_ssh";
#  "google_compute_instance.tech-instance" -> "google_compute_subnetwork.techsubnet";
#  "google_compute_instance.tech-instance" -> "google_storage_bucket.backup-bucket";
#  "google_compute_subnetwork.techsubnet" -> "google_compute_network.techvpc";
#}

# Save as image (requires graphviz)
terraform graph | dot -Tsvg > graph.svg
```

**Shows**: Visual representation of all dependencies

---

## Part 10: Workflow with `depends_on`

### Deployment Steps

```bash
# 1. Initialize
terraform init

# 2. Review plan (shows dependency order)
terraform plan
# Shows resources will be created in dependency order

# 3. Apply
terraform apply
# Creates resources in correct order:
# 1. VPC
# 2. Storage bucket
# 3. Firewall rules
# 4. Instances (waits for all above)

# 4. View outputs
terraform output
```

### Viewing Dependency Order

```bash
# Terraform tells you the order
terraform plan -out=plan.tfplan

# Apply shows the order
terraform apply plan.tfplan

# In logs/output, you can see:
# google_compute_network.techvpc: Creating...
# google_compute_network.techvpc: Creation complete
# google_storage_bucket.backup-bucket: Creating...
# google_storage_bucket.backup-bucket: Creation complete
# google_compute_firewall.fw_ssh: Creating...
# google_compute_firewall.fw_ssh: Creation complete
# google_compute_instance.tech-instance[0]: Creating...
```

---

## Key Takeaways

✅ **depends_on**: Explicit control over resource ordering
✅ **Implicit dependencies**: Still work through references
✅ **Use for**: Non-reference dependencies, safety, clarity
✅ **Don't overuse**: Only when necessary
✅ **Combine with**: count, for_each, other meta-arguments
✅ **Check**: `terraform graph` to visualize dependencies

---

## Next Steps

- Add more resources that depend on each other
- Create a complex dependency chain
- Use `terraform graph` to visualize your dependency tree
- Combine `depends_on` with `count` or `for_each`
- Explore `5-TF-Meta-arguements/4.provider` for multi-region setups
