# Lesson 5 - Terraform Infrastructure Project

This project is a modular Terraform setup for AWS infrastructure with **proper state management separation**:

1. **Bootstrap Infrastructure**: Separate project for S3 backend and DynamoDB locking
2. **Network Infrastructure**: VPC with public and private subnets
3. **Container Registry**: ECR for Docker images

## Usage

### IMPORTANT: Two-Phase Deployment

This project uses a **bootstrap approach** to avoid circular dependencies in state management.

### Phase 1: Bootstrap (Run Once)

1. **Deploy the bootstrap infrastructure**:

   cd lesson_5/bootstrap
   terraform init
   terraform plan
   terraform apply

2. **Get the backend configuration**:

   terraform output backend_config_text

### Phase 2: Main Infrastructure

1. **Navigate to main project**:

   cd ../ # back to lesson_5 root

2. **Initialize with remote backend**:

   terraform init

3. **Deploy main infrastructure**:

   terraform plan
   terraform apply

### Regular Usage

1. **Plan changes**:

   terraform plan

2. **Apply changes**:

   terraform apply

3. **Destroy infrastructure** (when needed):

   terraform destroy

## Configuration

### Main Variables

You can customize the configuration by modifying the variables in `main.tf`:

- `aws_region`: AWS region (default: "us-west-2")
- `project_name`: Project name (default: "lesson-5")

### Module-Specific Configuration

#### Bootstrap Configuration

- `bucket_name`: "dina-bucket-1" (in bootstrap/variables.tf)
- `table_name`: "terraform-locks" (in bootstrap/variables.tf)

#### VPC

- `vpc_cidr_block`: "10.0.0.0/16"
- `public_subnets`: 3 subnets (10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24)
- `private_subnets`: 3 subnets (10.0.4.0/24, 10.0.5.0/24, 10.0.6.0/24)
- `availability_zones`: us-west-2a, us-west-2b, us-west-2c

#### ECR

- `ecr_name`: "lesson-5-ecr"
- `scan_on_push`: true (vulnerability scanning enabled)

## Outputs

After successful deployment, you willl get the following outputs:

### VPC

- VPC ID and CIDR block
- Public and private subnet IDs
- Internet Gateway and NAT Gateway IDs

### ECR

- Repository URL and ARN
