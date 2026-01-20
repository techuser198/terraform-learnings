# Terraform Meta-Arguments: Understanding `lifecycle`

This Topic demonstrates the **`lifecycle` meta-argument** in Terraform. It allows you to control how resources are created, updated, and destroyed, enabling advanced patterns like zero-downtime deployments and protection against accidental deletions.

---

## Prerequisites & References

This project builds on concepts from earlier modules. For background information, please refer to:
- **VPC & Firewall**: See `3-TF-firewall-vminstance/README.md`
- **VM Instances**: See `3-TF-firewall-vminstance/README.md`
- **count Meta-Argument**: See `5-TF-Meta-arguements/1.count/README.md`
- **for_each Meta-Argument**: See `5-TF-Meta-arguements/2.for_each/README.md`
- **depends_on Meta-Argument**: See `5-TF-Meta-arguements/3.depends_on/README.md`
- **provider Meta-Argument**: See `5-TF-Meta-arguements/4.provider/README.md`

This module focuses on **`lifecycle` meta-argument** for resource management strategies.

---

## Part 1: What is the `lifecycle` Meta-Argument?

### Definition

The **`lifecycle` meta-argument** defines rules about how Terraform should create, update, and destroy resources. It lets you customize the resource lifecycle to match your operational requirements.

### Basic Syntax

```terraform
resource "google_compute_instance" "app" {
  # ... resource configuration ...

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = true
    ignore_changes        = [labels]
    replace_triggered_by  = [null_resource.version.triggers]
  }
}
```

### When is it Needed?

**Without lifecycle** (default behavior):
- Old resource destroyed → New resource created
- Results in temporary service interruption
- Manual changes tracked and can cause drift

**With lifecycle** (controlled behavior):
- New resource created → Old resource destroyed (zero-downtime)
- Resource can be protected from accidental deletion
- Manual changes can be ignored
- Changes to specific resources can trigger replacements

---

## Part 2: How `lifecycle` Meta-Argument Works

### Lifecycle Properties

#### 1. **create_before_destroy**

```terraform
lifecycle {
  create_before_destroy = true
}
```

**Effect**:
- When resource needs replacement, new one is created BEFORE old one is destroyed
- Results in zero-downtime updates
- Useful for load-balanced environments

**Timeline Comparison**:
```
WITHOUT create_before_destroy (default):
Time 0: Old instance running ──┐
Time 1: Old destroyed          ├─ SERVICE DOWN (brief outage)
Time 2: New created            ├─ SERVICE DOWN
Time 3: New running            ──┘ Service restored

WITH create_before_destroy = true:
Time 0: Old instance running
Time 1: New instance created (both running)
Time 2: Traffic switches to new (load balancer)
Time 3: Old instance destroyed
→ Zero-downtime update!
```

---

#### 2. **prevent_destroy**

```terraform
lifecycle {
  prevent_destroy = true
}
```

**Effect**:
- Terraform refuses to destroy this resource
- `terraform destroy` will fail if this resource exists
- Protects against accidental deletion

**Use Case**:
```terraform
resource "google_sql_database" "production_db" {
  # ... database configuration ...
  
  lifecycle {
    prevent_destroy = true  # Never destroy production database!
  }
}
```

**Error when trying to destroy**:
```
Error: Instance cannot be destroyed

  on main.tf line 42, in resource "google_compute_instance" "db":
   42: resource "google_compute_instance" "db" {

Error: Resource has lifecycle.prevent_destroy set, but the plan calls for this
resource to be destroyed. To avoid this error, either remove the
lifecycle block or set prevent_destroy to false and reapply.
```

---

#### 3. **ignore_changes**

```terraform
lifecycle {
  ignore_changes = [labels, metadata["applied_by"]]
}
```

**Effect**:
- Terraform ignores changes to specified attributes
- Resource won't be updated if only these fields change
- Useful for fields modified outside Terraform

**Common Use Cases**:
```terraform
# Ignore labels applied by automation
lifecycle {
  ignore_changes = [labels]
}

# Ignore manual modifications to metadata
lifecycle {
  ignore_changes = [metadata]
}

# Ignore auto-generated timestamps
lifecycle {
  ignore_changes = [created_at, modified_at]
}
```

**Example Scenario**:
```terraform
resource "google_compute_instance" "app" {
  labels = {
    environment = "production"
  }

  lifecycle {
    ignore_changes = [labels]
  }
}

# Even if someone manually adds/changes labels in GCP Console,
# Terraform won't try to "fix" them on next apply
```

---

#### 4. **replace_triggered_by**

```terraform
lifecycle {
  replace_triggered_by = [
    null_resource.app_version.triggers
  ]
}
```

