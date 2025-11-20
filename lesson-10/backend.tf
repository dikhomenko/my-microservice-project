# Backend configuration for Terraform state
# Stores state in S3 with DynamoDB locking

terraform {
  backend "s3" {
    bucket         = "dina-bucket-1"
    key            = "lesson-10/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
