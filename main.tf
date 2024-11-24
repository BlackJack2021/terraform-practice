# 初めての Terraform 
# ここでは s3 にプライベートバケットを追加する処理を実行

terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
    required_version = ">= 1.3.0"
}

provider "aws" {
    region = "ap-northeast-1"
}

resource "aws_s3_bucket" "example" {
    bucket = "terraform-practice-unique-bucket-name-12345"
}

resource "aws_s3_bucket_public_access_block" "example" {

    bucket = "terraform-practice-unique-bucket-name-12345"

    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}