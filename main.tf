# Terraform の設定をリモート状態管理に変更

terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
    required_version = ">= 1.3.0"

    backend "s3" {
        bucket = "terraform-state-unique-bucket-name-12345"
        key = "terraform.tfstate"
        region = "ap-northeast-1"
        dynamodb_table = "terraform-locks"
        encrypt = true
    }
}

provider "aws" {
    region = "ap-northeast-1"
}

resource "aws_s3_bucket" "example" {
    bucket = "terraform-practice-unique-bucket-name-12345"

    tags = {
        name = "Example S3 Bucket"
        environment = "Practice"
    }
}

resource "aws_s3_bucket_public_access_block" "example" {

    bucket = "terraform-practice-unique-bucket-name-12345"

    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}