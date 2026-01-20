resource "google_compute_instance" "tech-instance" {
  for_each = var.instances  # ← THIS IS THE META-ARGUMENT
  
  name         = each.key          # Uses map key as name (web-server-1, web-server-2, db-server)
  machine_type = each.value.machine_type  # Gets machine_type from map value
  zone         = each.value.zone   # Gets zone from map value
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
