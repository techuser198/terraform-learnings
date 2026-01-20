# PRIMARY REGION RESOURCES
# VPC in Primary Region (us-central1)
resource "google_compute_network" "techvpc_primary" {
  provider = google.primary  # ← Use primary provider
  name = "techvpc-primary" 
  auto_create_subnetworks = false    
}

resource "google_compute_subnetwork" "techsubnet_primary" {
  provider = google.primary  # ← Use primary provider
  name          = "primary-subnet"
  region        = var.gcp_region_primary
  ip_cidr_range = var.ip_cidr_primary
  network       = google_compute_network.techvpc_primary.id 
}

# SECONDARY REGION RESOURCES
# VPC in Secondary Region (asia-southeast1)
resource "google_compute_network" "techvpc_secondary" {
  provider = google.secondary  # ← Use secondary provider
  name = "techvpc-secondary" 
  auto_create_subnetworks = false    
}

resource "google_compute_subnetwork" "techsubnet_secondary" {
  provider = google.secondary  # ← Use secondary provider
  name          = "secondary-subnet"
  region        = var.gcp_region_secondary
  ip_cidr_range = var.ip_cidr_secondary
  network       = google_compute_network.techvpc_secondary.id 
}