**Effect**:
- Resource is destroyed and recreated when referenced resource changes
- Forces replacement based on external events

**Use Case**:
```terraform
# When app version changes, recreate the instance
resource "null_resource" "app_version" {
  triggers = {
    app_version = "v2.0"  # Change this to trigger replacement
  }
}

resource "google_compute_instance" "app" {
  lifecycle {
    replace_triggered_by = [null_resource.app_version.triggers]
  }
}
```

**How It Works**:
- The `null_resource` tracks the app version in its triggers
- When you change `app_version` to "v2.1", the trigger value changes
- Terraform detects this change and destroys/recreates the instance
- Old instance destroyed → New instance created with latest version

**Practical Example**:
```terraform
# In terraform.tfvars
app_version = "v2.0"

# After testing new features, update to:
app_version = "v2.1"

# Run: terraform apply
# Result: Instance automatically replaced with new version
```

**When to Use**:
- Deploy new application versions
- Force config reloads
- Update dependencies on instances

---

## Part 3: Real-World Analogy

Think of **lifecycle** like **managing a retail store**:

- **create_before_destroy**: Open new location → Transfer staff → Close old location (no downtime)
- **prevent_destroy**: "This store cannot be closed!" (legal protection)
- **ignore_changes**: Don't care if manager rearranges displays (cosmetic changes)
- **replace_triggered_by**: "When new inventory arrives, clear out old stock and restock"

---

## Part 4: Use Cases for `lifecycle`

### Use Case 1: Zero-Downtime Deployments

```terraform
resource "google_compute_instance" "app_server" {
  count         = 3
  name          = "app-${count.index + 1}"
  machine_type  = "e2-medium"
  zone          = "us-central1-a"

  lifecycle {
    create_before_destroy = true
  }
}
```

**Scenario**: Updating VM image
- Without: All 3 instances destroyed → Service down → New instances created
- With: New instances created → Old destroyed → Zero-downtime!

---

### Use Case 2: Production Database Protection

```terraform
resource "google_sql_database_instance" "production" {
  name             = "prod-db-instance"
  database_version = "POSTGRES_13"
  region           = "us-central1"

  lifecycle {
    prevent_destroy = true
  }
}
```

**Protection**: If someone runs `terraform destroy`, they get an error instead of losing production database.

---

### Use Case 3: Ignoring Manual Configuration

```terraform
resource "google_compute_instance" "app" {
  name         = "my-app"
  machine_type = "e2-micro"

  lifecycle {
    ignore_changes = [
      labels,
      metadata["managed_by"]
    ]
  }
}
```

**Scenario**: 
- DevOps team adds custom labels in GCP Console
- Terraform doesn't try to "fix" them
- Manual customization preserved

---

### Use Case 4: Forced Replacement on Config Change

```terraform
resource "null_resource" "config_version" {
  triggers = {
    config_hash = filemd5("${path.module}/app-config.json")
  }
}

resource "google_compute_instance" "app" {
  name = "my-app"

  lifecycle {
    replace_triggered_by = [null_resource.config_version.triggers]
  }
}

# Example 2: Track startup script changes
resource "null_resource" "startup_script_version" {
  triggers = {
    script_hash = filemd5("${path.module}/startup-script.sh")
  }
}

resource "google_compute_instance" "app_with_script" {
  name           = "my-app-with-script"
  startup_script = file("${path.module}/startup-script.sh")

  lifecycle {
    replace_triggered_by = [null_resource.startup_script_version.triggers]
  }
}
```
**Effect**: When app-config.json changes, the instance is destroyed and recreated with new config.

**Effect**: When startup-script.sh content changes, the instance is destroyed and recreated with the new startup script automatically executed.


---

## Part 5: Directory Structure & File Explanations

### Directory Overview

```
5-TF-Meta-arguements/5.lifecycle/
├── t1-providers.tf          # Provider configuration
├── t2-variables.tf          # Variables including version for triggering
├── t3-vpc.tf                # VPC and subnet
├── t4-firewallrules.tf      # Firewall rules
├── t5-vminstance.tf         # Instances with lifecycle block ← KEY FILE
├── t6-output-values.tf      # Outputs
├── terraform.tfvars         # Variable values
├── startup-script.sh        # Startup script
└── README.md                # This file
```

### Key File Differences

#### **t5-vminstance.tf** - Lifecycle Configuration

