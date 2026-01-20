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

variable "ip_cidr" {
  description = "CIDR range for the VPC network"
  type        = string
  default     = "10.128.0.0/20"
}

variable "machine_image" {
  description = "The image to use for the boot disk"
  type        = string
  default     = "debian-cloud/debian-12"
}

# for_each variable: Map of instances with different configurations
variable "instances" {
  description = "Map of instance configurations"
  type = map(object({
    machine_type = string
    zone         = string
  }))
  default = {
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
}
