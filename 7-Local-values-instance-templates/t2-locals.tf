locals {
  # Project and Region Configuration
  project_id = var.gcp_project
  region     = var.gcp_region1
  
  # Naming Convention Locals
  environment = "production"
  app_name    = "tech-app"
  instance_name = "${local.app_name}-instance"
  
  # Instance Template Configuration
  instance_template_name = "${local.app_name}-template"
  
  # Machine Configuration
  machine_type = var.machine_type
  
  # Zone Configuration (from data source)
  available_zones = data.google_compute_zones.available_zones.names
  instance_zone   = local.available_zones[0]
  
  # Image Configuration (from data source)
  boot_image = data.google_compute_image.debian_image.self_link
 
    # Startup Script Path
  startup_script_path = "${path.module}/startup-script.sh"
 
  # Zone Configuration
  instance_metadata = {
    "environment"    = local.environment
    "application"    = local.app_name
    "created_by"     = "terraform"
    "creation_time"  = timestamp()
    "startup-script" = file(local.startup_script_path)
  }
  
  # Labels for instances
  instance_labels = {
    "environment"    = local.environment
    "application"    = local.app_name
    "terraform"      = "true"
    "managed_by"     = "terraform"
  }
  
  # Networking Configuration
  network_id  = google_compute_network.techvpc.id
  subnet_id   = google_compute_subnetwork.techsubnet.id
  
}
