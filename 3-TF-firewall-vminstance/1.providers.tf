# Terraform Settings Block
terraform {
  required_version = ">= 1.8.5"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 7.16"
    }
  }
}

# Terraform Provider Block
provider "google" {
  project = "terraform-project-484318" # PROJECT_ID
  region = "us-central1"
}



