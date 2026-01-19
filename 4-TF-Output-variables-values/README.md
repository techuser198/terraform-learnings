# Terraform: Variables, Outputs, and Variable Precedence

This Topic demonstrates how to use **Terraform Variables** (input values) and **Output Values** (exported values) in a complete infrastructure setup. We build upon the same infrastructure (VPC, Firewall, VM Instance) from the previous module.

---

## Prerequisites & Reference

This project builds on concepts from **3-TF-firewall-vminstance**. For detailed information about:
- **Firewall Rules**: What they are, use cases, and manual GCP setup → Refer to Part 1 of the previous documentation
- **VM Instances**: How to create them manually in GCP → Refer to Part 2 of the previous documentation
- **VPC & Networking**: Network infrastructure setup → Refer to Part 3 of the previous documentation

This module focuses on **Variables and Outputs** that make infrastructure flexible and reusable.

---

## Part 1: Understanding Terraform Variables

### What is a Variable?

A **variable** in Terraform is a named placeholder for a value that can change. Instead of hardcoding values directly in your configuration, you define variables and provide their values from different sources. This makes your infrastructure code reusable and flexible.

**Real-world analogy**: Think of variables like **function parameters in programming**.

```python
# Without variables (hardcoded)
def deploy_server():
    machine_type = "e2-micro"
    region = "us-central1"
    # deploy...

# With variables (flexible)
def deploy_server(machine_type, region):
    # deploy...

deploy_server("e2-micro", "us-central1")
deploy_server("e2-small", "us-east1")  # Different values!
```

### Why Use Variables?

1. **Reusability**: Same configuration, different values
2. **Flexibility**: Change values without modifying code
3. **Team Collaboration**: Different teams can use same templates with their values
4. **Environment Management**: Separate dev, staging, production with different variable values
5. **Security**: Avoid hardcoding sensitive data like project IDs

### Declaring Variables

Variables are declared in `.tf` files using the `variable` block:

```terraform
variable "variable_name" {
  description = "What this variable is for"
  type        = string           # Type constraint
  default     = "default_value"  # Optional default value
}
```

**In this project** (`t2-variables.tf`):

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
```

**Key parts**:
- `description`: Documents what the variable is for
- `type`: Specifies what kind of value it accepts (string, number, bool, list, map, object, etc.)
- `default`: Optional default value used if no value is provided

---

## Part 2: Variable Precedence (Priority Order)

This is CRITICAL to understand! Terraform has a specific **priority order** for where variable values come from. When you provide a variable value in multiple places, Terraform uses this precedence (from highest to lowest priority):

### Variable Precedence Order (Highest to Lowest)

```
1. Command-line flags (-var)                    ← HIGHEST PRIORITY
2. Variable files (*.auto.tfvars)
3. Variable files (-var-file)
4. Environment variables (TF_VAR_*)
5. Default values in variable declaration      ← LOWEST PRIORITY
```

### Visual Representation

```
┌─────────────────────────────────────────────────────────┐
│        Command-line: terraform apply -var 'machine_type=e2-large'  │  1. HIGHEST
├─────────────────────────────────────────────────────────┤
│        File: tf.auto.tfvars (machine_type = "e2-medium")            │  2.
├─────────────────────────────────────────────────────────┤
│        File: terraform.tfvars (machine_type = "n1-standard-1")      │  3.
├─────────────────────────────────────────────────────────┤
│        Env: export TF_VAR_machine_type="e2-standard-2"              │  4.
├─────────────────────────────────────────────────────────┤
│   Default in variable declaration (default = "e2-small")            │  5. LOWEST
└─────────────────────────────────────────────────────────┘
```

### Breaking Down Variable Files

#### **1. Default Value (Lowest Priority)**

In `t2-variables.tf`:
```terraform
variable "machine_type" {
  default = "e2-small"  # Used if NO other value provided
}
```
- **Used when**: No value provided anywhere else
- **Priority**: Lowest (overridden by everything)

#### **2. Environment Variables**

```bash
export TF_VAR_machine_type="e2-standard-2"
terraform apply
```
- **Variable name format**: `TF_VAR_` + variable name
- **Example**: `TF_VAR_machine_type`, `TF_VAR_gcp_project`
- **Priority**: Higher than defaults, lower than .tfvars files
- **Use case**: CI/CD pipelines, Docker containers

#### **3. terraform.tfvars (Standard)**

In `terraform.tfvars`:
```terraform
gcp_project   = "terraform-project-484318"
gcp_region1   = "us-east1"
machine_type  = "n1-standard-1"
```
- **Automatically loaded** by Terraform (no need to specify with `-var-file`)
- **Convention**: Default filename for variable values
- **Priority**: Higher than environment variables
- **Use case**: Team-wide default settings

#### **4. *.auto.tfvars (Automatic)**

In `tf.auto.tfvars`:
```terraform
machine_type  = "e2-medium"
```
- **Automatically loaded** (any file matching `*.auto.tfvars`)
- **Loaded AFTER**: `terraform.tfvars` (if both exist)
- **Priority**: Higher than terraform.tfvars
- **Use case**: Environment-specific overrides (dev.auto.tfvars, prod.auto.tfvars)

#### **5. -var-file Flag (Custom File)**

```bash
terraform apply -var-file="tf.tfvars"
```
- **Must be explicitly specified** with `-var-file` flag
- **Priority**: Higher than automatic files
- **Use case**: Different values for different scenarios

#### **6. -var Flag (Command-line - Highest Priority)**

```bash
terraform apply -var 'machine_type=e2-large'
```
- **Highest priority**: Overrides everything else
- **Use case**: Quick overrides, automation scripts, one-off changes

### Practical Example in This Project

**Files in this directory**:
- `t2-variables.tf` - Declares variables with defaults: `machine_type = "e2-small"`
- `terraform.tfvars` - Sets: `machine_type = "n1-standard-1"`
- `tf.auto.tfvars` - Sets: `machine_type = "e2-medium"`

**Which value wins?**

```
scenario 1: terraform apply
  Result: machine_type = "e2-medium"
  Reason: tf.auto.tfvars (auto-loaded, higher priority than terraform.tfvars)

