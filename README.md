# Final Project - Production-Ready AWS Infrastructure

A complete AWS infrastructure for deploying Django microservices with Kubernetes, CI/CD pipelines, GitOps, and comprehensive monitoring.

## 📦 Components

| Component      | Description                              | Version                      |
| -------------- | ---------------------------------------- | ---------------------------- |
| **VPC**        | Multi-AZ VPC with public/private subnets | -                            |
| **EKS**        | Managed Kubernetes cluster               | 1.28                         |
| **RDS/Aurora** | PostgreSQL database (RDS or Aurora)      | 15.4                         |
| **ECR**        | Container image registry                 | -                            |
| **Jenkins**    | CI/CD pipeline automation                | Helm 5.1.27                  |
| **ArgoCD**     | GitOps continuous deployment             | Helm 5.51.6                  |
| **Prometheus** | Metrics collection and alerting          | kube-prometheus-stack 55.5.0 |
| **Grafana**    | Metrics visualization and dashboards     | Included                     |

## 🚀 Prerequisites

Before deploying, ensure you have the following installed:

```bash
# AWS CLI v2
aws --version

# Terraform >= 1.0
terraform --version

# kubectl
kubectl version --client

# Helm >= 3.0
helm version
```

### AWS Configuration

```bash
# Configure AWS CLI with your credentials
aws configure

# Verify access
aws sts get-caller-identity
```

## 📁 Project Structure

```
final-project/
├── main.tf                 # Root module - all infrastructure
├── variables.tf            # Variable definitions
├── outputs.tf              # Output values
├── backend.tf              # S3 backend configuration
├── terraform.tfvars.example # Example variables file
├── README.md               # This file
│
├── modules/
│   ├── vpc/                # VPC, subnets, NAT, routing
│   ├── eks/                # EKS cluster, node groups, addons
│   ├── rds/                # RDS/Aurora PostgreSQL
│   ├── ecr/                # Container registry
│   ├── s3-backend/         # Terraform state storage
│   ├── jenkins/            # Jenkins CI/CD
│   ├── argo_cd/            # ArgoCD GitOps
│   └── monitoring/         # Prometheus + Grafana
│
├── charts/
│   └── django-app/         # Helm chart for Django application
│
└── django/                 # Django application source
    ├── Dockerfile
    ├── Jenkinsfile
    ├── docker-compose.yaml
    └── ...
```

## 🔧 Deployment Instructions

### Step 1: Clone and Configure

```bash
# Clone the repository
git clone https://github.com/dikhomenko/my-microservice-project.git
cd my-microservice-project/final-project

# Copy and edit the variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
# - Set your AWS region
# - Set your project name
# - Configure database credentials
# - Set your Git repository URL
```

### Step 2: Initialize Terraform Backend (First Time Only)

```bash
# First, create the S3 backend infrastructure
cd modules/s3-backend
terraform init
terraform apply -auto-approve

# Note the outputs for backend configuration
cd ../..
```

### Step 3: Configure Backend

Update `backend.tf` with your S3 bucket name:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-project-terraform-state"
    key            = "final-project/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

### Step 4: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the execution plan
terraform plan

# Apply the infrastructure
terraform apply

# This will take approximately 20-30 minutes
```

### Step 5: Configure kubectl

```bash
# Update kubeconfig with EKS cluster credentials
aws eks update-kubeconfig \
  --region us-west-2 \
  --name my-eks-cluster

# Verify connection
kubectl get nodes
```

## ✅ Verification Commands

After deployment, verify all components are running:

### Check Namespaces

```bash
# Verify all required namespaces exist
kubectl get namespaces
```

### Jenkins Verification

```bash
# Check Jenkins pods
kubectl get pods -n jenkins

# Get Jenkins admin password
kubectl exec -n jenkins -it svc/jenkins -c jenkins -- \
  cat /run/secrets/additional/chart-admin-password

# Port-forward to access Jenkins UI
kubectl port-forward svc/jenkins -n jenkins 8080:8080
# Access at: http://localhost:8080
```

### ArgoCD Verification

```bash
# Check ArgoCD pods
kubectl get pods -n argocd

# Get ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo

# Port-forward to access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8443:443
# Access at: https://localhost:8443
```

### Monitoring Verification

```bash
# Check monitoring pods
kubectl get pods -n monitoring

# Port-forward to access Grafana
kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80
# Access at: http://localhost:3000
# Default credentials: admin / prom-operator

# Port-forward to access Prometheus
kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090
# Access at: http://localhost:9090
```

### Application Verification

```bash
# Check application pods
kubectl get pods -n default

# Check application services
kubectl get svc -n default
```

## CI/CD Pipeline Flow

1. **Push to GitHub**: Developer pushes code to the repository
2. **Jenkins Trigger**: Webhook triggers Jenkins pipeline
3. **Build & Test**: Jenkins runs tests and builds Docker image with Kaniko
4. **Push to ECR**: Image is pushed to Amazon ECR
5. **ArgoCD Sync**: ArgoCD detects changes and deploys to EKS
6. **Monitoring**: Prometheus collects metrics, Grafana displays dashboards

## Grafana Dashboards

The deployment includes pre-configured dashboards:

- **Django Application Dashboard**: Application-specific metrics
- **Kubernetes Cluster Overview**: Cluster health and resources
- **Node Exporter**: Node-level metrics
- **PostgreSQL**: Database metrics (when configured)

## Security Features

- **IRSA (IAM Roles for Service Accounts)**: Secure AWS authentication
- **Private Subnets**: EKS nodes in private subnets
- **Security Groups**: Strict network policies
- **Secrets Management**: Kubernetes secrets for sensitive data
- **TLS/SSL**: Encrypted communication between services
- **Non-root Containers**: Security best practices

## Cleanup

To destroy all infrastructure:

```bash
# Destroy all resources (WARNING: This deletes everything!)
terraform destroy

# Confirm with 'yes' when prompted
```

**Note**: The S3 bucket for Terraform state has deletion protection enabled. To delete it:

1. Empty the bucket manually
2. Disable deletion protection
3. Delete the bucket
