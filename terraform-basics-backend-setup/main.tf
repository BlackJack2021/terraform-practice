provider "aws" {
    region = "ap-northeast-1"
}

resource "aws_s3_bucket" "terraform_state" {
    bucket = "terraform-state-unique-bucket-name-12345"
    tags = {
        name = "Terraform State Bucket"
        environment = "Practice"
    }
}

resource "aws_s3_bucket_public_access_block" "privatize_terraform_state" {
    bucket = "terraform-state-unique-bucket-name-12345"
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
    bucket = aws_s3_bucket.terraform_state.id
    versioning_configuration {
      status = "Enabled"
    }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }

  hash_key = "LockID"

  tags = {
    Name        = "Terraform Lock Table"
    Environment = "Practice"
  }
}