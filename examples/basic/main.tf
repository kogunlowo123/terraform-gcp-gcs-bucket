provider "google" {
  project = var.project_id
  region  = var.region
}

variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The GCP region."
  type        = string
  default     = "us-central1"
}

module "bucket" {
  source = "../../"

  project_id         = var.project_id
  name               = "${var.project_id}-basic-bucket"
  location           = "US"
  storage_class      = "STANDARD"
  versioning_enabled = true

  labels = {
    environment = "dev"
    team        = "platform"
  }
}

output "bucket_name" {
  description = "The bucket name."
  value       = module.bucket.bucket_name
}

output "bucket_url" {
  description = "The bucket URL."
  value       = module.bucket.bucket_url
}

output "bucket_self_link" {
  description = "The bucket self link."
  value       = module.bucket.bucket_self_link
}
