module "test" {
  source = "../"

  project_id                  = "test-project-id"
  name                        = "test-project-data-bucket"
  location                    = "US"
  storage_class               = "STANDARD"
  force_destroy               = true
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  versioning_enabled          = true

  labels = {
    environment = "test"
    managed_by  = "terraform"
  }

  lifecycle_rules = [
    {
      action = {
        type          = "SetStorageClass"
        storage_class = "NEARLINE"
      }
      condition = {
        age = 30
      }
    },
    {
      action = {
        type = "SetStorageClass"
        storage_class = "COLDLINE"
      }
      condition = {
        age = 90
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

  soft_delete_policy = {
    retention_duration_seconds = 604800
  }

  iam_bindings = {
    "roles/storage.objectViewer" = [
      "serviceAccount:app-reader@test-project-id.iam.gserviceaccount.com"
    ]
  }
}
