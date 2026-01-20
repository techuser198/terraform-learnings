# Get each list item separately
output "instance_0_name" {
  description = "VM Name"
  value = google_compute_instance.tech-instance[0].name
}

# Get each list item separately
output "instance_1_name" {
  description = "VM Name"
  value = google_compute_instance.tech-instance[1].name
}

