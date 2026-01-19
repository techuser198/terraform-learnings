# Terraform: Firewall Rules and VM Instance with GCP

This topic contains Terraform configurations to create a complete infrastructure setup on Google Cloud Platform (GCP) including a VPC, firewall rules, and a VM instance running a web server.

---

## Part 1: Understanding Firewall Rules

### What is a Firewall?

A **firewall** is a network security system that acts as a barrier between your internal network and the external internet (or other networks). It monitors and controls incoming and outgoing network traffic based on predetermined security rules.

Think of a firewall like a **bouncer at a nightclub**:
- The bouncer checks who is trying to enter (incoming traffic)
- They verify if the person meets the entry requirements (firewall rules)
- They either allow entry or deny it based on the club's policies
- They also monitor people leaving (outgoing traffic)

### Real-World Example

**Scenario**: You have a web server that should be accessible to customers over the internet (HTTP port 80) and to administrators via SSH (port 22), but you want to block all other traffic.

**Without a firewall**: Any attacker can attempt to access any port on your server, potentially exposing vulnerabilities.

**With a firewall**: You define rules that say:
- ✅ Allow TCP traffic on port 22 (SSH) from anywhere
- ✅ Allow TCP traffic on port 80 (HTTP) from anywhere
- ❌ Block everything else

### Use Cases of Firewalls

1. **Security**: Prevent unauthorized access to your infrastructure
2. **Network Segmentation**: Control traffic between different parts of your infrastructure
3. **DDoS Protection**: Block malicious traffic patterns
4. **Compliance**: Meet regulatory requirements for network security
5. **Access Control**: Restrict who can access specific resources based on ports, protocols, and IPs

### Creating a Firewall in GCP Console (Manual Steps)

1. **Navigate to VPC Network → Firewalls and rules**
   - Go to the GCP Console (console.cloud.google.com)
   - In the left sidebar, search for "Firewall"
   - Click on "VPC network" → "Firewalls and rules"

2. **Click "Create Firewall Rule"**

3. **Fill in the details**:
   - **Name**: Give it a descriptive name (e.g., `allow-http-80`)
   - **Description**: Explain the purpose
   - **Network**: Select your VPC network
   - **Direction**: Choose "Ingress" (incoming traffic) or "Egress" (outgoing)
   - **Action**: Select "Allow" or "Deny"
   - **Logging**: Enable if needed for auditing

4. **Configure traffic rules**:
   - **Source IP ranges**: Specify which IPs can connect (e.g., `0.0.0.0/0` for everyone)
   - **Protocols and ports**: 
     - For SSH: TCP port 22
     - For HTTP: TCP port 80
     - For HTTPS: TCP port 443

5. **Set targets** (who this rule applies to):
   - **All instances in the network** OR
   - **Instances with specific tags** (e.g., "webserver-tag", "ssh-tag")

6. **Click Create**

### In This Project

We're creating two firewall rules:
- **SSH Rule**: Allows SSH access (port 22) from anywhere (`0.0.0.0/0`) to instances with the `ssh-tag`
- **HTTP Rule**: Allows HTTP access (port 80) from anywhere to instances with the `webserver-tag`

---

## Part 2: Understanding VM Instances

### What is a VM Instance?

A **VM (Virtual Machine) Instance** is a cloud-based computer that you can configure and control. It's like renting a physical server from GCP, but you only pay for what you use and can scale it up or down as needed.

Key characteristics:
- **Operating System**: Can run Linux (Debian, Ubuntu, CentOS) or Windows
- **Resources**: CPU, RAM, and storage are configurable
- **Pricing**: Pay-as-you-go model
- **Flexibility**: Add/remove resources on-the-fly

### Creating a VM Instance in GCP Console (Manual Steps)

1. **Navigate to Compute Engine → Instances**
   - Go to GCP Console
   - In the left sidebar, find "Compute Engine" → "Instances"

2. **Click "Create Instance"**

3. **Configure Basic Settings**:
   - **Name**: Give your instance a name (e.g., `my-web-server`)
   - **Region**: Choose location (e.g., `us-central1`)
   - **Zone**: Choose specific zone (e.g., `us-central1-a`)

4. **Choose Machine Type**:
   - Select from predefined types or customize
   - For this project: `e2-micro` (cost-effective, suitable for learning)
   - Options range from `e2-micro` (0.25-2 vCPU) to `m1-ultramem-416` (416 vCPU)