scenario 2: terraform apply -var-file="tf.tfvars" 
  Result: machine_type = "e2-standard-2"
  Reason: tf.tfvars file specifies this

scenario 3: terraform apply -var 'machine_type=e2-large'
  Result: machine_type = "e2-large"
  Reason: -var flag has highest priority

scenario 4: terraform apply -var-file="tf.tfvars" -var 'machine_type=e2-large'
  Result: machine_type = "e2-large"
  Reason: -var flag STILL has highest priority (overrides -var-file)
```

---

## Part 3: Using Variables in Configuration

### How to Reference Variables

Use the syntax: `var.variable_name`

**In this project** (`t5-vminstance.tf`):

```terraform
resource "google_compute_instance" "tech-instance" {
  name         = "tech-instance"
  machine_type = "e2-micro"  # HARDCODED
  zone         = "us-central1-a"
  # ...
}
```

**Could be written with variables**:

```terraform
resource "google_compute_instance" "tech-instance" {
  name         = "tech-instance"
  machine_type = var.machine_type      # References variable!
  zone         = "${var.gcp_region1}-a"
  # ...
}
```

Then you control the value through variable files or command-line without changing code!

---

## Part 4: Understanding Output Values

### What is an Output?

An **output** in Terraform is a value that you want to display or export after resources are created. It's like a return value from a Terraform configuration.

**Real-world analogy**: Outputs are like **return values from a function**.

```python
# Function returns useful information
def deploy_server(machine_type):
    server = deploy(machine_type)
    return {
        "server_id": server.id,
        "external_ip": server.public_ip,
        "server_name": server.name
    }
```

### Why Use Outputs?

1. **Get useful information** after deployment (IP addresses, IDs, etc.)
2. **Share values** between modules
3. **Display critical information** to users
4. **Export data** to other tools or scripts
5. **Query infrastructure** without logging into GCP console

### Declaring Outputs

Outputs are declared using the `output` block:

```terraform
output "output_name" {
  description = "Description of what this outputs"
  value       = some_resource_attribute
  sensitive   = false  # Set to true if it contains sensitive data
}
```

### In This Project (`t6-output-values.tf`)

```terraform
output "tech-instance_instanceid" {
  description = "VM Instance ID"
  value = google_compute_instance.tech-instance.instance_id
}

output "tech-instance_external_ip" {
  description = "VM External IPs"
  value = google_compute_instance.tech-instance.network_interface[0].access_config[0].nat_ip
}

output "tech-instance_name" {
  description = "VM Name"
  value = google_compute_instance.tech-instance.name
}

