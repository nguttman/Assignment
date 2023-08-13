provider "aws" {
  region = var.aws_region
}

resource "aws_dynamodb_table" "occurrences_table" {
  name         = "OccurrencesTable"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "ID"
    type = "S"
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "LambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_lambda_function" "calculate_lambda" {
  filename      = "lambdas/lambda1.py"
  function_name = "CalculateLambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda1.lambda_handler"
  runtime       = "python3.8"
}

resource "aws_lambda_function" "get_lambda" {
  filename      = "lambdas/lambda2.py"
  function_name = "GetLambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda2.lambda_handler"
  runtime       = "python3.8"
}

resource "aws_api_gateway_rest_api" "api" {
  name        = "OccurrenceAPI"
  description = "API for calculating occurrences"
}

resource "aws_iam_role" "api_gateway_execution_role" {
  name = "APIGatewayExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "api_gateway_execution_policy" {
  name = "APIGatewayExecutionPolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "lambda:InvokeFunction",
        Effect = "Allow",
        Resource = [
          aws_lambda_function.calculate_lambda.arn,
          aws_lambda_function.get_lambda.arn,
        ]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "api_gateway_execution_role_attachment" {
  policy_arn = aws_iam_policy.api_gateway_execution_policy.arn
  roles      = [aws_iam_role.api_gateway_execution_role.name]
}

resource "aws_api_gateway_resource" "calculate_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "calculate-number-of-occurrences"
}

resource "aws_api_gateway_resource" "get_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "get-number-of-occurrences"
}

resource "aws_api_gateway_method" "calculate_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.calculate_resource.id
  http_method   = "POST"
  authorization = "AWS_IAM"  # Change authorization to AWS_IAM
}

resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.get_resource.id
  http_method   = "GET"
  authorization = "AWS_IAM"  # Change authorization to AWS_IAM
}

resource "aws_api_gateway_integration" "calculate_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.calculate_resource.id
  http_method             = aws_api_gateway_method.calculate_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.calculate_lambda.invoke_arn
  credentials             = aws_iam_role.api_gateway_execution_role.arn
}

resource "aws_api_gateway_integration" "get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.get_resource.id
  http_method             = aws_api_gateway_method.get_method.http_method
  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_lambda.invoke_arn
  credentials             = aws_iam_role.api_gateway_execution_role.arn
}

resource "aws_api_gateway_method_response" "calculate_method_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.calculate_resource.id
  http_method = aws_api_gateway_method.calculate_method.http_method
  status_code = "200"
}

resource "aws_api_gateway_method_response" "get_method_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.get_resource.id
  http_method = aws_api_gateway_method.get_method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "calculate_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.calculate_resource.id
  http_method = aws_api_gateway_method.calculate_method.http_method
  status_code = aws_api_gateway_method_response.calculate_method_response.status_code
  response_templates = {
    "application/json" = ""
  }
}

resource "aws_api_gateway_integration_response" "get_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.get_resource.id
  http_method = aws_api_gateway_method.get_method.http_method
  status_code = aws_api_gateway_method_response.get_method_response.status_code
  response_templates = {
    "application/json" = ""
  }
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on  = [aws_api_gateway_integration.calculate_integration, aws_api_gateway_integration.get_integration]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "prod"
}

module "ssl_cert" {
  source = "terraform-aws-modules/acm/aws"
  version = "3.0.0"

  domain_name       = var.domain_name
  validation_method = "DNS"
  tags = {
    Terraform = "true"
  }
}

resource "aws_api_gateway_domain_name" "api_domain" {
  domain_name     = module.ssl_cert.this_acm_certificate_domain_name
  certificate_arn = module.ssl_cert.this_acm_certificate_arn
}

resource "aws_api_gateway_base_path_mapping" "api_mapping" {
  domain_name = aws_api_gateway_domain_name.api_domain.domain_name
  stage_name  = aws_api_gateway_deployment.deployment.stage_name
  api_id      = aws_api_gateway_rest_api.api.id
}

resource "aws_security_group" "api_gateway_sg" {
  name        = "api-gateway-sg"
  description = "Security Group for API Gateway"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_ips
  }
}

output "api_gateway_url" {
  value = "https://${aws_api_gateway_domain_name.api_domain.domain_name}"
}