5. **Select Boot Disk**:
   - **Image**: Choose OS (e.g., Debian 12)
   - **Size**: Usually 10-20 GB is fine
   - **Type**: Standard persistent disk

6. **Add Startup Script**:
   - Expand "Advanced options" → "Management" → "Automation"
   - Paste your startup script (runs automatically when VM boots)
   - This is where we install Nginx and configure the web server

7. **Configure Networking**:
   - **Network**: Select your VPC (e.g., `techvpc1`)
   - **Subnet**: Select your subnet (e.g., `tech-subnet1`)
   - **Internal IP**: Can be automatic or custom
   - **External IP**: Choose ephemeral or static

8. **Add Network Tags**:
   - Add tags for firewall rule targeting (e.g., `ssh-tag`, `webserver-tag`)
   - These tags link the firewall rules to this instance

9. **Click Create**

---

## Part 3: Understanding This Project's Files

### Directory Structure Overview

```
3-TF-firewall-vminstance/
├── 1.providers.tf         # GCP provider configuration
├── 2.vpc.tf               # VPC and Subnet resources
├── 3.firewallrules.tf     # Firewall rules for security
├── 4.vminstance.tf        # VM instance configuration
├── startup-script.sh      # Script to run on VM startup
└── README.md              # This file
```

### File-by-File Explanation

#### **1. providers.tf** - Setting Up the GCP Connection

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

**What it does**:
- **terraform block**: Specifies Terraform version requirements and which providers to use
- **provider block**: Authenticates with GCP and sets default region

**Key concepts**:
- `required_version`: Ensures Terraform CLI is at least version 1.8.5
- `google provider`: The plugin that communicates with GCP APIs
- `project`: Your GCP project ID where resources will be created
- `region`: Default region for all resources (us-central1)

---

#### **2. vpc.tf** - Creating the Network Foundation

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

**What it does**:
Creates the virtual network infrastructure where your VM will run.

**Breaking it down**:

- **VPC (Virtual Private Cloud)**:
  - `name = "techvpc1"`: Names the VPC
  - `auto_create_subnetworks = false`: We'll manually create subnets (better control)
  - **Purpose**: Creates an isolated network space in GCP

- **Subnet**:
  - `name = "tech-subnet1"`: Names the subnet
  - `region = "us-central1"`: Deploys in us-central1 region
  - `ip_cidr_range = "10.128.0.0/20"`: Allocates 4,096 IP addresses (10.128.0.0 to 10.128.15.255)
  - `network = google_compute_network.techvpc.id`: Links to the VPC created above
  - **Purpose**: Creates a smaller network segment within the VPC where instances get IP addresses

**Network Address Explanation**:
- `10.128.0.0/20` is a private IP range (cannot be reached from the internet)
- Perfect for internal communication within your infrastructure

---

#### **3. firewallrules.tf** - Defining Security Rules

```terraform
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

**What it does**:
Defines two firewall rules to allow specific traffic to your VM.

**SSH Rule Breakdown**:
- `name = "tech-fw-allow-ssh22"`: Rule identifier
- `allow { ports = ["22"] }`: Allow TCP port 22 (SSH protocol for remote access)
- `direction = "INGRESS"`: Rule applies to incoming traffic
- `network`: Applies to our VPC
- `priority = 1000`: Priority level (lower numbers = higher priority; 1000 is default)
- `source_ranges = ["0.0.0.0/0"]`: Allow from any IP address in the world
- `target_tags = ["ssh-tag"]`: Apply to instances tagged with "ssh-tag"

**HTTP Rule Breakdown**:
- Similar to SSH rule but for port 80 (web traffic)
- `target_tags = ["webserver-tag"]`: Apply to instances tagged with "webserver-tag"

**Note**: In this project, both tags are applied to the same instance, so both rules allow traffic to it.

---

#### **4. vminstance.tf** - Creating the Compute Instance

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
  }
}
```

**What it does**:
Creates a virtual machine instance with all necessary configurations.

**Configuration breakdown**:

- **Identity & Location**:
  - `name = "tech-instance"`: The VM's name in GCP
  - `machine_type = "e2-micro"`: Tiny machine type (cost-effective for learning)
  - `zone = "us-central1-a"`: Specific zone within us-central1 region

