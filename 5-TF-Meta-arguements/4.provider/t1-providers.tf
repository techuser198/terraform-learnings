# Terraform Settings Block
terraform {
  required_version = ">= 1.8.5"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 7.16"
      # Create provider aliases for multiple regions
      configuration_aliases = [google.primary, google.secondary]
    }
  }
}

# Primary Provider - US Central Region
provider "google" {
  alias   = "primary"
  project = var.gcp_project
  region  = var.gcp_region_primary
}

# Secondary Provider - US East Region (different region)
provider "google" {
  alias   = "secondary"
  project = var.gcp_project
  region  = var.gcp_region_secondary
}
