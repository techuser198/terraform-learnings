#output values
output "tech-instance_instanceid" {
  description = "VM Instance ID"
  value = google_compute_instance.tech-instance.instance_id
}

output "tech-instance_selflink" {
  description = "VM Instance Self link"
  value = google_compute_instance.tech-instance.self_link
}

output "tech-instance_id" {
  description = "VM ID"
  value = google_compute_instance.tech-instance.id
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