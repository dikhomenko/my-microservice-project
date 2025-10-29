# Backend configuration for Terraform state management (S3 and DynamoDB)

terraform {
  backend "s3" {
    bucket         = "dina-bucket-1"
    key            = "lesson-5/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}