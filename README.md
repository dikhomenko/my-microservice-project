# My Microservice Project - DevOps Learning Journey

This repository contains a complete project implementing infrastructure as code, containerization, orchestration, and CI/CD pipelines.

## Project Structure

### Lesson 5 - Foundation Infrastructure

- **VPC**: Network infrastructure with public/private subnets
- **ECR**: Container registry for Docker images
- **S3 Backend**: Terraform state management

### Lesson 7 - EKS Kubernetes Cluster with Django Application

- **EKS Kubernetes Cluster**: Managed Kubernetes cluster in existing VPC
- **Django Application Deployment**: Helm chart with autoscaling and load balancing
- **ECR Integration**: Uses lesson-5 ECR repository for container images

### Lesson 8-9 - Complete CI/CD Pipeline

- **Jenkins**: Automated Docker builds using Kaniko
- **Argo CD**: GitOps-based continuous deployment
- **IRSA**: Secure AWS authentication for Kubernetes service accounts
- **Automated Pipeline**: Full automation from code commit to production deployment

### Lesson 10 - Universal RDS/Aurora Database Module

- **Universal Database Module**: Single module for both RDS and Aurora
- **Conditional Logic**: Switch between RDS and Aurora with one flag
- **Complete Infrastructure**: VPC, EKS, ECR, Jenkins, Argo CD, and Database
- **Production Ready**: High availability, backups, monitoring, security
- **Flexible Configuration**: Multiple engines (PostgreSQL, MySQL, MariaDB), custom parameters

## Quick Start

### Prerequisites

- **AWS CLI**: Configured with appropriate credentials
- **Terraform**: >= 1.0 installed
- **kubectl**: Kubernetes command line tool
- **Helm**: Kubernetes package manager
- **Git**: Version control

### Deployment Sequence

The lessons can be deployed independently or in sequence:

**1. Lesson 5 - Foundation Infrastructure**

- Deploy VPC, ECR, and S3 backend
- Required by: Lesson 7, Lesson 8-9

**2. Lesson 7 - EKS Cluster** (Optional - independent from Lesson 8-9)

- Deploy Kubernetes cluster and Django application
- Standalone lesson for learning EKS

**3. Lesson 8-9 - CI/CD Pipeline**

- Deploy Jenkins and Argo CD for automated deployments
- **Only requires Lesson 5** (VPC, ECR)
- Creates its own EKS cluster (lesson-8-9-eks)
- Self-contained EKS setup (no lesson-7 modifications needed)

**4. Lesson 10 - Universal Database Infrastructure** (Independent)

- Complete infrastructure with RDS or Aurora database
- **Self-contained**: Creates own VPC, EKS, ECR, Jenkins, Argo CD
- Switch between RDS and Aurora with single flag
- Production-ready database with HA, backups, monitoring
- Can be deployed independently or after Lesson 5

---

## Lesson 10 - Universal RDS/Aurora Database

### Overview

Production-ready infrastructure demonstrating a universal database module that can deploy either regular RDS instances or Aurora clusters using conditional Terraform logic.

### Key Features

- **Single module** for both RDS and Aurora
- **One-flag switch** between database types (`use_aurora`)
- **Production security**: VPC isolation, encryption, security groups
- **High availability**: Multi-AZ RDS, Aurora clusters with readers
- **Full flexibility**: Multiple engines, custom parameters, autoscaling
- **Complete stack**: Includes VPC, EKS, Jenkins, Argo CD

### Quick Deploy

```bash
cd lesson-10

# Initialize
terraform init

# Deploy with PostgreSQL RDS
terraform apply

# Or switch to Aurora in main.tf
# use_aurora = true
# Then: terraform apply
```

### Database Types Supported

**Regular RDS:**

- PostgreSQL (versions 12-16)
- MySQL (versions 5.7, 8.0)
- MariaDB (versions 10.x)

**Aurora:**

- Aurora PostgreSQL (versions 13-15)
- Aurora MySQL (versions 5.7, 8.0)
- Aurora Serverless v2

### Configuration Examples

