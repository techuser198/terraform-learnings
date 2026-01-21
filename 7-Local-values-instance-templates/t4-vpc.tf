resource "google_compute_network" "techvpc" {
  name = "techvpc1" 
  auto_create_subnetworks = false    
}

resource "google_compute_subnetwork" "techsubnet" {
  name          = "${local.region}-subnet"
  region        = local.region
  ip_cidr_range = var.ip_cidr
  network       = google_compute_network.techvpc.id 
}

