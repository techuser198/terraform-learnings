resource "google_compute_firewall" "fw_ssh" {
  name    = "techfw-allow-ssh"
  network = google_compute_network.techvpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-tag"]
}

resource "google_compute_firewall" "fw_http" {
  name    = "techfw-allow-http80"
  network = google_compute_network.techvpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["webserver-tag"]
}
