########################################
# VPC AND NETWORKING INFRASTRUCTURE
########################################
# Defines the core VPC layout with local variables for subnet organization
locals {
  # Map public subnets by index for consistent Terraform references
  public_subnets = {
    for idx, cidr in var.public_subnet_cidrs : tostring(idx) => {
      cidr = cidr
      az   = var.azs[idx]
    }
  }

  private_app_subnets = {
    for idx, cidr in var.private_app_subnet_cidrs : tostring(idx) => {
      cidr = cidr
      az   = var.azs[idx]
    }
  }

  private_db_subnets = {
    for idx, cidr in var.private_db_subnet_cidrs : tostring(idx) => {
      cidr = cidr
      az   = var.azs[idx]
    }
  }
}

########################################
# VIRTUAL PRIVATE CLOUD (VPC)
########################################
# Primary VPC with DNS support enabled for ECS service discovery and
# ALB hostname resolution.
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

########################################
# INTERNET GATEWAY
########################################
# Enables internet connectivity for public subnets and NAT gateway.
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })
}

########################################
# PUBLIC SUBNETS
########################################
# Subnets for internet-facing resources like the ALB.
# Map public IP assignment enabled for potential bastion hosts.
resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = format("%s-public-%s", var.name_prefix, each.key)
    Tier = "public"
  })
}

########################################
# PRIVATE APPLICATION SUBNETS
########################################
# Subnets for application tier EC2 instances.
# No public IP assignment for security.
resource "aws_subnet" "private_app" {
  for_each = local.private_app_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name = format("%s-private-app-%s", var.name_prefix, each.key)
    Tier = "app"
  })
}

########################################
# PRIVATE DATABASE SUBNETS
########################################
# Reserved subnets for future database tier workloads.
# No public IP assignment, isolated routing.
resource "aws_subnet" "private_db" {
  for_each = local.private_db_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.tags, {
    Name = format("%s-private-db-%s", var.name_prefix, each.key)
    Tier = "db"
  })
}

########################################
# ELASTIC IP FOR NAT GATEWAY
########################################
# Static IP allocated for NAT gateway.
# Enables consistent outbound connectivity from private subnets.
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-eip"
  })

  depends_on = [aws_internet_gateway.this]
}

########################################
# NAT GATEWAY
########################################
# Provides secure outbound internet access for private subnets.
# Deployed in first public subnet for HA across AZs.
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public["0"].id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat"
  })

  depends_on = [aws_internet_gateway.this]
}

########################################
# PUBLIC ROUTE TABLE AND ROUTES
########################################
# Routes public subnets traffic directly to Internet Gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-rt"
  })
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

########################################
# PRIVATE APPLICATION ROUTE TABLES
########################################
# Per-AZ route tables for private app subnets.
# Routes internet-bound traffic through NAT gateway.
resource "aws_route_table" "private_app" {
  for_each = aws_subnet.private_app

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = format("%s-private-app-rt-%s", var.name_prefix, each.key)
  })
}

resource "aws_route" "private_app_default" {
  for_each = aws_route_table.private_app

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

resource "aws_route_table_association" "private_app" {
  for_each = aws_subnet.private_app

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_app[each.key].id
}

########################################
# PRIVATE DATABASE ROUTE TABLES
########################################
# Per-AZ route tables for private DB subnets.
# No internet route; isolated from public internet.
resource "aws_route_table" "private_db" {
  for_each = aws_subnet.private_db

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = format("%s-private-db-rt-%s", var.name_prefix, each.key)
  })
}

resource "aws_route_table_association" "private_db" {
  for_each = aws_subnet.private_db

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_db[each.key].id
}
