# Lesson 8-9: Complete CI/CD Pipeline with Jenkins, Helm, Terraform, and Argo CD

## Overview

This lesson implements a complete CI/CD pipeline that automates the entire workflow from code commit to production deployment:

1. **Jenkins** - Builds Docker images using Kaniko and pushes to Amazon ECR
2. **Helm** - Packages Kubernetes applications
3. **Terraform** - Provisions and manages infrastructure (Jenkins + Argo CD)
4. **Argo CD** - Implements GitOps for continuous deployment

## Architecture

```
Developer Push → GitHub → Jenkins Pipeline → Build Image (Kaniko)
                                    ↓
                            Push to ECR + Update Helm Chart
                                    ↓
                          Commit & Push to GitHub
                                    ↓
                    Argo CD Detects Changes → Sync to EKS
```

### Key Features

- **Kaniko**: Builds Docker images without Docker daemon (secure, Kubernetes-native)
- **IRSA**: IAM Roles for Service Accounts for secure AWS authentication
- **GitOps**: Single source of truth in Git, Argo CD auto-syncs changes
- **Automated Pipeline**: Full automation from code to deployment

## Prerequisites

Before starting, ensure you have completed:

- ✅ **Lesson 5** - VPC and ECR infrastructure deployed
- ✅ **Lesson 7** - EKS cluster deployed (no modifications needed!)
- ✅ AWS CLI configured with appropriate credentials
- ✅ kubectl installed and configured
- ✅ Terraform >= 1.0 installed
- ✅ Git repository set up (GitHub/GitLab)

**Note**: This lesson is **self-contained** and does NOT require any changes to lesson-7. All EKS add-ons (OIDC provider, EBS CSI driver) are managed within lesson-8-9.

## Project Structure

```
lesson-8-9/
├── main.tf                          # Main Terraform configuration
├── backend.tf                       # S3 backend configuration
├── outputs.tf                       # Terraform outputs
├── Jenkinsfile                      # Jenkins pipeline definition
├── README.md                        # This file
├── modules/
│   ├── eks_addons/                  # EKS add-ons (OIDC + EBS CSI)
│   │   ├── eks_addons.tf           # OIDC provider + EBS CSI driver
│   │   ├── variables.tf            # Input variables
│   │   └── outputs.tf              # Module outputs
│   ├── jenkins/                     # Jenkins Helm module
│   │   ├── jenkins.tf              # Jenkins deployment + IRSA
│   │   ├── providers.tf            # Provider configurations
│   │   ├── variables.tf            # Input variables
│   │   ├── values.yaml             # Jenkins Helm values (Kaniko)
│   │   └── outputs.tf              # Module outputs
│   └── argo_cd/                    # Argo CD Helm module
│       ├── argo_cd.tf              # Argo CD deployment
│       ├── providers.tf            # Provider configurations
│       ├── variables.tf            # Input variables
│       ├── values.yaml             # Argo CD Helm values
│       ├── outputs.tf              # Module outputs
│       └── charts/
│           └── argo-apps/          # Helm chart for Argo CD Applications
│               ├── Chart.yaml
│               ├── values.yaml
│               └── templates/
│                   ├── application.yaml    # Application CRD
│                   └── repository.yaml     # Repository CRD
└── charts/
    └── django-app/                 # Django application Helm chart
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── configmap.yaml
            └── hpa.yaml
```

## Step-by-Step Setup

### Step 1: Verify Prerequisites

```bash
# Verify lesson-5 and lesson-7 are deployed
cd ../lesson-5
terraform output

cd ../lesson-7
terraform output

# Configure kubectl to access EKS cluster
aws eks update-kubeconfig --region us-west-2 --name lesson-7-eks
kubectl get nodes
```

**Note**: No changes to lesson-7 are required. This lesson deploys its own EKS add-ons.

### Step 2: Update Git Repository URL

Update the Git repository URL in `main.tf`:

```terraform
variable "git_repo_url" {
  description = "Git repository URL"
  type        = string
  default     = "https://github.com/YOUR-USERNAME/my-microservice-project.git"
}
```

