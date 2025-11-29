# Variables for S3 Backend Module

variable "bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}
