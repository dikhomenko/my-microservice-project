# Shared resources for both RDS and Aurora
# These resources are created regardless of database type

# DB Subnet Group - required for both RDS and Aurora
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.subnet_ids
  
  description = "Database subnet group for ${var.project_name}"
  
  tags = {
    Name        = "${var.project_name}-db-subnet-group"
    Environment = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Security Group for database access
resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Security group for ${var.project_name} database"
  vpc_id      = var.vpc_id
  
  # Ingress rule - allow database connections
  ingress {
    description = "Database access from allowed CIDR blocks"
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }
  
  # Additional security group rules if specified
  dynamic "ingress" {
    for_each = var.allowed_security_groups
    content {
      description     = "Database access from security group ${ingress.value}"
      from_port       = var.db_port
      to_port         = var.db_port
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }
  
  # Egress rule - allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "${var.project_name}-db-sg"
    Environment = var.project_name
    ManagedBy   = "Terraform"
  }
}
