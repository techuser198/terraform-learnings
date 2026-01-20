resource "google_compute_network" "techvpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "techsubnet" {
  name          = var.subnet_name
  ip_cidr_range = var.ip_cidr
  region        = var.gcp_region
  network       = google_compute_network.techvpc.id
}
