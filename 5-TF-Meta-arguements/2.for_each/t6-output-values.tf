# Output all instances using splat syntax
output "all_instance_names" {
  description = "Names of all instances"
  value = [for name, instance in google_compute_instance.tech-instance : instance.name]
}

output "all_instance_ips" {
  description = "External IPs of all instances"
  value = {
    for name, instance in google_compute_instance.tech-instance :
    name => instance.network_interface[0].access_config[0].nat_ip
  }
}

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
