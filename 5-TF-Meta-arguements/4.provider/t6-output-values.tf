output "primary_instance_ip" {
  description = "Primary Region - Instance External IP"
  value = google_compute_instance.tech-instance-primary.network_interface[0].access_config[0].nat_ip
}

output "primary_instance_zone" {
  description = "Primary Region - Instance Zone"
  value = google_compute_instance.tech-instance-primary.zone
}

output "secondary_instance_ip" {
  description = "Secondary Region - Instance External IP"
  value = google_compute_instance.tech-instance-secondary.network_interface[0].access_config[0].nat_ip
}

output "secondary_instance_zone" {
  description = "Secondary Region - Instance Zone"
  value = google_compute_instance.tech-instance-secondary.zone
}

output "primary_vpc_id" {
  description = "Primary VPC ID"
  value = google_compute_network.techvpc_primary.id
}

output "secondary_vpc_id" {
  description = "Secondary VPC ID"
  value = google_compute_network.techvpc_secondary.id
}
