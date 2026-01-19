resource "google_compute_instance" "tech-instance" {
  name         = var.machine_name
  machine_type = var.machine_type
  zone         = "${var.gcp_region1}-a"
  tags        = ["ssh-tag","webserver-tag"]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
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