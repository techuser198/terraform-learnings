output "instances_ids" {
  description = "IDs of created instances"
  value       = google_compute_instance.tech-instance[*].id
}

output "instances_names" {
  description = "Names of created instances"
  value       = google_compute_instance.tech-instance[*].name
}

output "instances_internal_ips" {
  description = "Internal IPs of created instances"
  value       = google_compute_instance.tech-instance[*].network_interface[0].network_ip
}

output "instances_external_ips" {
  description = "External IPs of created instances"
  value       = google_compute_instance.tech-instance[*].network_interface[0].access_config[0].nat_ip
}

output "vpc_id" {
  description = "VPC ID"
  value       = google_compute_network.techvpc.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = google_compute_subnetwork.techsubnet.id
}

output "instance_count" {
  description = "Total instances created"
  value       = var.instance_count
}
