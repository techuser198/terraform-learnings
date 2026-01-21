
resource "google_compute_instance_template" "tech_template" {
  name_prefix  = "${local.app_name}-template-"
  description  = "Instance template for ${local.app_name}"
  machine_type = local.machine_type
  
  # Boot Disk Configuration
  disk {
    source_image = local.boot_image
    boot         = true
    disk_size_gb = 10
    disk_type    = "pd-standard"
    auto_delete  = true
  }
  
  # Networking Configuration
  network_interface {
    network    = local.network_id
    subnetwork = local.subnet_id
    
    access_config {}
  }
  
  # Metadata 
  metadata = local.instance_metadata
  
  # Labels for organization
  labels = local.instance_labels
  
  # Tags for firewall rules targeting
  tags = ["ssh-tag", "webserver-tag"]
}
