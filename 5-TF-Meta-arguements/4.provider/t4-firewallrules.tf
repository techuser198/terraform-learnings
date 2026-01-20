# PRIMARY REGION FIREWALL RULES
resource "google_compute_firewall" "fw_ssh_primary" {
  provider = google.primary  # ← Use primary provider
  name = "primary-fw-allow-ssh22"
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.techvpc_primary.id 
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-tag"]
}

resource "google_compute_firewall" "fw_http_primary" {
  provider = google.primary  # ← Use primary provider
  name = "primary-fw-allow-http80"
  allow {
    ports    = ["80"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.techvpc_primary.id 
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["webserver-tag"]
}

# SECONDARY REGION FIREWALL RULES
resource "google_compute_firewall" "fw_ssh_secondary" {
  provider = google.secondary  # ← Use secondary provider
  name = "secondary-fw-allow-ssh22"
  allow {
    ports    = ["22"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.techvpc_secondary.id 
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-tag"]
}

resource "google_compute_firewall" "fw_http_secondary" {
  provider = google.secondary  # ← Use secondary provider
  name = "secondary-fw-allow-http80"
  allow {
    ports    = ["80"]
    protocol = "tcp"
  }
  direction     = "INGRESS"
  network       = google_compute_network.techvpc_secondary.id 
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["webserver-tag"]
}