output "tech-instance_machine_type" {
  description = "VM Machine Type"
  value = google_compute_instance.tech-instance.machine_type
}
```

**Breaking it down**:
- `tech-instance_instanceid` - The unique instance ID from GCP
- `tech-instance_external_ip` - The public IP address you can use to access the VM
- `tech-instance_name` - The name of the created instance
- `tech-instance_machine_type` - The machine type that was deployed

### How Terraform Displays Outputs

After `terraform apply`, outputs are displayed like:

```
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

tech-instance_external_ip = "34.123.45.67"
tech-instance_instanceid = "1234567890123456789"
tech-instance_machine_type = "e2-medium"
tech-instance_name = "tech-instance"
```

### Accessing Outputs Later

```bash
# View all outputs
terraform output

# View specific output
terraform output tech-instance_external_ip

# Get output in JSON format
terraform output -json
```

### Output Value Expressions

Outputs can reference:
1. **Resource attributes**: `google_compute_instance.tech-instance.id`
2. **Variables**: `var.machine_type`
3. **Data sources**: Information retrieved from GCP
4. **Expressions**: Computed values, concatenations, conditionals

**Examples**:

```terraform
# Simple attribute
output "instance_id" {
  value = google_compute_instance.tech-instance.id
}

# Nested attribute
output "external_ip" {
  value = google_compute_instance.tech-instance.network_interface[0].access_config[0].nat_ip
}

# Concatenation
output "ssh_command" {
  value = "ssh -i ~/.ssh/id_rsa user@${google_compute_instance.tech-instance.network_interface[0].access_config[0].nat_ip}"
}

# Reference to variable
output "deployment_region" {
  value = var.gcp_region1
}

# Conditional output
output "environment" {
  value = var.environment == "prod" ? "Production" : "Development"
}
```

---

## Part 5: Directory Structure & File Explanations

### Directory Overview

```
4-TF-Output-variables-values/
├── t1-providers.tf          # GCP provider configuration
├── t2-variables.tf          # Variable declarations with defaults
├── t3-vpc.tf                # VPC and Subnet resources
├── t4-firewallrules.tf      # Firewall rules
├── t5-vminstance.tf         # VM instance (using variables)
├── t6-output-values.tf      # Output declarations
├── terraform.tfvars         # Default variable values
├── tf.tfvars                # Alternative variable values
├── tf.auto.tfvars           # Auto-loaded variable values
├── startup-script.sh        # VM startup script
├── README.md                # This file
└── .terraform/              # Terraform state (auto-generated)
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
  project = "terraform-project-484318"
  region = "us-central1"
}
```

**Purpose**: Sets up Google Cloud Provider
**Note**: Same as previous project (see 3-TF-firewall-vminstance documentation)

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
```

**What it does**:
- Declares three variables that the project uses
- Each has a `type` (what kind of value it accepts)
- Each has a `default` (fallback value if not specified elsewhere)

**Key concept**:
- This defines the **schema** - what variables exist and their types
- Actual values come from terraform.tfvars, tf.auto.tfvars, or command-line

---

#### **t3-vpc.tf** - VPC and Subnet

```terraform
resource "google_compute_network" "techvpc" {
  name = "techvpc1"
  auto_create_subnetworks = false    
}

resource "google_compute_subnetwork" "techsubnet" {
  name          = "tech-subnet1"
  region        = "us-central1"
  ip_cidr_range = "10.128.0.0/20"
  network       = google_compute_network.techvpc.id
}
```

**Purpose**: Creates network infrastructure
**Note**: Same as previous project (see 3-TF-firewall-vminstance documentation)
**Can be improved**: Use `var.gcp_region1` instead of hardcoding "us-central1"

---

#### **t4-firewallrules.tf** - Firewall Rules

```terraform
resource "google_compute_firewall" "fw_ssh" {
  name = "tech-fw-allow-ssh22"
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  # ... rest of configuration
}
```

**Purpose**: Security rules for network traffic
**Note**: Same as previous project (see 3-TF-firewall-vminstance documentation)

---

#### **t5-vminstance.tf** - Virtual Machine Instance

```terraform
resource "google_compute_instance" "tech-instance" {
  name         = "tech-instance"
  machine_type = "e2-micro"  # Could use var.machine_type instead!
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
      # Gives the VM an external IP address
    }
  }
}
```

