resource "google_compute_instance" "tech-instance" {
  count        = 3
  name         = "${var.machine_name}-${count.index}"
  machine_type = var.machine_type
  # Using data source to get zones dynamically based on count.index
  zone         = data.google_compute_zones.available_zones.names[count.index]
  tags        = ["ssh-tag","webserver-tag"]
  boot_disk {
    initialize_params {
      # Using data source to get the latest Debian 12 image
      image = data.google_compute_image.debian_image.self_link
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

