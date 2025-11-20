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

## Quick Start

### Prerequisites

- **AWS CLI**: Configured with appropriate credentials
- **kubectl**: Kubernetes command line tool
- **Helm**: Kubernetes package manager

### Deployment Sequence

The lessons must be deployed in order due to dependencies:

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

---

### Prerequisites

### Phase 1: Deploy EKS Infrastructure

### Phase 2: Configure kubectl

### Phase 3: Deploy Django Application

---

## Lesson 8-9 - Complete CI/CD Pipeline

### Overview

Implements a complete CI/CD pipeline with:

- **Jenkins** - Builds Docker images using Kaniko and pushes to ECR
- **Argo CD** - GitOps-based continuous deployment
- **Automated Workflow** - Code → Build → Deploy pipeline

### Architecture

```
Developer Push → GitHub → Jenkins Pipeline → Build Image (Kaniko)
->
Push to ECR + Update Helm Chart
->
Commit & Push to GitHub
->
Argo CD Detects Changes → Sync to EKS
```

### Prerequisites

- **Lesson 5** - VPC and ECR infrastructure deployed (REQUIRED)
- AWS CLI configured with appropriate credentials
- kubectl and Helm installed
- Git repository set up (GitHub/GitLab)

**Important Notes**:

- Lesson-7 is **NOT required** - Lesson 8-9 creates its own EKS cluster
- This lesson is **self-contained** and creates `lesson-8-9-eks` cluster

### Step 1: Update Git Repository URL

Edit `lesson-8-9/main.tf` and update:

```terraform
variable "git_repo_url" {
  default = "https://github.com/dikhomenko/my-microservice-project.git"
}
```

### Step 2: Deploy Infrastructure

```bash
# Navigate to lesson-8-9
cd lesson-8-9

# Initialize Terraform
terraform init

# Deploy Jenkins and Argo CD
terraform apply
```

This deploys:

- **EKS Cluster**: lesson-8-9-eks (new cluster, independent from lesson-7)
- **OIDC Provider**: For IRSA support
- **EBS CSI Driver**: For persistent volumes
- **Jenkins**: With Kaniko pod template
- **Argo CD**: With auto-sync enabled
- **Django Application**: Monitoring via Argo CD

### Step 3: Access Jenkins

```bash
# Get Jenkins URL
terraform output jenkins_url

# Get admin password
terraform output -raw jenkins_admin_password
```

Login to Jenkins:

- **URL**: Output from above
- **Username**: `admin`
- **Password**: Output from above

### Step 4: Configure Jenkins Pipeline

1. **Create Pipeline**:

   - Script Path: `lesson-8-9/Jenkinsfile`

2. **Add Git Credentials**

### Step 5: Access Argo CD

```bash
# Get Argo CD URL
terraform output argocd_server_url

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

Login to Argo CD:

- **URL**: Output from above
- **Username**: `admin`
- **Password**: Output from kubectl command

### Step 6: Run the Pipeline

### Step 7: Verify Deployment

After Jenkins completes:

1. **Configure kubectl for lesson-8-9 cluster**:

   ```bash
   aws eks update-kubeconfig --region us-west-2 --name lesson-8-9-eks
   ```

2. **Check Git**: Verify `lesson-8-9/charts/django-app/values.yaml` has new image tag

3. **Check Argo CD**: Application should auto-sync within 3 minutes

4. **Check Kubernetes**:
   ```bash
   kubectl get pods -n default
   kubectl describe pod <pod-name> | grep Image
   ```

### Key Features

#### Kaniko (Secure Docker Builds)

#### IRSA (IAM Roles for Service Accounts)

#### GitOps with Argo CD
