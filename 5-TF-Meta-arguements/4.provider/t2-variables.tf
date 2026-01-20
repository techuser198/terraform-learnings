variable "gcp_project" {
  description = "Project in which GCP Resources to be created"
  type = string
  default = "terraform-project-484318"
}

variable "gcp_region_primary" {
  description = "Primary region"
  type = string
  default = "us-central1"
}

variable "gcp_region_secondary" {
  description = "Secondary region"
  type = string
  default = "us-east1"
}

variable "machine_type" {
  description = "Compute Engine Machine Type"
  type = string
  default = "e2-small"
}

variable "ip_cidr_primary" {
  description = "CIDR range for primary VPC"
  type = string
  default = "10.128.0.0/20"
}

variable "ip_cidr_secondary" {
  description = "CIDR range for secondary VPC"
  type = string
  default = "10.129.0.0/20"
}

variable "machine_name" {
  description = "Name of the VM Instance"
  type = string
  default = "tech-instance"
}

variable "machine_image" {
  description = "The image to use for the boot disk"
  type = string
  default = "debian-cloud/debian-12"
}
