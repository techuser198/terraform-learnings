# Resource: VPC
resource "google_compute_network" "techvpc" {
  name = "techvpc1" #the name of the vpc you want to create
  auto_create_subnetworks = false    
}

# Resource: Subnet
resource "google_compute_subnetwork" "techsubnet" {
  name          = "tech-subnet1"
  region        = "us-central1"
  ip_cidr_range = "10.128.0.0/20"
  network       = google_compute_network.techvpc.id  // GET VPC ID
}