```terraform
resource "google_compute_instance" "tech-instance" {
  count         = var.instance_count
  name          = "tech-instance-lifecycle-${count.index + 1}"
  machine_type  = var.machine_type
  zone          = var.gcp_zone
  tags          = ["ssh-tag", "webserver-tag"]

  metadata = {
    instance_version = var.instance_version
  }

  # ... network configuration ...

  # LIFECYCLE BLOCK - Core demonstration
  lifecycle {
    # Zero-downtime updates: new created before old destroyed
    create_before_destroy = true
    
    # Ignore version changes in metadata (don't update for this)
    ignore_changes = [metadata["instance_version"]]
  }

  # Provisioners log lifecycle events
  provisioner "local-exec" {
    when    = create
    command = "echo 'Instance created' >> /tmp/lifecycle.log"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Instance destroyed' >> /tmp/lifecycle.log"
  }
}
```

---

#### **t2-variables.tf** - Version Variable for Triggering

```terraform
variable "instance_version" {
  description = "Version tag for instances - change to trigger replacement"
  type        = string
  default     = "v1.0"
}

# Change this in terraform.tfvars to trigger:
# - Plan shows resource will be replaced
# - New instance created before old destroyed
# - Demonstrates create_before_destroy in action
```

---

## Part 6: Lifecycle Event Workflow

### Deployment Lifecycle Events

```
CREATION PHASE:
┌─────────────────────────────────────┐
│ terraform apply                     │
└─────────────────────────────────────┘
             ↓
┌─────────────────────────────────────┐
│ Provisioner "create" runs           │
│ (logs "Instance CREATED")           │
└─────────────────────────────────────┘
             ↓
┌─────────────────────────────────────┐
│ Instance is fully ready             │
│ Web server responding                │
└─────────────────────────────────────┘

UPDATE/REPLACEMENT PHASE:
┌─────────────────────────────────────┐
│ Change to machine_type              │
│ terraform apply                     │
└─────────────────────────────────────┘
             ↓ (create_before_destroy = true)
┌──────────────────────────────────────┐
│ NEW instance created                 │
│ Provisioner "create" runs            │
│ Old and new running simultaneously   │
└──────────────────────────────────────┘
             ↓
┌──────────────────────────────────────┐
│ OLD instance destroyed               │
│ Provisioner "destroy" runs           │
│ (logs "Instance DESTROYED")          │
└──────────────────────────────────────┘

DELETION PHASE:
┌─────────────────────────────────────┐
│ terraform destroy                   │
└─────────────────────────────────────┘
             ↓
┌─────────────────────────────────────┐
│ Provisioner "destroy" runs          │
│ (logs "Instance DESTROYED")         │
└─────────────────────────────────────┘
             ↓
┌─────────────────────────────────────┐
│ Instance completely removed         │
│ GCP resources cleaned up            │
└─────────────────────────────────────┘
```

---

## Part 7: Common Lifecycle Patterns

### Pattern 1: High Availability with Zero-Downtime Updates

```terraform
resource "google_compute_instance" "ha-app" {
  count         = 3  # Always 3 instances for HA
  name          = "app-${count.index + 1}"
  machine_type  = "e2-medium"

  lifecycle {
    create_before_destroy = true  # Smooth rolling updates
  }
}
```

**Result**: Update rolling through instances without service interruption

---

### Pattern 2: Critical Production Resources

```terraform
resource "google_sql_database_instance" "core_db" {
  name     = "production-database"
  database_version = "POSTGRES_15"

  lifecycle {
    prevent_destroy = true  # Absolutely cannot be destroyed
  }
}

resource "google_storage_bucket" "backups" {
  name = "company-backups"

  lifecycle {
    prevent_destroy = true  # Never delete backup storage
  }
}
```

**Effect**: These resources cannot be destroyed without removing the lifecycle block first (intentional protection)

---

### Pattern 3: Configuration-Driven Recreation

```terraform
resource "null_resource" "app_config" {
  triggers = {
    config = file("${path.module}/nginx.conf")
  }
}

resource "google_compute_instance" "web" {
  name = "web-server"

  lifecycle {
    replace_triggered_by = [null_resource.app_config.triggers]
  }
}
```

**Effect**: When nginx.conf changes, instance is recreated with new config

---

### Pattern 4: Ignore Cosmetic Changes

```terraform
resource "google_compute_instance" "app" {
  labels = {
    environment = "production"
    owner       = "platform-team"
  }

  lifecycle {
    ignore_changes = [labels]  # Labels can be changed manually
  }
}
```

**Effect**: Terraform ignores label changes - DevOps can add labels via console

---

## Part 8: Testing Lifecycle Behavior

### Test 1: See create_before_destroy in Action