**Purpose**: Creates the compute instance
**Note**: In a real production setup, `machine_type` would be:
```terraform
machine_type = var.machine_type  # Accepts values from variables!
```

---

#### **t6-output-values.tf** - Outputs

```terraform
output "tech-instance_instanceid" {
  description = "VM Instance ID"
  value = google_compute_instance.tech-instance.instance_id
}

output "tech-instance_external_ip" {
  description = "VM External IPs"
  value = google_compute_instance.tech-instance.network_interface[0].access_config[0].nat_ip
}

output "tech-instance_name" {
  description = "VM Name"
  value = google_compute_instance.tech-instance.name
}

output "tech-instance_machine_type" {
  description = "VM Machine Type"
  value = google_compute_instance.tech-instance.machine_type
}
```

**Purpose**: Exports useful information after deployment

**Breaking down the outputs**:

1. **instance_id**: Unique identifier from GCP
   ```terraform
   value = google_compute_instance.tech-instance.instance_id
   ```

2. **external_ip**: Public IP for accessing the server
   ```terraform
   value = google_compute_instance.tech-instance.network_interface[0].access_config[0].nat_ip
   # Breaks down as: network_interface[0] (first network) → access_config[0] (first public IP) → nat_ip (the actual IP)
   ```

3. **name**: VM name
4. **machine_type**: Type of machine deployed

---

#### **terraform.tfvars** - Standard Variable Values File

```terraform
gcp_project   = "terraform-project-484318"
gcp_region1   = "us-east1"
machine_type  = "n1-standard-1"
```

**Purpose**: Provides values for declared variables
**Precedence**: Automatically loaded (lower priority than *.auto.tfvars files)
**Use case**: Team-wide defaults

**Note**: Sets region to `us-east1` (different from default!)

---

#### **tf.tfvars** - Alternative Variable Values File

```terraform
machine_type  = "e2-standard-2"
```

**Purpose**: Alternative set of variable values
**How to use**: 
```bash
terraform apply -var-file="tf.tfvars"
```
**Use case**: Different scenarios (e.g., high-performance deployment)

---

#### **tf.auto.tfvars** - Auto-loaded Variable Values File

```terraform
machine_type  = "e2-medium"
```

**Purpose**: Provides variable values (auto-loaded)
**Precedence**: Higher than `terraform.tfvars`
**Use case**: Environment-specific overrides (dev.auto.tfvars, prod.auto.tfvars)

**File naming convention**: `*auto.tfvars` files are ALWAYS auto-loaded in alphabetical order
- `dev.auto.tfvars` might be loaded
- `prod.auto.tfvars` might be loaded
- They ALL get loaded together (so use them carefully!)

---

#### **startup-script.sh** - Initialization Script

```bash
#!/bin/bash
sudo apt update
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
# ... creates web page
```

**Purpose**: Automatically configures the VM on startup
**Note**: Same as previous project (see 3-TF-firewall-vminstance documentation)

---

## Part 6: Variable Precedence Demonstration

### Example: What value does `machine_type` actually have?

**Current setup**:
- Default in `t2-variables.tf`: `"e2-small"`
- Value in `terraform.tfvars`: `"n1-standard-1"`
- Value in `tf.auto.tfvars`: `"e2-medium"`

**Scenario 1: Standard deployment**
```bash
cd 4-TF-Output-variables-values
terraform apply
```
**Result**: `machine_type = "e2-medium"`
**Reason**: tf.auto.tfvars loaded last (highest auto priority)

**Scenario 2: Use specific tfvars file**
```bash
terraform apply -var-file="tf.tfvars"
```
**Result**: `machine_type = "e2-standard-2"`
**Reason**: -var-file explicitly specifies this file

**Scenario 3: Override with command-line**
```bash
terraform apply -var 'machine_type=e2-large'
```
**Result**: `machine_type = "e2-large"`
**Reason**: Command-line -var has HIGHEST priority

**Scenario 4: Multiple flags (command-line wins)**
```bash
terraform apply -var-file="tf.tfvars" -var 'machine_type=e2-large'
```
**Result**: `machine_type = "e2-large"`
**Reason**: -var flag ALWAYS wins (highest priority)

**Scenario 5: Using environment variable**
```bash
export TF_VAR_machine_type="e2-xlarge"
terraform apply
```
**Result**: `machine_type = "e2-xlarge"`
**Reason**: Environment variable has priority, but tf.auto.tfvars would override it (if both set)

