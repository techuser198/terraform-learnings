output "instance_names" {
  description = "VM Names"
  value = google_compute_instance.tech-instance[*].name
}

output "instance_external_ips" {
  description = "VM External IPs"
  value = google_compute_instance.tech-instance[*].network_interface[0].access_config[0].nat_ip
}

output "backup_bucket_name" {
  description = "Backup Storage Bucket Name"
  value = google_storage_bucket.backup-bucket.name
}

output "vpc_id" {
  description = "VPC Network ID"
  value = google_compute_network.techvpc.id
}
