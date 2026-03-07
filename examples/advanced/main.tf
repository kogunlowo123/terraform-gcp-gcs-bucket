provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
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

# Data bucket with lifecycle rules and IAM
module "data_bucket" {
  source = "../../"

  project_id         = var.project_id
  name               = "${var.project_id}-data-advanced"
  location           = "us-central1"
  storage_class      = "STANDARD"
  versioning_enabled = true

  lifecycle_rules = [
    # Transition to Nearline after 30 days
    {
      action = {
        type          = "SetStorageClass"
        storage_class = "NEARLINE"
      }
      condition = {
        age = 30
      }
    },
    # Transition to Coldline after 90 days
    {
      action = {
        type          = "SetStorageClass"
        storage_class = "COLDLINE"
      }
      condition = {
        age = 90
      }
    },
    # Delete after 365 days
    {
      action = {
        type = "Delete"
      }
      condition = {
        age = 365
      }
    },
    # Delete old versions after 30 days
    {
      action = {
        type = "Delete"
      }
      condition = {
        num_newer_versions = 3
        with_state         = "ARCHIVED"
      }
    },
    # Delete incomplete multipart uploads after 7 days
    {
      action = {
        type = "AbortIncompleteMultipartUpload"
      }
      condition = {
        age = 7
      }
    }
  ]

  cors = [
    {
      origin          = ["https://app.example.com", "https://admin.example.com"]
      method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
      response_header = ["Content-Type", "Content-Disposition", "Cache-Control"]
      max_age_seconds = 3600
    }
  ]

  iam_bindings = {
    "roles/storage.objectViewer" = [
      "group:developers@example.com",
    ]
    "roles/storage.objectCreator" = [
      "serviceAccount:data-pipeline@${var.project_id}.iam.gserviceaccount.com",
    ]
    "roles/storage.objectAdmin" = [
      "serviceAccount:admin@${var.project_id}.iam.gserviceaccount.com",
    ]
  }

  soft_delete_policy = {
    retention_duration_seconds = 604800 # 7 days
  }

  labels = {
    environment = "staging"
    team        = "data-engineering"
    cost-center = "analytics"
  }
}

# Log bucket for access logs
module "log_bucket" {
  source = "../../"

  project_id    = var.project_id
  name          = "${var.project_id}-access-logs"
  location      = "us-central1"
  storage_class = "NEARLINE"

  lifecycle_rules = [
    {
      action = {
        type = "Delete"
      }
      condition = {
        age = 90
      }
    }
  ]

  labels = {
    environment = "staging"
    purpose     = "access-logs"
  }
}

output "data_bucket_name" {
  description = "Data bucket name."
  value       = module.data_bucket.bucket_name
}

output "data_bucket_url" {
  description = "Data bucket URL."
  value       = module.data_bucket.bucket_url
}

output "log_bucket_name" {
  description = "Log bucket name."
  value       = module.log_bucket.bucket_name
}
