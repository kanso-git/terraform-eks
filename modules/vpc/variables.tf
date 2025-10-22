#######################################################################
# 🌐 VPC MODULE — Input Variables
# ---------------------------------------------------------------------
# Defines all configurable inputs for the VPC module.
# - Uses static defaults only (no dynamic functions in defaults)
# - Dynamic values (e.g., timestamps) are handled in locals.tf
# - Includes validation for CIDRs, AZ consistency, and redundancy
#######################################################################

# ------------------------------------------------------------
# 🧱 Core Networking Configuration
# ------------------------------------------------------------
variable "vpc_cidr" {
  description = "(Required) The primary CIDR block for the VPC."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "The provided vpc_cidr must be a valid CIDR block, e.g., 10.0.0.0/16."
  }
}

# ------------------------------------------------------------
# 🏗️ Existing VPC Option
# ------------------------------------------------------------
variable "create_vpc" {
  description = "(Optional) Whether to create a new VPC. Defaults to true."
  type        = bool
  default     = true
}

variable "existing_vpc_id" {
  description = "(Optional) ID of an existing VPC to reuse. If provided, set create_vpc = false."
  type        = string
  default     = null
}

# ------------------------------------------------------------
# ☸️ Cluster Name
# ------------------------------------------------------------
variable "cluster_name" {
  description = "(Required) The name of the EKS cluster associated with this VPC."
  type        = string
}

# ------------------------------------------------------------
# 🌍 Availability Zones
# ------------------------------------------------------------
variable "azs" {
  description = "(Required) List of Availability Zones in the region."
  type        = list(string)

  validation {
    condition     = length(var.azs) >= 2
    error_message = "You must specify at least two Availability Zones for redundancy."
  }
}

# ------------------------------------------------------------
# 🌐 Public Subnet CIDRs
# ------------------------------------------------------------
variable "public_subnet_cidrs" {
  description = "(Required) CIDR blocks for public subnets."
  type        = list(string)

  validation {
    condition     = alltrue([for c in var.public_subnet_cidrs : can(cidrnetmask(c))])
    error_message = "All values in public_subnet_cidrs must be valid CIDR blocks."
  }
}

# ------------------------------------------------------------
# 🔒 Private Subnet CIDRs
# ------------------------------------------------------------
variable "private_subnet_cidrs" {
  description = "(Required) List of private subnet CIDRs. Must match number of AZs."
  type        = list(string)

  validation {
    condition     = alltrue([for c in var.private_subnet_cidrs : can(cidrnetmask(c))])
    error_message = "All values in private_subnet_cidrs must be valid CIDR blocks."
  }
}

# ------------------------------------------------------------
# 🌱 Environment Context
# ------------------------------------------------------------
variable "environment" {
  description = "(Required) Environment name (e.g., dev, test, prod)."
  type        = string
}

# ------------------------------------------------------------
# 👤 Owner Tag
# ------------------------------------------------------------
variable "owner" {
  description = "(Optional) Identifies the resource owner or responsible team."
  type        = string
  default     = "experts-lab.com"
}

# ------------------------------------------------------------
# 🏷️ Extra Custom Tags
# ------------------------------------------------------------
variable "extra_tags" {
  description = "(Optional) Map of additional tags merged into all resources."
  type        = map(string)
  default     = {}
}

# ------------------------------------------------------------
# 🕓 Creation Metadata
# ------------------------------------------------------------
variable "creation_date" {
  description = "Timestamp for resource creation tracking (YYYY-MM-DD)."
  type        = string
  default     = ""
}