### Step 3: Initialize and Deploy Terraform

```bash
# Navigate to lesson-8-9
cd lesson-8-9

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

This will:

- Create OIDC provider for EKS (for IRSA)
- Install EBS CSI driver with IRSA
- Create Jenkins namespace and service account with IRSA for ECR
- Deploy Jenkins via Helm with Kaniko pod template
- Create Argo CD namespace
- Deploy Argo CD via Helm
- Create Argo CD Application to monitor the django-app Helm chart

### Step 4: Access Jenkins

```bash
# Get Jenkins URL
terraform output jenkins_url

# Get Jenkins admin password
terraform output -raw jenkins_admin_password
```

Open Jenkins in your browser:

- **Username**: `admin`
- **Password**: (from terraform output)

### Step 5: Configure Jenkins Pipeline

#### Option A: Manual Pipeline Creation

1. Click **New Item** → Enter name "django-app-pipeline" → Select **Pipeline** → Click OK
2. Under **Pipeline** section:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: Your Git repository URL
   - **Branch**: `*/main`
   - **Script Path**: `lesson-8-9/Jenkinsfile`
3. Click **Save**

#### Option B: Using Jenkins Configuration as Code (Automated)

The Jenkins module already configures credentials via JCasC. Verify them:

1. Go to **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
2. You should see:
   - `ecr-repository-url`
   - `aws-region`
   - `aws-account-id`
   - `git-repo-url`

### Step 6: Set Up Git Credentials for Jenkins

For Jenkins to push changes back to Git, you need to add Git credentials:

#### Using GitHub Personal Access Token (Recommended)

1. Generate a GitHub PAT:

   - Go to GitHub → Settings → Developer settings → Personal access tokens → Generate new token
   - Select scopes: `repo` (full control of private repositories)
   - Copy the token

2. Add to Jenkins:

   - **Manage Jenkins** → **Credentials** → **System** → **Global credentials** → **Add Credentials**
   - **Kind**: Username with password
   - **Username**: Your GitHub username
   - **Password**: Your PAT
   - **ID**: `git-credentials`
   - **Description**: GitHub credentials

3. Update Jenkinsfile to use credentials:

```groovy
// In the "Commit and Push Changes" stage, add:
withCredentials([usernamePassword(
    credentialsId: 'git-credentials',
    usernameVariable: 'GIT_USERNAME',
    passwordVariable: 'GIT_PASSWORD'
)]) {
    sh """
        git config user.name "Jenkins CI"
        git config user.email "jenkins@ci.local"

        # Add credentials to URL
        git remote set-url origin https://\${GIT_USERNAME}:\${GIT_PASSWORD}@github.com/YOUR-USERNAME/my-microservice-project.git

        git add ${HELM_VALUES_PATH}
        git commit -m "Update Django app image tag to ${IMAGE_TAG} [ci skip]"
        git push origin main
    """
}
```

### Step 7: Access Argo CD

```bash
# Get Argo CD URL
terraform output argocd_server_url

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d
```

Open Argo CD in your browser:

- **Username**: `admin`
- **Password**: (from kubectl command)

### Step 8: Verify Argo CD Application

1. Login to Argo CD UI
2. You should see the **django-app** application
3. Click on it to view details:
   - **Sync Status**: Should be "Synced"
   - **Health Status**: Should be "Healthy"
   - **Last Sync**: Recent timestamp

### Step 9: Run the Jenkins Pipeline

1. Go to Jenkins → **django-app-pipeline**
2. Click **Build Now**
3. Monitor the pipeline stages:

   - ✅ Checkout
   - ✅ Build and Push Docker Image (using Kaniko)
   - ✅ Update Helm Chart
   - ✅ Commit and Push Changes

4. Check the console output for:
   ```
   Successfully built and pushed image: <ECR-URL>:<BUILD-NUMBER>
   Successfully pushed changes to repository
   ```

### Step 10: Verify Automatic Deployment

After Jenkins pipeline completes:

1. **Check Git**: Verify `lesson-8-9/charts/django-app/values.yaml` has the new image tag
2. **Check Argo CD**:
   - The application should auto-sync within 3 minutes
   - Status should show the new revision
3. **Check Kubernetes**:
   ```bash
   kubectl get pods -n default
   kubectl describe pod <pod-name> -n default | grep Image
   ```

## How It Works

### 1. Jenkins Pipeline Flow

```groovy
stage('Checkout')
  └─> Clone Git repository

