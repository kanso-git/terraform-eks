#######################################################################
# 🔐 IAM MODULE — Locals
# ---------------------------------------------------------------------
# Centralizes computed values such as:
#   - Dynamic creation date fallback
#   - Base and merged tagging scheme
#######################################################################

locals {
  # ----------------------------------------------------------
  # 🕓 Creation Date
  # ----------------------------------------------------------
  # If no creation date was provided by the caller, compute
  # today’s date in YYYY-MM-DD format.
  # ----------------------------------------------------------
  creation_date = var.creation_date != "" ? var.creation_date : formatdate("YYYY-MM-DD", timestamp())

  # ----------------------------------------------------------
  # 🏷️ Base Tags
  # ----------------------------------------------------------
  base_tags = {
    Environment  = var.environment
    Owner        = var.owner
    CreationDate = local.creation_date
  }

  # ----------------------------------------------------------
  # 🧩 Common Tags (Base + Extra)
  # ----------------------------------------------------------
  common_tags = merge(local.base_tags, var.extra_tags)
}
