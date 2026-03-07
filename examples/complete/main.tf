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

variable "kms_key_name" {
  description = "Cloud KMS key for bucket encryption."
  type        = string
  default     = null
}

variable "notification_topic" {
  description = "Pub/Sub topic for bucket notifications."
  type        = string
  default     = null
}

# Primary data bucket with full configuration
module "primary_bucket" {
  source = "../../"

  project_id                  = var.project_id
  name                        = "${var.project_id}-primary-data"
  location                    = "us-central1"
  storage_class               = "STANDARD"
  force_destroy               = false
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  versioning_enabled          = true
  requester_pays              = false

  # CMEK encryption
  encryption = var.kms_key_name != null ? {
    default_kms_key_name = var.kms_key_name
  } : null

  # Comprehensive lifecycle rules
  lifecycle_rules = [
    # Transition current objects through storage classes
    {
      action = {
        type          = "SetStorageClass"
        storage_class = "NEARLINE"
      }
      condition = {
        age                   = 30
        matches_storage_class = ["STANDARD"]
      }
    },
    {
      action = {
        type          = "SetStorageClass"
        storage_class = "COLDLINE"
      }
      condition = {
        age                   = 90
        matches_storage_class = ["NEARLINE"]
      }
    },
    {
      action = {
        type          = "SetStorageClass"
        storage_class = "ARCHIVE"
      }
      condition = {
        age                   = 365
        matches_storage_class = ["COLDLINE"]
      }
    },
    # Delete archived objects after 7 years
    {
      action = {
        type = "Delete"
      }
      condition = {
        age                   = 2555
        matches_storage_class = ["ARCHIVE"]
      }
    },
    # Manage noncurrent versions
    {
      action = {
        type = "Delete"
      }
      condition = {
        days_since_noncurrent_time = 30
        num_newer_versions         = 5
      }
    },
    # Delete temp files after 1 day
    {
      action = {
        type = "Delete"
      }
      condition = {
        age            = 1
        matches_prefix = ["tmp/", "temp/", "staging/"]
      }
    },
    # Delete log files after 90 days
    {
      action = {
        type = "Delete"
      }
      condition = {
        age            = 90
        matches_suffix = [".log", ".log.gz"]
      }
    },
    # Abort incomplete multipart uploads
    {
      action = {
        type = "AbortIncompleteMultipartUpload"
      }
      condition = {
        age = 3
      }
    }
  ]

  # CORS for web application access
  cors = [
    {
      origin          = ["https://app.example.com", "https://admin.example.com"]
      method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
      response_header = ["Content-Type", "Content-Disposition", "Cache-Control", "X-Upload-Content-Length"]
      max_age_seconds = 3600
    }
  ]

  # Retention policy (30 days minimum retention)
  retention_policy = {
    retention_period = 2592000 # 30 days
    is_locked        = false
  }

  # Soft delete
  soft_delete_policy = {
    retention_duration_seconds = 604800 # 7 days
  }

  # Access logging
  logging = {
    log_bucket        = module.log_bucket.bucket_name
    log_object_prefix = "primary-data/"
  }

  # IAM bindings
  iam_bindings = {
    "roles/storage.objectViewer" = [
      "group:data-analysts@example.com",
      "serviceAccount:reporting@${var.project_id}.iam.gserviceaccount.com",
    ]
    "roles/storage.objectCreator" = [
      "serviceAccount:data-pipeline@${var.project_id}.iam.gserviceaccount.com",
      "serviceAccount:etl-worker@${var.project_id}.iam.gserviceaccount.com",
    ]
    "roles/storage.objectAdmin" = [
      "group:platform-admins@example.com",
    ]
    "roles/storage.legacyBucketReader" = [
      "serviceAccount:bigquery@${var.project_id}.iam.gserviceaccount.com",
    ]
  }

  # Pub/Sub notifications
  notifications = var.notification_topic != null ? [
    {
      topic          = var.notification_topic
      payload_format = "JSON_API_V1"
      event_types    = ["OBJECT_FINALIZE", "OBJECT_DELETE"]
      custom_attributes = {
        source = "primary-data-bucket"
      }
    },
    {
      topic              = var.notification_topic
      payload_format     = "JSON_API_V1"
      event_types        = ["OBJECT_FINALIZE"]
      object_name_prefix = "ingest/"
      custom_attributes = {
        source   = "primary-data-bucket"
        pipeline = "data-ingestion"
      }
    }
  ] : []

  labels = {
    environment     = "production"
    team            = "data-platform"
    cost-center     = "data-engineering"
    data-class      = "confidential"
    backup-required = "true"
  }
}

# Autoclass bucket for variable-access data
module "autoclass_bucket" {
  source = "../../"

  project_id                  = var.project_id
  name                        = "${var.project_id}-autoclass-data"
  location                    = "us-central1"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  versioning_enabled          = true

  autoclass = {
    enabled                = true
    terminal_storage_class = "ARCHIVE"
  }

  lifecycle_rules = [
    {
      action = {
        type = "Delete"
      }
      condition = {
        days_since_noncurrent_time = 90
      }
    }
  ]

  labels = {
    environment = "production"
    purpose     = "variable-access"
  }
}

# Log bucket
module "log_bucket" {
  source = "../../"

  project_id                  = var.project_id
  name                        = "${var.project_id}-access-logs-prod"
  location                    = "us-central1"
  storage_class               = "NEARLINE"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  lifecycle_rules = [
    {
      action = {
        type          = "SetStorageClass"
        storage_class = "COLDLINE"
      }
      condition = {
        age = 30
      }
    },
    {
      action = {
        type = "Delete"
      }
      condition = {
        age = 365
      }
    }
  ]

  labels = {
    environment = "production"
    purpose     = "access-logs"
  }
}

# Static website bucket
module "website_bucket" {
  source = "../../"

  project_id                  = var.project_id
  name                        = "${var.project_id}-static-website"
  location                    = "US"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "inherited"

  website = {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }

  cors = [
    {
      origin          = ["*"]
      method          = ["GET", "HEAD"]
      response_header = ["Content-Type"]
      max_age_seconds = 86400
    }
  ]

  iam_bindings = {
    "roles/storage.objectViewer" = [
      "allUsers",
    ]
  }

  labels = {
    environment = "production"
    purpose     = "website"
  }
}

output "primary_bucket_name" {
  description = "Primary data bucket name."
  value       = module.primary_bucket.bucket_name
}

output "primary_bucket_url" {
  description = "Primary data bucket URL."
  value       = module.primary_bucket.bucket_url
}

output "autoclass_bucket_name" {
  description = "Autoclass bucket name."
  value       = module.autoclass_bucket.bucket_name
}

output "log_bucket_name" {
  description = "Log bucket name."
  value       = module.log_bucket.bucket_name
}

output "website_bucket_name" {
  description = "Website bucket name."
  value       = module.website_bucket.bucket_name
}

output "website_bucket_url" {
  description = "Website bucket URL."
  value       = module.website_bucket.bucket_url
}

output "gcs_service_account" {
  description = "GCS service account for the project."
  value       = module.primary_bucket.gcs_service_account
}

output "notification_ids" {
  description = "Primary bucket notification IDs."
  value       = module.primary_bucket.notification_ids
}
