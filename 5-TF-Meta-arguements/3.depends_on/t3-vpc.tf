# Resource: VPC (Must be created first)
resource "google_compute_network" "techvpc" {
  name = "techvpc1" 
  auto_create_subnetworks = false    
}

# Resource: Subnet (Depends on VPC)
resource "google_compute_subnetwork" "techsubnet" {
  name          = "${var.gcp_region1}-subnet"
  region        = var.gcp_region1
  ip_cidr_range = var.ip_cidr
  network       = google_compute_network.techvpc.id 
}

# Resource: Cloud Storage Bucket (Independent resource for demo)
resource "google_storage_bucket" "backup-bucket" {
  name = "${var.gcp_project}-backup-bucket-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  location = var.gcp_region1
}