#### PostgreSQL RDS with Multi-AZ

```terraform
module "rds" {
  source = "./modules/rds"

  use_aurora     = false
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.small"
  multi_az       = true

  allocated_storage = 100

  parameters = {
    max_connections = "200"
    shared_buffers  = "256MB"
  }
}
```

#### Aurora PostgreSQL Cluster

```terraform
module "rds" {
  source = "./modules/rds"

  use_aurora            = true
  engine                = "postgres"
  aurora_engine_version = "15.4"
  aurora_instance_count = 3  # 1 writer + 2 readers
  aurora_instance_class = "db.t3.medium"

  parameters = {
    max_connections = "300"
  }
}
```

#### Aurora Serverless v2

```terraform
module "rds" {
  source = "./modules/rds"

  use_aurora         = true
  aurora_instance_class = "db.serverless"

  aurora_serverless_v2_scaling = {
    min_capacity = 0.5
    max_capacity = 4.0
  }
}
```

### Access Database

```bash
# Get connection info
terraform output db_endpoint
terraform output db_connection_string

# Connect with psql
psql -h $(terraform output -raw db_endpoint | cut -d: -f1) -U dbadmin -d appdb

# Or MySQL
mysql -h $(terraform output -raw db_endpoint | cut -d: -f1) -u dbadmin -p appdb
```

### Module Features

**Automatic Resource Creation:**

- DB Subnet Group (for both RDS and Aurora)
- Security Group with configurable rules
- Parameter Group with custom settings

**High Availability:**

- Multi-AZ deployment for RDS
- Aurora clusters with multiple instances
- Automated failover

**Backup & Recovery:**

- Automated daily backups
- Configurable retention period
- Point-in-time recovery
- Final snapshot on deletion

**Monitoring:**

- CloudWatch Logs export
- Performance Insights
- Enhanced monitoring

**Security:**

- Storage encryption at rest
- VPC isolation in private subnets
- Security group access control
- IAM authentication ready

### Switching Database Types

To switch from RDS to Aurora (or vice versa):

1. **Create snapshot** of existing database:

   ```bash
   aws rds create-db-snapshot \
     --db-instance-identifier lesson-10-db \
     --db-snapshot-identifier before-aurora-migration
   ```

2. **Update configuration** in `main.tf`:

   ```terraform
   module "rds" {
     use_aurora = true  # Changed from false
     # ... rest of config
   }
   ```

3. **Apply changes**:
   ```bash
   terraform apply
   ```

**Warning**: This recreates the database. Use snapshots to preserve data.

### Scaling Options

**Vertical Scaling (Change instance size):**

```terraform
instance_class = "db.t3.large"  # Was db.t3.small
```

**Horizontal Scaling (Aurora readers):**

```terraform
aurora_instance_count = 5  # Add more read replicas
```

**Storage Autoscaling (RDS):**

```terraform
allocated_storage     = 100
max_allocated_storage = 500  # Auto-scale up to 500GB
```

**Serverless Autoscaling (Aurora):**

```terraform
aurora_serverless_v2_scaling = {
  min_capacity = 0.5  # Scale down to 0.5 ACUs
  max_capacity = 16.0 # Scale up to 16 ACUs
}
```

### Common Parameters

**PostgreSQL:**

```terraform
parameters = {
  max_connections             = "200"
  shared_buffers             = "256MB"
  work_mem                   = "8MB"
  maintenance_work_mem       = "128MB"
  effective_cache_size       = "1GB"
  random_page_cost           = "1.1"
  log_statement              = "ddl"
  log_min_duration_statement = "1000"
}
```

**MySQL:**

```terraform
parameters = {
  max_connections        = "200"
  innodb_buffer_pool_size = "256M"
  slow_query_log         = "1"
  long_query_time        = "2"
  character_set_server   = "utf8mb4"
  collation_server       = "utf8mb4_unicode_ci"
}
```

### Cleanup

```bash
# Destroy all resources
terraform destroy
```

For production, enable deletion protection:

```terraform
deletion_protection = true
skip_final_snapshot = false
```