```bash
# 1. Initial deployment
terraform apply

# 2. Change machine type to trigger replacement
# Edit terraform.tfvars:
# machine_type = "e2-small"  (was e2-micro)

# 3. Plan shows replacement
terraform plan
# Output shows: "must be replaced"

# 4. Apply with verbose logging
terraform apply -auto-approve

# 5. Watch in another terminal (optional):
gcloud compute instances list --filter="name~'tech-instance-lifecycle'"

# 6. Check lifecycle logs
cat /tmp/lifecycle.log
# Shows: Instance CREATED, Instance DESTROYED
```

---

### Test 2: See prevent_destroy Protection

```bash
# 1. Uncomment prevent_destroy in t5-vminstance.tf

# 2. Try to destroy
terraform destroy

# Expected output:
# Error: Instance cannot be destroyed
# ...lifecycle.prevent_destroy set...
# Fix: Remove prevent_destroy block or set to false
```

---

### Test 3: See ignore_changes in Action

```bash
# 1. Manually add labels in GCP Console
gcloud compute instances update tech-instance-lifecycle-1 \
  --update-labels=manual_label=custom_value

# 2. Run terraform plan
terraform plan

# Result: Plan shows NO CHANGES
# (because ignore_changes = [metadata])
# Without ignore_changes, plan would show removal of manual_label
```

---

## Part 9: Advanced Lifecycle Patterns

### Pattern: Canary Deployments

```terraform
# Current production version
resource "google_compute_instance" "stable" {
  count   = var.instance_count
  name    = "app-stable-${count.index}"
  zone    = "us-central1-a"

  lifecycle {
    create_before_destroy = true
  }
}

# Canary instance (new version)
resource "google_compute_instance" "canary" {
  count   = 1
  name    = "app-canary"
  zone    = "us-central1-b"
  machine_type = var.canary_machine_type  # Can be different

  lifecycle {
    ignore_changes = [machine_type]  # Manual canary adjustments allowed
  }
}
```

---

## Part 10: Lifecycle Considerations & Best Practices

### When to Use Each Property

| Property | Use When | Risk |
|----------|----------|------|
| `create_before_destroy` | Need zero-downtime updates | Temporary double resource cost |
| `prevent_destroy` | Critical resource that shouldn't be deleted | Must manually unset to destroy |
| `ignore_changes` | Field modified outside Terraform | Changes won't be tracked/controlled |
| `replace_triggered_by` | Want recreation based on external events | Unintended recreation if trigger changes |

### Best Practices

✅ **DO**:
- Use `create_before_destroy` for load-balanced apps
- Use `prevent_destroy` on databases and storage
- Document why each lifecycle rule exists
- Test lifecycle changes in development first
- Monitor logs when using provisioners

❌ **DON'T**:
- Use `prevent_destroy` on everything (defeats IaC benefits)
- Use `ignore_changes` on security-critical fields
- Rely on provisioners for complex logic (use configuration management)
- Ignore lifecycle warnings in terraform plan
- Use `replace_triggered_by` without understanding implications

---

## Part 11: Troubleshooting Lifecycle Issues

### Issue: Resource Won't Destroy (prevent_destroy)

```bash
# Error: Resource has lifecycle.prevent_destroy set

# Solution 1: Temporarily disable
# Edit t5-vminstance.tf:
# prevent_destroy = false  # Change this

# Solution 2: Or remove the lifecycle block entirely
terraform destroy

# Solution 3: Restore protection after
# prevent_destroy = true  # Change back
terraform apply
```

---

### Issue: Unexpected Resource Recreation

```bash
# Problem: terraform plan shows replacement but nothing changed

# Causes:
# 1. A replace_triggered_by dependency changed
# 2. Machine type computed field changed
# 3. Metadata changed and not in ignore_changes

# Debug:
terraform plan -json | jq '.resource_changes[] | select(.change.actions | contains(["delete", "create"]))'
```

---

### Issue: Performance with create_before_destroy

```bash
# Problem: Double the resources during update = double cost

# Situation:
# Initial: 3 instances × cost = 3X
# Update: 6 instances (old + new) × cost = 6X ← Temporary spike!
# After: 3 instances × cost = 3X

# Solution: Monitor resource costs during updates
# Or use gradual deployment with count adjustments
```

---

## Key Takeaways

✅ **lifecycle meta-argument**: Control resource creation, update, destruction behavior
✅ **create_before_destroy**: Zero-downtime rolling updates
✅ **prevent_destroy**: Protect critical resources from accidental deletion
✅ **ignore_changes**: Allow manual configuration outside Terraform
✅ **replace_triggered_by**: Force recreation based on external events
✅ **Event logging**: Use provisioners to track lifecycle events
✅ **Production-ready**: Essential for mission-critical infrastructure

---

