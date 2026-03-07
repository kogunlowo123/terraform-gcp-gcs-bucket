###############################################################################
# Google Cloud Storage Bucket
###############################################################################
resource "google_storage_bucket" "this" {
  provider = google-beta

  project                     = var.project_id
  name                        = var.name
  location                    = var.location
  storage_class               = var.storage_class
  force_destroy               = var.force_destroy
  uniform_bucket_level_access = var.uniform_bucket_level_access
  public_access_prevention    = var.public_access_prevention
  requester_pays              = var.requester_pays
  default_event_based_hold    = var.default_event_based_hold
  labels                      = local.merged_labels

  versioning {
    enabled = var.versioning_enabled
  }

  # Lifecycle rules
  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lifecycle_rule.value.action.storage_class
      }
      condition {
        age                                     = lifecycle_rule.value.condition.age
        created_before                          = lifecycle_rule.value.condition.created_before
        with_state                              = lifecycle_rule.value.condition.with_state
        matches_storage_class                   = lifecycle_rule.value.condition.matches_storage_class
        matches_prefix                          = lifecycle_rule.value.condition.matches_prefix
        matches_suffix                          = lifecycle_rule.value.condition.matches_suffix
        num_newer_versions                      = lifecycle_rule.value.condition.num_newer_versions
        days_since_noncurrent_time              = lifecycle_rule.value.condition.days_since_noncurrent_time
        noncurrent_time_before                  = lifecycle_rule.value.condition.noncurrent_time_before
        days_since_custom_time                  = lifecycle_rule.value.condition.days_since_custom_time
        custom_time_before                      = lifecycle_rule.value.condition.custom_time_before
        send_days_since_noncurrent_time_if_zero = lifecycle_rule.value.condition.send_days_since_noncurrent_time_if_zero
        send_days_since_custom_time_if_zero     = lifecycle_rule.value.condition.send_days_since_custom_time_if_zero
        send_num_newer_versions_if_zero         = lifecycle_rule.value.condition.send_num_newer_versions_if_zero
      }
    }
  }

  # CORS configuration
  dynamic "cors" {
    for_each = var.cors
    content {
      origin          = cors.value.origin
      method          = cors.value.method
      response_header = cors.value.response_header
      max_age_seconds = cors.value.max_age_seconds
    }
  }

  # Retention policy
  dynamic "retention_policy" {
    for_each = var.retention_policy != null ? [var.retention_policy] : []
    content {
      retention_period = retention_policy.value.retention_period
      is_locked        = retention_policy.value.is_locked
    }
  }

  # CMEK encryption
  dynamic "encryption" {
    for_each = var.encryption != null ? [var.encryption] : []
    content {
      default_kms_key_name = encryption.value.default_kms_key_name
    }
  }

  # Access logging
  dynamic "logging" {
    for_each = var.logging != null ? [var.logging] : []
    content {
      log_bucket        = logging.value.log_bucket
      log_object_prefix = logging.value.log_object_prefix
    }
  }

  # Static website
  dynamic "website" {
    for_each = var.website != null ? [var.website] : []
    content {
      main_page_suffix = website.value.main_page_suffix
      not_found_page   = website.value.not_found_page
    }
  }

  # Custom dual-region placement
  dynamic "custom_placement_config" {
    for_each = var.custom_placement_config != null ? [var.custom_placement_config] : []
    content {
      data_locations = custom_placement_config.value.data_locations
    }
  }

  # Autoclass
  dynamic "autoclass" {
    for_each = var.autoclass != null ? [var.autoclass] : []
    content {
      enabled                = autoclass.value.enabled
      terminal_storage_class = autoclass.value.terminal_storage_class
    }
  }

  # Soft delete policy
  dynamic "soft_delete_policy" {
    for_each = var.soft_delete_policy != null ? [var.soft_delete_policy] : []
    content {
      retention_duration_seconds = soft_delete_policy.value.retention_duration_seconds
    }
  }
}

###############################################################################
# IAM Bindings
###############################################################################
resource "google_storage_bucket_iam_member" "bindings" {
  for_each = {
    for binding in local.iam_bindings_flat :
    "${binding.role}-${binding.member}" => binding
  }

  bucket = google_storage_bucket.this.name
  role   = each.value.role
  member = each.value.member
}

###############################################################################
# Pub/Sub Notifications
###############################################################################
resource "google_storage_notification" "notifications" {
  count = length(var.notifications)

  bucket             = google_storage_bucket.this.name
  topic              = var.notifications[count.index].topic
  payload_format     = var.notifications[count.index].payload_format
  event_types        = var.notifications[count.index].event_types
  object_name_prefix = var.notifications[count.index].object_name_prefix
  custom_attributes  = var.notifications[count.index].custom_attributes

  depends_on = [google_storage_bucket.this]
}
