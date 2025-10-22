# =====================================================================
# 🏗️ VPC MODULE — Region-Agnostic (works in eu-central-2 and others)
# ---------------------------------------------------------------------
# Creates the network layer for an EKS cluster:
#  - Optionally creates a new VPC (`var.create_vpc`), or reuses an existing VPC.
#  - Creates public and private subnets across the provided AZs.
#  - Attaches an Internet Gateway (IGW) and a single NAT Gateway (shared).
#    For production HA, consider one NAT per AZ.
#  - Separate route tables for public and private subnets.
#
# Tagging:
#  - Uses common tags from locals (env/owner/date) + extra tags.
#  - Adds EKS discovery tag: "kubernetes.io/cluster/${var.cluster_name}" = "shared"
#    on VPC and all subnets, so EKS/ALB discover them.
# =====================================================================

############################################
# VPC (conditionally created)
############################################
resource "aws_vpc" "this" {
  count = var.create_vpc ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name                                        = "${var.environment}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

############################################
# Internet Gateway
############################################
resource "aws_internet_gateway" "this" {
  vpc_id = local.vpc_id

  tags = merge(local.common_tags, {
    Name = "${var.environment}-igw"
  })
}

############################################
# Elastic IP for NAT Gateway
############################################
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "${var.environment}-nat-eip"
  })
}

############################################
# Public Subnets
############################################
resource "aws_subnet" "public" {
  for_each = local.subnets.public

  vpc_id                  = local.vpc_id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name                                        = "${var.environment}-public-${each.key}",
    Type                                        = "public",
    "kubernetes.io/cluster/${var.cluster_name}" = "owned",
    "kubernetes.io/role/elb"                    = "1"
  })
}

############################################
# Private Subnets
############################################
resource "aws_subnet" "private" {
  for_each = local.subnets.private

  vpc_id            = local.vpc_id
  cidr_block        = each.value
  availability_zone = each.key

  tags = merge(local.common_tags, {
    Name                                        = "${var.environment}-private-${each.key}",
    Type                                        = "private",
    "kubernetes.io/cluster/${var.cluster_name}" = "owned",
    "kubernetes.io/role/internal-elb"           = "1"
  })
}

############################################
# NAT Gateway (shared across AZs)
############################################
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  # Deterministically place the NAT in the lexicographically first public AZ
  subnet_id = aws_subnet.public[local.first_public_az].id

  tags = merge(local.common_tags, {
    Name = "${var.environment}-nat-gw"
  })

  depends_on = [aws_internet_gateway.this]
}

############################################
# Public Route Table
############################################
resource "aws_route_table" "public" {
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-public-rt"
  })
}

############################################
# Private Route Table
############################################
resource "aws_route_table" "private" {
  vpc_id = local.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-private-rt"
  })
}

############################################
# Route Table Associations
############################################
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
