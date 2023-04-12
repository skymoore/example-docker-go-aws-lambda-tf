
variable "tags" {
  type    = map(string)
  default = {}
}

resource "aws_sqs_queue" "my_queue" {
  name                    = "test-go-lambda-queue"
  sqs_managed_sse_enabled = true
}

resource "aws_lambda_function" "my_lambda" {
  function_name = "test-go-lambda"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.lambda_repository.repository_url}:latest"
  memory_size   = 128
  timeout       = 10
  role          = aws_iam_role.lambda_role.arn
}

resource "aws_lambda_event_source_mapping" "sqs_lambda_mapping" {
  event_source_arn = aws_sqs_queue.my_queue.arn
  function_name    = aws_lambda_function.my_lambda.function_name
  batch_size       = 1
}

resource "aws_ecr_repository" "lambda_repository" {
  name                 = "test-go-lambda"
  image_tag_mutability = "MUTABLE"
}

resource "aws_iam_role" "lambda_role" {
  name = "test-go-lambda-role"

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

resource "aws_iam_policy" "ecr_read_policy" {
  name        = "test-lambda-ecr-read-policy"
  description = "Allows Lambda function to read images from ECR repository"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Effect   = "Allow"
        Resource = aws_ecr_repository.lambda_repository.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_policy_attachment" {
  policy_arn = aws_iam_policy.ecr_read_policy.arn
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

output "lambda_repository_url" {
  value = aws_ecr_repository.lambda_repository.repository_url
}
