# =====================================================================
# 💾 Terraform Backend Configuration
# ---------------------------------------------------------------------
# File: backend.tf
# Purpose:
#   Defines the type of backend (e.g., S3) used by Terraform to store
#   the remote state file and manage state locking.
#
# Notes:
#   - This file declares the backend *type* and structure.
#   - It must remain static: backend blocks cannot use variables
#     or dynamic expressions.
#   - Environment-specific values (e.g., bucket, key, region) may be
#     defined directly here OR provided separately via a backend.conf file.
#
# Usage:
#   Option 1: Static configuration (simpler)
#       terraform init
#
#   Option 2: Dynamic configuration via backend.conf
#       terraform init -backend-config=backend.conf
#
#   Each environment (dev/test/prod) should use a unique S3 key path
#   to ensure complete state isolation.
# =====================================================================

terraform {
  backend "s3" {
    # If you use a static backend configuration, uncomment the values below:
    # bucket         = "experts-lab-terraform-states"
    # key            = "eks/dev/terraform.tfstate"
    # region         = "eu-central-2"
    # encrypt        = true
    # dynamodb_table = "terraform-locks"
  }
}
