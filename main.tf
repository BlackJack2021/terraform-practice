terraform {
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

# lambda 用の S3 バケットを定義
resource "aws_s3_bucket" "lambda_code" {
    bucket = "lambda-code-bucket-unique-name-12345"
    tags = {
        Name = "Lambda Code Bucket"
        Environment = "Practice"
    }
}

resource "aws_s3_bucket_public_access_block" "lambda_code_public_access_block" {
    bucket = aws_s3_bucket.lambda_code.id
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

resource "aws_s3_object" "lambda_zip" {
    bucket = aws_s3_bucket.lambda_code.bucket
    key = "lambda/handler.zip"
    source = "${path.module}/lambda/handler.zip"
    tags = {
        Name = "Lambda Handler Zip"
        Environment = "Practice"
    }
}

# Lambda に適用可能な IAM ロールを構築する
resource "aws_iam_role" "lambda_role" {
    name = "lambda_role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "lambda.amazonaws.com"
                }
            }
        ]
    })
}

# 直前で構築された IAM ロールに対してポリシーを紐づけ
# ここでは CloudWatch Logs に関連するアクションをいくつか許可
resource "aws_iam_role_policy" "lambda_policy" {
    role = aws_iam_role.lambda_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ]
                Effect = "Allow"
                Resource = "arn:aws:logs:*:*:*"
            }
        ]
    })
}

# Lambda 関数を定義
resource "aws_lambda_function" "example" {
    function_name = "example_lambda"
    role = aws_iam_role.lambda_role.arn
    handler = "handler.lambda_handler"
    runtime = "python3.9"

    s3_bucket = aws_s3_bucket.lambda_code.bucket
    s3_key = aws_s3_object.lambda_zip.key

    environment {
        variables = {
            ENV = "production"
        }
    }

    tags = {
        Name = "Example Lambda"
        Environment = "Practice"
    }
}