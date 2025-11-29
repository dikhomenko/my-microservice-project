# Backend configuration for Terraform state
# Stores state in S3 with DynamoDB locking for state consistency

terraform {
  backend "s3" {
    bucket         = "final-project-terraform-state"
    key            = "final-project/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "final-project-terraform-locks"
  }
}
