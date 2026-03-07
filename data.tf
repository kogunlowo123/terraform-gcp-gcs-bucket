data "google_project" "current" {
  project_id = var.project_id
}

data "google_client_config" "current" {}

data "google_storage_project_service_account" "gcs_account" {
  project = var.project_id
}
