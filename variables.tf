variable "project_id" {
  description = "The GCP project ID where the bucket will be created."
  type        = string

  validation {
    condition     = length(var.project_id) > 0
    error_message = "Project ID must not be empty."
  }
}

variable "name" {
  description = "The name of the bucket, must be globally unique."
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
  description = "The storage class of the bucket (STANDARD, NEARLINE, COLDLINE, ARCHIVE)."
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
  description = "Enable uniform bucket-level access (disables ACLs)."
  type        = bool
  default     = true
}

variable "public_access_prevention" {
  description = "Public access prevention, set to 'enforced' to prevent public access."
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
  description = "Retention policy with retention_period (seconds) and is_locked flag."
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
  description = "List of lifecycle rules with action and condition blocks."
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
  description = "List of CORS configurations with origin, method, response_header, and max_age_seconds."
  type = list(object({
    origin          = optional(list(string), [])
    method          = optional(list(string), [])
    response_header = optional(list(string), [])
    max_age_seconds = optional(number)
  }))
  default = []
}

variable "encryption" {
  description = "Encryption configuration with default_kms_key_name for CMEK."
  type = object({
    default_kms_key_name = string
  })
  default = null
}

variable "logging" {
  description = "Access logging configuration with log_bucket and log_object_prefix."
  type = object({
    log_bucket        = string
    log_object_prefix = optional(string, "")
  })
  default = null
}

variable "website" {
  description = "Static website hosting configuration with main_page_suffix and not_found_page."
  type = object({
    main_page_suffix = optional(string)
    not_found_page   = optional(string)
  })
  default = null
}

variable "custom_placement_config" {
  description = "Custom dual-region placement configuration with data_locations list."
  type = object({
    data_locations = list(string)
  })
  default = null
}

variable "autoclass" {
  description = "Autoclass configuration with enabled flag and terminal_storage_class."
  type = object({
    enabled                = bool
    terminal_storage_class = optional(string)
  })
  default = null
}

variable "soft_delete_policy" {
  description = "Soft delete policy with retention_duration_seconds."
  type = object({
    retention_duration_seconds = number
  })
  default = null
}

variable "iam_bindings" {
  description = "IAM bindings for the bucket as a map of role to list of members."
  type        = map(list(string))
  default     = {}
}

variable "notifications" {
  description = "List of Pub/Sub notification configurations with topic, payload_format, and event_types."
  type = list(object({
    topic              = string
    payload_format     = optional(string, "JSON_API_V1")
    event_types        = optional(list(string))
    object_name_prefix = optional(string)
    custom_attributes  = optional(map(string), {})
  }))
  default = []
}
