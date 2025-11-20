# S3 Backend Module - DynamoDB Table for State Locking

resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
  
  tags = {
    Name        = var.dynamodb_table_name
    Purpose     = "Terraform state locking"
    ManagedBy   = "Terraform"
  }
  
  lifecycle {
    prevent_destroy = false  # Set to true in production
  }
}
