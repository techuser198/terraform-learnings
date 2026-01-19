resource "google_compute_instance" "tech-instance" {
  name         = "tech-instance"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
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
  }
}