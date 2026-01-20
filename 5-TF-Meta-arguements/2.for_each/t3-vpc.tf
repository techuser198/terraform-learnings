# Resource: VPC
resource "google_compute_network" "techvpc" {
  name = "techvpc1" 
  auto_create_subnetworks = false    
}

# Resource: Subnet
resource "google_compute_subnetwork" "techsubnet" {
  name          = "${var.gcp_region1}-subnet"
  region        = var.gcp_region1
  ip_cidr_range = var.ip_cidr
  network       = google_compute_network.techvpc.id 
}