stage('Build and Push Docker Image')
  └─> Kaniko builds image from Dockerfile
  └─> Push to ECR with build number tag and 'latest'

stage('Update Helm Chart')
  └─> Update values.yaml with new image tag using sed

stage('Commit and Push Changes')
  └─> Commit values.yaml changes
  └─> Push to main branch with [ci skip] to prevent loop
```

### 2. Kaniko Build Process

Kaniko runs as a pod in Kubernetes:

- **No Docker daemon required** (secure, no privileged containers)
- **Uses service account with IRSA** for ECR authentication
- **Automatic credential resolution** via AWS SDK
- **Layer caching** for faster builds

### 3. Argo CD GitOps Flow

```yaml
syncPolicy:
  automated:
    prune: true # Delete resources not in Git
    selfHeal: true # Auto-fix manual changes
  retry:
    limit: 5 # Retry failed syncs
```

Argo CD monitors the Git repository and:

1. Detects changes to `lesson-8-9/charts/django-app/`
2. Compares desired state (Git) vs actual state (Kubernetes)
3. Automatically syncs differences
4. Reports health status

## Configuration Deep Dive

### IRSA (IAM Roles for Service Accounts)

Jenkins service account is annotated with IAM role:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/jenkins-ecr-role
```

This allows Jenkins pods to:

- Assume IAM role automatically
- Get temporary AWS credentials
- Push to ECR without storing secrets

### Kaniko Pod Template

Defined in Jenkins values.yaml:

```yaml
containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:v1.19.0-debug
    command: "/busybox/sleep"
    args: "99d"
```

The `debug` variant includes a shell for debugging.

## Troubleshooting

### Jenkins Can't Push to ECR

**Symptom**: Error "no basic auth credentials"

**Solution**:

1. Verify IRSA role is attached:
   ```bash
   kubectl describe sa jenkins -n jenkins
   ```
2. Check IAM role has ECR permissions:
   ```bash
   aws iam get-role-policy --role-name lesson-7-eks-jenkins-ecr-role --policy-name lesson-7-eks-jenkins-ecr-policy
   ```

### Argo CD Not Syncing

**Symptom**: Application stuck in "OutOfSync"

**Solution**:

1. Check repository connection:
   ```bash
   kubectl get secret django-app-repo -n argocd
   ```
2. Check Argo CD logs:
   ```bash
   kubectl logs -n argocd deployment/argocd-repo-server
   ```
3. Manually sync:
   - Argo CD UI → **django-app** → **Sync** → **Synchronize**

### Kaniko Build Fails

**Symptom**: "error checking push permissions"

**Solution**:

1. Verify service account has IRSA annotation
2. Check pod logs:
   ```bash
   kubectl logs -n jenkins <pod-name> -c kaniko
   ```
3. Test ECR access from pod:
   ```bash
   kubectl exec -it -n jenkins <pod-name> -c kaniko -- /busybox/sh
   aws ecr get-login-password --region us-west-2
   ```

### Git Push Fails in Jenkins

**Symptom**: "Permission denied" or "Authentication failed"

**Solution**:

1. Verify Git credentials are configured
2. Check the credential ID matches in Jenkinsfile
3. For GitHub, ensure PAT has `repo` scope
4. Test credentials:
   ```bash
   git ls-remote https://YOUR-USERNAME:YOUR-TOKEN@github.com/YOUR-USERNAME/my-microservice-project.git
   ```

### Pipeline Triggers Infinite Loop

