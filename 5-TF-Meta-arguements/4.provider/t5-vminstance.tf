# PRIMARY REGION INSTANCE
resource "google_compute_instance" "tech-instance-primary" {
  provider = google.primary  # ← Use primary provider
  
  name         = "${var.machine_name}-primary"
  machine_type = var.machine_type
  zone         = "${var.gcp_region_primary}-a"
  tags        = ["ssh-tag","webserver-tag"]
  boot_disk {
    initialize_params {
      image = var.machine_image
    }
  }
  metadata_startup_script = file("${path.module}/startup-script.sh")
  network_interface {
    subnetwork = google_compute_subnetwork.techsubnet_primary.id 
    access_config {
      # External IP
    }
  }
}

# SECONDARY REGION INSTANCE
resource "google_compute_instance" "tech-instance-secondary" {
  provider = google.secondary  # ← Use secondary provider
  
  name         = "${var.machine_name}-secondary"
  machine_type = var.machine_type
  zone         = "${var.gcp_region_secondary}-b"  # Note: zone in secondary region
  tags        = ["ssh-tag","webserver-tag"]
  boot_disk {
    initialize_params {
      image = var.machine_image
    }
  }
  metadata_startup_script = file("${path.module}/startup-script.sh")
  network_interface {
    subnetwork = google_compute_subnetwork.techsubnet_secondary.id 
    access_config {
      # External IP
    }
  }
}
