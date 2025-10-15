# =====================================================================
# 🌐 VPC MODULE — Input Variables
# ---------------------------------------------------------------------
# Defines all configurable inputs for the VPC module.
# Each variable includes:
#  - Clear purpose and examples
#  - Strong typing for safety
#  - Validation logic for early error detection
#  - Default values aligned with best practices
# =====================================================================

# ------------------------------------------------------------
# 🧱 Core Networking Configuration
# ------------------------------------------------------------
variable "vpc_cidr" {
  description = <<EOT
  (Required) The primary CIDR block for the VPC.
  Example: "10.0.0.0/16"
  EOT
  type = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "The provided vpc_cidr must be a valid CIDR block, e.g., 10.0.0.0/16."
  }
}

# ------------------------------------------------------------
# 🏗️ Existing VPC Option
# ------------------------------------------------------------
variable "vpc_id" {
  description = <<EOT
  (Optional) Use an existing VPC instead of creating a new one.
  If null, a new VPC will be created automatically.
  EOT
  type    = string
  default = null
}

# ------------------------------------------------------------
# ☸️ Cluster Name
# ------------------------------------------------------------
variable "cluster_name" {
  description = <<EOT
  (Required) The name of the EKS cluster associated with this VPC.
  Used for tagging and resource discovery by Kubernetes.
  Example: "eks-dev-cluster"
  EOT
  type = string
}

# ------------------------------------------------------------
# 🌍 Availability Zones
# ------------------------------------------------------------
variable "azs" {
  description = <<EOT
  (Required) List of Availability Zones in the Zurich region.
  Example: ["eu-central-2a", "eu-central-2b", "eu-central-2c"]
  EOT
  type = list(string)

  validation {
    condition     = length(var.azs) >= 2
    error_message = "You must specify at least two Availability Zones for redundancy."
  }
}

# ------------------------------------------------------------
# 🌐 Public Subnet CIDRs
# ------------------------------------------------------------
variable "public_subnet_cidrs" {
  description = <<EOT
  (Required) CIDR blocks for public subnets. Must match the number of Availability Zones.
  Example:
    ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
  EOT
  type = list(string)

  validation {
    condition     = alltrue([for c in var.public_subnet_cidrs : can(cidrnetmask(c))])
    error_message = "All values in public_subnet_cidrs must be valid CIDR blocks."
  }
}

# ------------------------------------------------------------
# 🔒 Private Subnet CIDRs
# ------------------------------------------------------------
variable "private_subnet_cidrs" {
  description = <<EOT
  (Required) CIDR blocks for private subnets. Must match the number of Availability Zones.
  Example:
    ["10.0.96.0/19", "10.0.128.0/19", "10.0.160.0/19"]
  EOT
  type = list(string)

  validation {
    condition     = alltrue([for c in var.private_subnet_cidrs : can(cidrnetmask(c))])
    error_message = "All values in private_subnet_cidrs must be valid CIDR blocks."
  }
}

# ------------------------------------------------------------
# 🌱 Environment Context
# ------------------------------------------------------------
variable "environment" {
  description = <<EOT
  (Required) Environment name (e.g., dev, test, prod).
  Used in resource naming and tagging conventions.
  EOT
  type = string
}

# ------------------------------------------------------------
# 👤 Owner Tag
# ------------------------------------------------------------
variable "owner" {
  description = <<EOT
  (Optional) Identifies the resource owner or responsible team.
  Used for the "Owner" tag across all resources.
  Default: experts-lab.com
  EOT
  type    = string
  default = "experts-lab.com"
}

# ------------------------------------------------------------
# 🏷️ Extra Custom Tags
# ------------------------------------------------------------
variable "extra_tags" {
  description = <<EOT
  (Optional) Map of additional tags merged into all resources.
  Example:
    extra_tags = {
      Project     = "EKS-Migration"
      CostCenter  = "CC-12345"
    }
  EOT
  type    = map(string)
  default = {}
}

# ------------------------------------------------------------
# 🕓 Creation Metadata
# ------------------------------------------------------------
variable "creation_date" {
  description = <<EOT
  (Optional) Creation date tag for audit and traceability.
  If not provided, defaults to the current timestamp.
  Example: "2025-10-10"
  EOT
  type    = string
  default = "2025-10-10"
}

# ------------------------------------------------------------
# 🔍 Validation: AZ and Subnet Count Consistency
# ------------------------------------------------------------
locals {
  az_count = length(var.azs)
}

# Validate subnet counts vs AZs
resource "null_resource" "validate_subnet_count" {
  count = (
    length(var.public_subnet_cidrs) == local.az_count &&
    length(var.private_subnet_cidrs) == local.az_count
  ) ? 0 : 1

  provisioner "local-exec" {
    command = "echo '❌ ERROR: Number of subnet CIDRs must match number of AZs!' && exit 1"
  }
}
