resource "google_compute_instance" "tech-instance" {
  # Explicit dependency on Storage Bucket and Firewall rules
  # Even though network dependency is implicit, we make backup dependent on storage
  depends_on = [
    google_storage_bucket.backup-bucket,
    google_compute_firewall.fw_ssh,
    google_compute_firewall.fw_http
  ]
  
  count = 2
  name         = "${var.machine_name}-${count.index}"
  machine_type = var.machine_type
  zone         = "${var.gcp_region1}-a"
  tags        = ["ssh-tag","webserver-tag"]
  boot_disk {
    initialize_params {
      image = var.machine_image
    }
  }
  # Install Webserver
  metadata_startup_script = file("${path.module}/startup-script.sh")
  network_interface {
    subnetwork = google_compute_subnetwork.techsubnet.id 
    access_config {
      # Include this section to give the VM an external IP address
    }
  }
}
