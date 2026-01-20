variable "gcp_project" {
  description = "Project in which GCP Resources to be created"
  type = string
  default = "terraform-project-484318"
}

variable "gcp_region1" {
  description = "Region in which GCP Resources to be created"
  type = string
  default = "us-central1"
}

variable "machine_type" {
  description = "Compute Engine Machine Type"
  type = string
  default = "e2-small"
}

variable "ip_cidr" {
  description = "CIDR range for the VPC network"
  type        = string
  default     = "10.128.0.0/20"
}

variable "machine_name" {
  description = "Name of the VM Instance"
  type = string
  default = "tech-instance"
}

variable "machine_image" {
  description = "The image to use for the boot disk"
  type        = string
  default     = "debian-cloud/debian-12"
}
