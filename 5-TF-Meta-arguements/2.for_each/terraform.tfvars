gcp_project = "terraform-project-484318"
gcp_region1 = "us-central1"

instances = {
  "web-server-1" = {
    machine_type = "e2-micro"
    zone         = "us-central1-a"
  }
  "web-server-2" = {
    machine_type = "e2-small"
    zone         = "us-central1-b"
  }
  "db-server" = {
    machine_type = "n1-standard-1"
    zone         = "us-central1-c"
  }
}
