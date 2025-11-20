# Backend configuration for lesson-8-9
# Uses the same S3 backend created by lesson-5 bootstrap

terraform {
  backend "s3" {
    bucket         = "dina-bucket-1"
    key            = "lesson-8-9/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
