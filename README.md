# Lesson 7 - EKS Kubernetes Cluster with Django Application

This project extends lesson-5 infrastructure with:

1. **EKS Kubernetes Cluster**: Managed Kubernetes cluster in existing VPC
2. **Django Application Deployment**: Helm chart with autoscaling and load balancing
3. **ECR Integration**: Uses lesson-5 ECR repository for container images

## Prerequisites

- **Lesson-5 Infrastructure**: VPC, ECR repository, and S3 backend must be deployed
- **AWS CLI**: Configured with appropriate credentials
- **kubectl**: Kubernetes command line tool
- **Helm**: Kubernetes package manager

## Usage

### Phase 1: Deploy EKS Infrastructure

1. **Navigate to lesson-7**:

   ```bash
   cd lesson-7
   ```

2. **Initialize Terraform**:

   ```bash
   terraform init
   ```

3. **Deploy EKS cluster**:
   ```bash
   terraform plan
   terraform apply
   ```

### Phase 2: Configure kubectl

1. **Update kubeconfig**:

   ```bash
   aws eks update-kubeconfig --region us-west-2 --name lesson-7-eks
   ```

2. **Verify cluster access**:
   ```bash
   kubectl get nodes
   ```

### Phase 3: Deploy Django Application

1. **Update ECR repository URL** in `charts/django-app/values.yaml`:

   - Replace `ACCOUNT_ID` : `2513-4250-3781` with your AWS account ID
   - Ensure image `IMAGE_NAME` : `dina_django_project_web:latest` exists in ECR

2. **Install Helm chart**:

   ```bash
   helm install django-app ./charts/django-app
   ```

3. **Get LoadBalancer URL**:
   ```bash
   kubectl get service django-app
   ```

## Configuration

### EKS Cluster

- **Instance Type**: t3.small (free tier eligible)
- **Node Group**: 2-4 nodes with autoscaling
- **Network**: Uses lesson-5 VPC private subnets

### Django Application

- **Replicas**: 2 (minimum) to 6 (maximum)
- **Autoscaling**: Based on 70% CPU utilization
- **Service**: LoadBalancer for external access
- **Environment**: ConfigMap with database and application settings

## Cleanup

```bash
# Remove Django application
helm uninstall django-app

# Destroy EKS infrastructure
terraform destroy
```

**Note**: Lesson-5 infrastructure (VPC, ECR) remains unchanged.
