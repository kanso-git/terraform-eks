# =====================================================================
# 🏗️ VPC MODULE — Zurich Region (eu-central-2)
# ---------------------------------------------------------------------
# Creates a full network layer for an EKS cluster:
# - Dedicated or existing VPC
# - 3 Public and 3 Private Subnets
# - Internet Gateway (IGW)
# - One NAT Gateway (shared across AZs)
# - Separate Route Tables for Public and Private traffic
#
# Includes:
# - EKS-compatible tags
# - Environment-based naming
# - Static creation date (via var.creation_date)
# =====================================================================

# ------------------------------------------------------------
# 🧱 Create a new VPC (if not provided)
# ------------------------------------------------------------
resource "aws_vpc" "this" {
  count = var.vpc_id == null ? 1 : 0                # Only create if no existing VPC provided

  cidr_block           = var.vpc_cidr               # Example: 10.0.0.0/16
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name         = "${var.environment}-vpc"
    Environment  = var.environment
    Owner        = var.owner
    CreationDate = var.creation_date
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}


# ------------------------------------------------------------
# 🌐 Internet Gateway
# ------------------------------------------------------------
resource "aws_internet_gateway" "this" {
  vpc_id = local.vpc_id

  tags = {
    Name         = "${var.environment}-igw"
    Environment  = var.environment
    Owner        = var.owner
    CreationDate = var.creation_date
  }
}

# ------------------------------------------------------------
# ☁️ Elastic IP for NAT Gateway
# ------------------------------------------------------------
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name         = "${var.environment}-nat-eip"
    Environment  = var.environment
    Owner        = var.owner
    CreationDate = var.creation_date
  }
}

# ------------------------------------------------------------
# 🌉 Public Subnets
# ------------------------------------------------------------
resource "aws_subnet" "public" {
  for_each = zipmap(var.azs, var.public_subnet_cidrs)

  vpc_id                  = local.vpc_id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name         = "${var.environment}-public-${each.key}"
    Environment  = var.environment
    Type         = "public"
    Owner        = var.owner
    CreationDate = var.creation_date
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb" = "1"
  }
}

# ------------------------------------------------------------
# 🔒 Private Subnets
# ------------------------------------------------------------
resource "aws_subnet" "private" {
  for_each = zipmap(var.azs, var.private_subnet_cidrs)

  vpc_id            = local.vpc_id
  cidr_block        = each.value
  availability_zone = each.key

  tags = {
    Name         = "${var.environment}-private-${each.key}"
    Environment  = var.environment
    Type         = "private"
    Owner        = var.owner
    CreationDate = var.creation_date
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# ------------------------------------------------------------
# 🌐 NAT Gateway
# ------------------------------------------------------------
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = values(aws_subnet.public)[0].id   # Place NAT in the first public subnet

  tags = {
    Name         = "${var.environment}-nat-gw"
    Environment  = var.environment
    Owner        = var.owner
    CreationDate = var.creation_date
  }

  depends_on = [aws_internet_gateway.this]
}

# ------------------------------------------------------------
# 🛣️ Public Route Table
# ------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name         = "${var.environment}-public-rt"
    Environment  = var.environment
    Owner        = var.owner
    CreationDate = var.creation_date
  }
}

# ------------------------------------------------------------
# 🛣️ Private Route Table
# ------------------------------------------------------------
resource "aws_route_table" "private" {
  vpc_id = local.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name         = "${var.environment}-private-rt"
    Environment  = var.environment
    Owner        = var.owner
    CreationDate = var.creation_date
  }
}

# ------------------------------------------------------------
# 🔗 Subnet Associations
# ------------------------------------------------------------
resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_assoc" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
