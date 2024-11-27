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

# ECR リポジトリの作成
resource "aws_ecr_repository" "practice_repo" {
    name = "practice-docker-lambda-deploy"
    image_tag_mutability = "MUTABLE"
    tags = {
        Name = "Practice Docker Lambda Repository"
        Environment = "Practice"
    }
}

# 構築したリポジトリのURLを出力
output "ecr_repository_url" {
    value = aws_ecr_repository.practice_repo.repository_url
}

# Lambda のロールを構築し、ポリシーをアタッチ
resource "aws_iam_role" "lambda_role" {
    name = "lambda_docker_role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Principal = {
                    Service = "lambda.amazonaws.com"
                }
                Action = "sts:AssumeRole"
            }
        ]
    })
}

resource "aws_iam_role_policy" "lambda_policy" {
    role = aws_iam_role.lambda_role.id
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ]
                Resource = "arn:aws:logs:*:*:*"
            },
            {
                Effect = "Allow"
                Action = [
                    "ecr:GetDownloadUrlForLayer",
                    "ecr:BatchGetImage"
                ]
                Resource = aws_ecr_repository.practice_repo.arn
            }
        ]
    })
}

resource "aws_lambda_function" "docker_lambda" {
    function_name = "practice_docker_lambda"
    role = aws_iam_role.lambda_role.arn
    package_type = "Image"
    timeout = 300

    image_uri = "${aws_ecr_repository.practice_repo.repository_url}:latest"

    environment {
        variables = {
            ENV = "production"
        }
    }

    tags = {
        Name = "Practice Doker Lambda"
        Environment = "Practice"
    }
}