**Symptom**: Pipeline keeps triggering itself

**Solution**:

- Ensure commit message includes `[ci skip]` or `[skip ci]`
- Configure webhook to ignore commits from Jenkins
- Use separate branch for CI updates

## Architecture Decisions

### Why Kaniko over Docker-in-Docker?

| Feature                  | Kaniko                      | Docker-in-Docker            |
| ------------------------ | --------------------------- | --------------------------- |
| Security                 | ✅ No privileged containers | ❌ Requires privileged mode |
| Kubernetes-native        | ✅ Native support           | ❌ Workarounds needed       |
| Caching                  | ✅ Registry-based           | ✅ Volume-based             |
| Speed                    | Medium                      | Fast                        |
| Dockerfile compatibility | Most features               | Full compatibility          |

**Decision**: Kaniko is the industry standard for Kubernetes-based builds.

### Monorepo vs Separate GitOps Repo

#### Current Setup: Monorepo

✅ **Pros**:

- Simpler for learning/small projects
- Single repository to manage
- Easier to track application + deployment changes together

❌ **Cons**:

- Application changes trigger CI/CD even for doc updates
- Mix of concerns (app code + deployment config)

#### Alternative: Separate Repos

**App Repo**: `my-microservice-project`

- Application code
- Dockerfile
- Jenkins builds & pushes image

**GitOps Repo**: `my-microservice-gitops`

- Helm charts
- Kubernetes manifests
- Argo CD monitors this repo

✅ **Pros**:

- Clean separation of concerns
- Different teams can manage app vs infrastructure
- Independent access controls
- Deployment changes don't trigger app builds

❌ **Cons**:

- More complex to set up
- Need to manage multiple repositories

**Recommendation**: Start with monorepo for learning, move to separate repos for production.

### IRSA vs Storing AWS Credentials

| Approach           | Security                 | Rotation     | Audit         |
| ------------------ | ------------------------ | ------------ | ------------- |
| IRSA               | ✅ Temporary credentials | ✅ Automatic | ✅ CloudTrail |
| Static credentials | ❌ Long-lived            | ❌ Manual    | ❌ Limited    |

**Decision**: Always use IRSA in production.

## Monitoring and Observability

### Check Pipeline Status

```bash
# View Jenkins builds
curl -u admin:PASSWORD http://JENKINS-URL/job/django-app-pipeline/api/json

# View Argo CD application status
kubectl get application django-app -n argocd -o yaml

# View deployed pods
kubectl get pods -n default -l app.kubernetes.io/name=django-app
```

### View Logs

```bash
# Jenkins pod logs
kubectl logs -n jenkins deployment/jenkins

# Argo CD application controller logs
kubectl logs -n argocd deployment/argocd-application-controller

# Django app logs
kubectl logs -n default deployment/django-app
```

## Cleanup

To destroy all resources:

```bash
# Delete lesson-8-9 resources
terraform destroy

# Note: This will remove Jenkins and Argo CD but preserve:
# - EKS cluster (lesson-7)
# - VPC and ECR (lesson-5)
```

To clean up everything:

```bash
cd lesson-8-9 && terraform destroy
cd ../lesson-7 && terraform destroy
cd ../lesson-5 && terraform destroy
```

## Next Steps

- [ ] Add Slack/Email notifications to Jenkins pipeline
- [ ] Implement multi-environment deployment (dev/staging/prod)
- [ ] Add Prometheus/Grafana for monitoring
- [ ] Implement rollback strategy in Argo CD
- [ ] Add security scanning (Trivy, Snyk)
- [ ] Implement blue-green or canary deployments

## References

- [Jenkins Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)
- [Kaniko Documentation](https://github.com/GoogleContainerTools/kaniko)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [AWS IRSA Documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)

## Support

For issues or questions:

1. Check the Troubleshooting section
2. Review Jenkins/Argo CD logs
3. Verify AWS permissions and networking
4. Consult official documentation

---

**Created**: Lesson 8-9  
**Last Updated**: November 2025  
**Author**: DevOps Training
