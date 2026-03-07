locals {
  default_labels = {
    managed-by = "terraform"
  }

  merged_labels = merge(local.default_labels, var.labels)

  iam_bindings_flat = flatten([
    for role, members in var.iam_bindings : [
      for member in members : {
        role   = role
        member = member
      }
    ]
  ])

  # Determine if bucket is multi-region, dual-region, or regional
  is_multi_region = contains(["US", "EU", "ASIA"], upper(var.location))
  is_dual_region  = var.custom_placement_config != null
}
