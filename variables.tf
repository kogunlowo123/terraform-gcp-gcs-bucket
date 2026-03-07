variable "project_id" {
  description = "The GCP project ID where the bucket will be created."
  type        = string

  validation {
    condition     = length(var.project_id) > 0
    error_message = "Project ID must not be empty."
  }
}

variable "name" {
  description = "The name of the bucket. Must be globally unique."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9._-]{1,220}[a-z0-9]$", var.name))
    error_message = "Bucket name must be 3-222 characters, start and end with a letter or number, and contain only lowercase letters, numbers, hyphens, underscores, and dots."
  }
}

variable "location" {
  description = "The GCS location (region, dual-region, or multi-region) for the bucket."
  type        = string
  default     = "US"
}

variable "storage_class" {
  description = "The storage class of the bucket. Supported values: STANDARD, NEARLINE, COLDLINE, ARCHIVE."
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "Storage class must be one of: STANDARD, NEARLINE, COLDLINE, ARCHIVE."
  }
}

variable "force_destroy" {
  description = "When true, deleting the bucket will delete all contained objects."
  type        = bool
  default     = false
}

variable "uniform_bucket_level_access" {
  description = "Enable uniform bucket-level access (disables ACLs). Recommended for production."
  type        = bool
  default     = true
}

variable "public_access_prevention" {
  description = "Public access prevention. Set to 'enforced' to prevent public access."
  type        = string
  default     = "enforced"

  validation {
    condition     = contains(["inherited", "enforced"], var.public_access_prevention)
    error_message = "Public access prevention must be 'inherited' or 'enforced'."
  }
}

variable "versioning_enabled" {
  description = "Enable object versioning for the bucket."
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels to apply to the bucket."
  type        = map(string)
  default     = {}
}

variable "requester_pays" {
  description = "Enable requester pays for the bucket."
  type        = bool
  default     = false
}

variable "default_event_based_hold" {
  description = "Enable default event-based hold on new objects."
  type        = bool
  default     = false
}

variable "retention_policy" {
  description = <<-EOT
    Retention policy configuration:
    - retention_period: Minimum retention period in seconds for objects.
    - is_locked: If true, the retention policy cannot be removed or shortened. IRREVERSIBLE.
  EOT
  type = object({
    retention_period = number
    is_locked        = optional(bool, false)
  })
  default = null

  validation {
    condition     = var.retention_policy == null || var.retention_policy.retention_period > 0
    error_message = "Retention period must be greater than 0."
  }
}

variable "lifecycle_rules" {
  description = <<-EOT
    List of lifecycle rules. Each rule contains:
    - action: Object with type (Delete, SetStorageClass, AbortIncompleteMultipartUpload) and optional storage_class.
    - condition: Object with optional age, created_before, with_state, matches_storage_class, matches_prefix, matches_suffix, num_newer_versions, days_since_noncurrent_time, noncurrent_time_before, days_since_custom_time, custom_time_before, send_days_since_noncurrent_time_if_zero, send_days_since_custom_time_if_zero, send_num_newer_versions_if_zero.
  EOT
  type = list(object({
    action = object({
      type          = string
      storage_class = optional(string)
    })
    condition = object({
      age                                     = optional(number)
      created_before                          = optional(string)
      with_state                              = optional(string)
      matches_storage_class                   = optional(list(string))
      matches_prefix                          = optional(list(string))
      matches_suffix                          = optional(list(string))
      num_newer_versions                      = optional(number)
      days_since_noncurrent_time              = optional(number)
      noncurrent_time_before                  = optional(string)
      days_since_custom_time                  = optional(number)
      custom_time_before                      = optional(string)
      send_days_since_noncurrent_time_if_zero = optional(bool)
      send_days_since_custom_time_if_zero     = optional(bool)
      send_num_newer_versions_if_zero         = optional(bool)
    })
  }))
  default = []
}

variable "cors" {
  description = <<-EOT
    List of CORS configurations. Each entry contains:
    - origin: List of origins (e.g., ["https://example.com"])
    - method: List of HTTP methods (e.g., ["GET", "POST"])
    - response_header: List of response headers
    - max_age_seconds: Max age in seconds for preflight cache
  EOT
  type = list(object({
    origin          = optional(list(string), [])
    method          = optional(list(string), [])
    response_header = optional(list(string), [])
    max_age_seconds = optional(number)
  }))
  default = []
}

variable "encryption" {
  description = <<-EOT
    Encryption configuration:
    - default_kms_key_name: Cloud KMS key name for default object encryption (CMEK).
  EOT
  type = object({
    default_kms_key_name = string
  })
  default = null
}

variable "logging" {
  description = <<-EOT
    Access logging configuration:
    - log_bucket: The bucket to receive access logs.
    - log_object_prefix: Prefix for log object names.
  EOT
  type = object({
    log_bucket        = string
    log_object_prefix = optional(string, "")
  })
  default = null
}

variable "website" {
  description = <<-EOT
    Static website hosting configuration:
    - main_page_suffix: The main page suffix (e.g., "index.html").
    - not_found_page: The custom 404 page (e.g., "404.html").
  EOT
  type = object({
    main_page_suffix = optional(string)
    not_found_page   = optional(string)
  })
  default = null
}

variable "custom_placement_config" {
  description = <<-EOT
    Custom dual-region placement configuration:
    - data_locations: List of two regions for dual-region placement.
  EOT
  type = object({
    data_locations = list(string)
  })
  default = null
}

variable "autoclass" {
  description = <<-EOT
    Autoclass configuration:
    - enabled: Enable Autoclass for automatic storage class transitions.
    - terminal_storage_class: Terminal storage class (NEARLINE or ARCHIVE).
  EOT
  type = object({
    enabled                = bool
    terminal_storage_class = optional(string)
  })
  default = null
}

variable "soft_delete_policy" {
  description = <<-EOT
    Soft delete policy configuration:
    - retention_duration_seconds: Duration to retain soft-deleted objects (0 to disable, 604800 to 7776000).
  EOT
  type = object({
    retention_duration_seconds = number
  })
  default = null
}

variable "iam_bindings" {
  description = <<-EOT
    IAM bindings for the bucket. Map of role => list of members.
    Example: { "roles/storage.objectViewer" = ["user:dev@example.com"] }
  EOT
  type    = map(list(string))
  default = {}
}

variable "notifications" {
  description = <<-EOT
    List of Pub/Sub notification configurations. Each contains:
    - topic: The Pub/Sub topic name (full resource name).
    - payload_format: JSON_API_V1 or NONE.
    - event_types: List of event types (OBJECT_FINALIZE, OBJECT_METADATA_UPDATE, OBJECT_DELETE, OBJECT_ARCHIVE).
    - object_name_prefix: Filter by object name prefix.
    - custom_attributes: Map of custom attributes to include in the notification.
  EOT
  type = list(object({
    topic              = string
    payload_format     = optional(string, "JSON_API_V1")
    event_types        = optional(list(string))
    object_name_prefix = optional(string)
    custom_attributes  = optional(map(string), {})
  }))
  default = []
}