**Scenario 5 with auto.tfvars**:
```bash
export TF_VAR_machine_type="e2-xlarge"
# tf.auto.tfvars still contains machine_type = "e2-medium"
terraform apply
```
**Result**: `machine_type = "e2-medium"`
**Reason**: tf.auto.tfvars has HIGHER priority than environment variables

---

## Part 7: Accessing Outputs

### After Deployment

```bash
# View all outputs
$ terraform output
tech-instance_external_ip = "34.123.45.67"
tech-instance_instanceid = "1234567890123456789"
tech-instance_machine_type = "e2-medium"
tech-instance_name = "tech-instance"

# View specific output
$ terraform output tech-instance_external_ip
34.123.45.67

# SSH to your VM using output
$ ssh user@$(terraform output tech-instance_external_ip)

# Get JSON output for scripting
$ terraform output -json
{
  "tech-instance_external_ip": {
    "value": "34.123.45.67"
  },
  "tech-instance_instanceid": {
    "value": "1234567890123456789"
  },
  ...
}
```

---

## Part 8: Complete Workflow Example

### Step 1: Initialize
```bash
terraform init
```

### Step 2: Review plan with default variables
```bash
terraform plan
# Shows machine_type = "e2-medium" (from tf.auto.tfvars)
```

### Step 3: Deploy with different machine type
```bash
terraform apply -var 'machine_type=e2-small'
# Deploys with e2-small (command-line override)
```

### Step 4: Check outputs
```bash
terraform output
# Displays all useful information about the deployment
```

### Step 5: Connect to VM
```bash
EXTERNAL_IP=$(terraform output -raw tech-instance_external_ip)
ssh user@${EXTERNAL_IP}
```

---

## Key Takeaways

✅ **Variables**: Make infrastructure flexible and reusable
✅ **Variable Precedence**: Command-line (-var) has highest priority
✅ **.auto.tfvars**: Auto-loaded files for environment-specific values
✅ **terraform.tfvars**: Convention for team-wide defaults
✅ **Outputs**: Display and export useful information after deployment
✅ **Output references**: `resource.name.attribute` to get resource values
✅ **Variable references**: `var.variable_name` to use variable values

---

## Comparison: With vs Without Variables

### ❌ WITHOUT Variables (Hardcoded)

```terraform
resource "google_compute_instance" "tech-instance" {
  name         = "tech-instance"
  machine_type = "e2-micro"      # Hardcoded
  zone         = "us-central1-a" # Hardcoded
}
```
**Problems**:
- Must edit code to change values
- Can't have different values for dev/prod
- Hard to share with team members

### ✅ WITH Variables (Flexible)

**In t2-variables.tf**:
```terraform
variable "machine_type" {
  default = "e2-small"
}
```

**In t5-vminstance.tf**:
```terraform
resource "google_compute_instance" "tech-instance" {
  name         = "tech-instance"
  machine_type = var.machine_type  # Uses variable!
  zone         = "us-central1-a"
}
```

**Usage**:
```bash
# Deploy dev
terraform apply -var 'machine_type=e2-micro'

# Deploy prod
terraform apply -var 'machine_type=e2-large'

# Deploy with tfvars
terraform apply -var-file="prod.tfvars"
```

**Benefits**:
- Code stays the same
- Values change easily
- Different teams can use same code
- Secure, repeatable deployments

---

## Variable and Output Best Practices

### Variables Best Practices
1. Always provide **descriptions** for documentation
2. Use **type constraints** for validation
3. Use **defaults** for optional variables
4. Use **meaningful names** (not just `x`, `y`, `z`)
5. Group related variables together
6. Use **.tfvars files** for team-wide values
7. Use **environment variables** for secrets in CI/CD

### Outputs Best Practices
1. **Export critical information**: IPs, IDs, hostnames
2. Provide **descriptions** for each output
3. Mark **sensitive data** with `sensitive = true`
4. Export **actionable information**: SSH commands, URLs
5. Use **clear naming**: prefixed with resource type
6. Document where outputs are used

---

## Next Steps

- Modify `t5-vminstance.tf` to use `var.machine_type` instead of hardcoding
- Add a new variable for `zone` and make it configurable
- Create `prod.auto.tfvars` with production-grade machine type
- Create output for SSH command: `"ssh user@${output_ip}"`
- Try deploying with different variable precedence scenarios
