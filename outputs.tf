output "bucket_name" {
  description = "The name of the bucket."
  value       = google_storage_bucket.this.name
}

output "bucket_self_link" {
  description = "The self link of the bucket."
  value       = google_storage_bucket.this.self_link
}

output "bucket_url" {
  description = "The URL of the bucket (gs://...)."
  value       = google_storage_bucket.this.url
}

output "bucket_id" {
  description = "The ID of the bucket."
  value       = google_storage_bucket.this.id
}

output "bucket_location" {
  description = "The location of the bucket."
  value       = google_storage_bucket.this.location
}

output "bucket_storage_class" {
  description = "The storage class of the bucket."
  value       = google_storage_bucket.this.storage_class
}

output "bucket_project" {
  description = "The project containing the bucket."
  value       = google_storage_bucket.this.project
}

output "bucket_versioning_enabled" {
  description = "Whether versioning is enabled."
  value       = var.versioning_enabled
}

output "bucket_uniform_access" {
  description = "Whether uniform bucket-level access is enabled."
  value       = google_storage_bucket.this.uniform_bucket_level_access
}

output "gcs_service_account" {
  description = "The GCS service account email for the project."
  value       = data.google_storage_project_service_account.gcs_account.email_address
}

output "effective_labels" {
  description = "The effective labels on the bucket."
  value       = google_storage_bucket.this.effective_labels
}

output "notification_ids" {
  description = "List of notification IDs."
  value       = [for n in google_storage_notification.notifications : n.notification_id]
}
