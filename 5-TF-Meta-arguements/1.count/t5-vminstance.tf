resource "google_compute_instance" "tech-instance" {
  count = 2
  name         = "${var.machine_name}-${count.index}" #for now we are going to create instances with same name but different index in same region + zone
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