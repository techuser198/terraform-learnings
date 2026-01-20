variable "gcp_project" {
  description = "GCP Project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "vpc_name" {
  description = "VPC Network Name"
  type        = string
  default     = "techvpc"
}

variable "subnet_name" {
  description = "Subnet Name"
  type        = string
  default     = "techsubnet"
}

variable "ip_cidr" {
  description = "IP CIDR for Subnet"
  type        = string
  default     = "10.128.0.0/20"
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Machine type for instances"
  type        = string
  default     = "e2-micro"
}

variable "instance_version" {
  description = "Version tag for instances - change to trigger replacement"
  type        = string
  default     = "v1.0"
}
