# =====================================================================
# 💾 Terraform Backend Configuration — Test Environment
# ---------------------------------------------------------------------
# Uses AWS S3 for remote state storage and DynamoDB for state locking.
# The actual configuration values are supplied from backend.conf.
# =====================================================================

terraform {
  backend "s3" {}
}
