#output values from data sources
output "available_zones" {
  description = "List of available zones in the region with UP status"
  value = data.google_compute_zones.available_zones.names
}


output "debian_image_id" {
  description = "Latest Debian 12 Image ID"
  value = data.google_compute_image.debian_image.id
}

output "debian_image_name" {
  description = "Latest Debian 12 Image Name"
  value = data.google_compute_image.debian_image.name
}

output "debian_image_self_link" {
  description = "Latest Debian 12 Image Self Link"
  value = data.google_compute_image.debian_image.self_link
}

# Output values from VM Instances (with count)
output "tech-instance_instanceids" {
  description = "VM Instance IDs (all 3 instances)"
  value = google_compute_instance.tech-instance[*].instance_id
}

output "tech-instance_selflinks" {
  description = "VM Instance Self links (all 3 instances)"
  value = google_compute_instance.tech-instance[*].self_link
}

output "tech-instance_ids" {
  description = "VM IDs (all 3 instances)"
  value = google_compute_instance.tech-instance[*].id
}

output "tech-instance_external_ips" {
  description = "VM External IPs (all 3 instances)"
  value = [for instance in google_compute_instance.tech-instance[*] : instance.network_interface[0].access_config[0].nat_ip]
}

output "tech-instance_names" {
  description = "VM Names (all 3 instances)"
  value = google_compute_instance.tech-instance[*].name
}

output "tech-instance_machine_types" {
  description = "VM Machine Types (all 3 instances)"
  value = google_compute_instance.tech-instance[*].machine_type
}

output "tech-instance_zones" {
  description = "VM Zones (all 3 instances with their assigned zones)"
  value = google_compute_instance.tech-instance[*].zone
}