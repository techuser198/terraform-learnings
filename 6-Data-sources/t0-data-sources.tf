# Data source to fetch available compute zones in the region
# This queries Google Cloud to get zones where status = "UP"
data "google_compute_zones" "available_zones" {
  project = var.gcp_project
  region  = var.gcp_region1
  status  = "UP"
}

# Data source to fetch the latest Debian 12 image
# Instead of hardcoding the image, we fetch the latest available
data "google_compute_image" "debian_image" {
  family  = "debian-12"
  project = "debian-cloud"
}
