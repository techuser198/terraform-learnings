# ============================================
# Output Values
# - Exposes important values from locals, data sources, and resources
# - Instance template information
# - Single instance information
# - Network and firewall information
# ============================================

# ============================================
# Local Values Outputs
# ============================================

output "local_project_id" {
  description = "Project ID from local values"
  value       = local.project_id
}

output "local_region" {
  description = "Region from local values"
  value       = local.region
}

output "local_instance_zone" {
  description = "Instance zone from local values"
  value       = local.instance_zone
}

output "local_machine_type" {
  description = "Machine type from local values"
  value       = local.machine_type
}

output "local_app_name" {
  description = "Application name from local values"
  value       = local.app_name
}

output "local_instance_name" {
  description = "Instance name from local values"
  value       = local.instance_name
}

output "local_environment" {
  description = "Environment from local values"
  value       = local.environment
}

output "local_instance_labels" {
  description = "Instance labels from local values"
  value       = local.instance_labels
}

# ============================================
# Data Sources Outputs
# ============================================

output "available_zones" {
  description = "List of available zones in the region with UP status"
  value       = data.google_compute_zones.available_zones.names
}

output "debian_image_id" {
  description = "Latest Debian 12 Image ID"
  value       = data.google_compute_image.debian_image.id
}

output "debian_image_name" {
  description = "Latest Debian 12 Image Name"
  value       = data.google_compute_image.debian_image.name
}

output "debian_image_self_link" {
  description = "Latest Debian 12 Image Self Link"
  value       = data.google_compute_image.debian_image.self_link
}

# ============================================
# Instance Template Outputs
# ============================================

output "instance_template_id" {
  description = "Instance Template ID"
  value       = google_compute_instance_template.tech_template.id
}

output "instance_template_self_link" {
  description = "Instance Template Self Link"
  value       = google_compute_instance_template.tech_template.self_link
}

output "instance_template_name" {
  description = "Instance Template Name"
  value       = google_compute_instance_template.tech_template.name
}

# ============================================
# VM Instance Outputs (Single Instance)
# ============================================

output "instance_id" {
  description = "VM Instance ID"
  value       = google_compute_instance_from_template.tech_app.instance_id
}

output "instance_name" {
  description = "VM Instance Name"
  value       = google_compute_instance_from_template.tech_app.name
}

output "instance_zone" {
  description = "VM Instance Zone"
  value       = google_compute_instance_from_template.tech_app.zone
}

output "instance_machine_type" {
  description = "VM Machine Type"
  value       = google_compute_instance_from_template.tech_app.machine_type
}

output "instance_self_link" {
  description = "VM Instance Self Link"
  value       = google_compute_instance_from_template.tech_app.self_link
}

output "instance_external_ip" {
  description = "VM External IP (for SSH access)"
  value       = google_compute_instance_from_template.tech_app.network_interface[0].access_config[0].nat_ip
}

output "instance_internal_ip" {
  description = "VM Internal IP (Private IP)"
  value       = google_compute_instance_from_template.tech_app.network_interface[0].network_ip
}

output "instance_labels" {
  description = "VM Instance Labels"
  value       = google_compute_instance_from_template.tech_app.labels
}

# ============================================
# Network Outputs
# ============================================

output "vpc_network_id" {
  description = "VPC Network ID"
  value       = google_compute_network.techvpc.id
}

output "vpc_network_self_link" {
  description = "VPC Network Self Link"
  value       = google_compute_network.techvpc.self_link
}

output "subnet_id" {
  description = "Subnet ID"
  value       = google_compute_subnetwork.techsubnet.id
}

output "subnet_self_link" {
  description = "Subnet Self Link"
  value       = google_compute_subnetwork.techsubnet.self_link
}

output "subnet_ip_range" {
  description = "Subnet IP CIDR Range"
  value       = google_compute_subnetwork.techsubnet.ip_cidr_range
}

# ============================================
# Firewall Rules Outputs
# ============================================

output "firewall_ssh_id" {
  description = "SSH Firewall Rule ID"
  value       = google_compute_firewall.fw_ssh.id
}

output "firewall_http_id" {
  description = "HTTP Firewall Rule ID"
  value       = google_compute_firewall.fw_http.id
}

# ============================================
# Summary Output
# ============================================

output "deployment_summary" {
  description = "Summary of the deployment"
  value = {
    project_id        = local.project_id
    region            = local.region
    instance_zone     = local.instance_zone
    application       = local.app_name
    instance_name     = local.instance_name
    environment       = local.environment
    machine_type      = local.machine_type
    external_ip       = google_compute_instance_from_template.tech_app.network_interface[0].access_config[0].nat_ip
    internal_ip       = google_compute_instance_from_template.tech_app.network_interface[0].network_ip
    template_used     = google_compute_instance_template.tech_template.name
  }
}

# ============================================
# SSH Access Command
# ============================================

output "ssh_command" {
  description = "SSH command to access the instance"
  value       = "gcloud compute ssh ${google_compute_instance_from_template.tech_app.name} --zone=${google_compute_instance_from_template.tech_app.zone} --project=${local.project_id}"
}

output "connect_info" {
  description = "Quick connection information"
  value = {
    command      = "gcloud compute ssh ${google_compute_instance_from_template.tech_app.name} --zone=${google_compute_instance_from_template.tech_app.zone}"
    external_ip  = google_compute_instance_from_template.tech_app.network_interface[0].access_config[0].nat_ip
    internal_ip  = google_compute_instance_from_template.tech_app.network_interface[0].network_ip
    hint         = "Copy the command above and run it to SSH into the instance"
  }
}
