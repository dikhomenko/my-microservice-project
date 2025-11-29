# VPC and Subnets Configuration
# Production-ready network infrastructure for AWS

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Create public subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                            = "${var.project_name}-public-${count.index + 1}"
    Type                                            = "Public"
    Environment                                     = var.environment
    "kubernetes.io/role/elb"                        = "1"
    "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
  }
}

# Create private subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                                            = "${var.project_name}-private-${count.index + 1}"
    Type                                            = "Private"
    Environment                                     = var.environment
    "kubernetes.io/role/internal-elb"               = "1"
    "kubernetes.io/cluster/${var.project_name}-eks" = "shared"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Create Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = length(var.public_subnets)
  domain = "vpc"

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name        = "${var.project_name}-eip-${count.index + 1}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Create NAT Gateways (one per AZ for high availability)
resource "aws_nat_gateway" "main" {
  count         = length(var.public_subnets)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name        = "${var.project_name}-nat-${count.index + 1}"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
