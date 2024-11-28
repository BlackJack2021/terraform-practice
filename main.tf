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
            },
            {
                Effect = "Allow",
                Action = [
                    "kms:Decrypt",
                    "kms:Encrypt",
                    "kms:GenerateDataKey",
                ],
                Resource = "*"
            },
            {
                Effect = "Allow",
                Action = [
                    "s3:GetObject"
                ],
                Resource = "arn:aws:s3:::${var.bucket_name}/${var.prefix}/*"
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

# Step Functions の最初に行う doc_ids を取得する処理を追加
resource "aws_lambda_function" "doc_id_extractor" {
    function_name = "doc_id_extractor"
    role = aws_iam_role.lambda_role.arn
    handler = "doc_id_extractor.handler.lambda_handler"
    runtime = "python3.12"
    timeout = 60
    
    filename = "${path.module}/doc_id_extractor/doc_id_extractor.zip"

    environment {
        variables = {
            BUCKET_NAME = var.bucket_name
            PREFIX = var.prefix
        }
    }

    tags = {
        Name = "DocID Extractor"
        Environment = "Practice"
    }
}

# 以下 Step Functions を追加
# まずはロールの定義
resource "aws_iam_role" "step_functions_role" {
    name = "step_functions_role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow",
                Principal = {
                    Service = "states.amazonaws.com"
                },
                Action = "sts:AssumeRole"
            }
        ]
    })
}

# ロールに Lambda を実行するための権限を付与
resource "aws_iam_role_policy" "step_functions_policy" {
    role = aws_iam_role.step_functions_role.id
    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            {
                Effect = "Allow",
                Action = [
                    "lambda:InvokeFunction"
                ],
                Resource = [
                    aws_lambda_function.docker_lambda.arn,
                    aws_lambda_function.doc_id_extractor.arn,
                ]
            }
        ]
    })
}

# Step Functions の処理を定義
resource "aws_sfn_state_machine" "string_processing_machine" {
    name = "string_processing_machine"
    role_arn = aws_iam_role.step_functions_role.arn
    definition = jsonencode({
        Comment: "Step Function to process doc_ids strings sequentially with Lambda",
        StartAt: "ExtractDocIDs",
        States: {
            ExtractDocIDs: {
                Type: "Task",
                Resource: aws_lambda_function.doc_id_extractor.arn,
                ResultPath: "$",
                Next: "ProcessStrings"
            },
            ProcessStrings: {
                Type: "Map",
                ItemsPath: "$.doc_ids",
                Parameters: {
                    "input_string.$": "$$.Map.Item.Value"
                },
                Iterator: {
                    StartAt: "InvokeLambda",
                    States: {
                        InvokeLambda: {
                            Type: "Task",
                            Resource: aws_lambda_function.docker_lambda.arn,
                            End: true
                        }
                    }
                },
                End: true
            }
        }
    })
}