- **Tagging**:
  - `tags = ["ssh-tag","webserver-tag"]`: Applies both tags so firewall rules apply to this instance

- **Boot Disk**:
  - `image = "debian-cloud/debian-12"`: Installs Debian 12 Linux OS on startup
  - This is the operating system image for the VM

- **Startup Script**:
  - `metadata_startup_script = file("${path.module}/startup-script.sh")`
  - Runs the startup script when the VM first boots
  - `${path.module}` references the current directory where Terraform files are

- **Networking**:
  - `subnetwork = google_compute_subnetwork.techsubnet.id`
  - Connects the instance to our subnet (tech-subnet1)
  - Automatically gets assigned a private IP from `10.128.0.0/20` range

---

#### **5. startup-script.sh** - Automatic VM Setup

```bash
#!/bin/bash
sudo apt update
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

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

**What it does**:
Automatically configures the VM when it starts up.

**Line-by-line explanation**:

1. `#!/bin/bash` - Shebang indicating this is a Bash script
2. `sudo apt update` - Updates the package list on Debian/Ubuntu
3. `sudo apt install -y nginx` - Installs Nginx web server (`-y` means yes to prompts)
4. `sudo systemctl enable nginx` - Enables Nginx to start automatically on VM reboot
5. `sudo systemctl start nginx` - Starts the Nginx service immediately
6. `HOSTNAME=$(hostname)` - Captures the VM's hostname into a variable
7. `IP_ADDRESS=$(hostname -I | awk '{print $1}')` - Gets the VM's IP address
8. `sudo tee /var/www/html/index.html` - Creates the default web page
9. HTML content - Creates a simple welcome page displaying the hostname and IP address

**Result**: When the VM boots, it automatically installs and starts a web server, and displays a simple webpage showing the server's details.

---

## How It All Works Together (Architecture Diagram)

```
┌─────────────────────────────────────────────────────────┐
│              GCP Project                                 │
│  (terraform-project-484318, us-central1)                 │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │  VPC: techvpc1                                 │    │
│  │                                                │    │
│  │  ┌──────────────────────────────────────────┐ │    │
│  │  │  Subnet: tech-subnet1                    │ │    │
│  │  │  (10.128.0.0/20)                         │ │    │
│  │  │                                          │ │    │
│  │  │  ┌─────────────────────────────────┐   │ │    │
│  │  │  │  VM Instance: tech-instance     │   │ │    │
│  │  │  │  (e2-micro, Debian 12)          │   │ │    │
│  │  │  │  - Running Nginx Web Server     │   │ │    │
│  │  │  │  - Tags: ssh-tag, webserver-tag │   │ │    │
│  │  │  └─────────────────────────────────┘   │ │    │
│  │  └──────────────────────────────────────────┘ │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
│  Firewall Rules:                                        │
│  ┌─────────────────────────────────────────────┐       │
│  │ SSH Rule (Port 22)   ─→  [ssh-tag]          │       │
│  │ HTTP Rule (Port 80)  ─→  [webserver-tag]    │       │
│  │ (Both target our instance)                  │       │
│  └─────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────┘
```

---

## Deployment Workflow

### Step 1: Initialize Terraform
```bash
terraform init
```
Downloads the Google provider plugin and initializes the working directory.

### Step 2: Review the Plan
```bash
terraform plan
```
Shows what resources will be created without actually creating them.

### Step 3: Apply Configuration
```bash
terraform apply
```
Creates all resources:
1. VPC network
2. Subnet
3. Two firewall rules
4. VM instance (runs startup script)

### Step 4: Access Your Web Server
Once deployed, you can:
- **SSH into the VM**:
  ```bash
  gcloud compute ssh tech-instance --zone=us-central1-a
  ```
- **Access the web server**: Find the external IP and visit it in your browser

---

## Key Takeaways

✅ **Firewall**: Protects your infrastructure by controlling network traffic using rules
✅ **VM Instance**: Runs your applications and services
✅ **VPC & Subnet**: Provides isolated, controlled network environment
✅ **Startup Script**: Automates initial setup (no manual configuration needed)
✅ **Tags**: Link firewall rules to specific instances without hardcoding IPs
✅ **Infrastructure as Code**: Terraform makes this repeatable and version-controlled

---

