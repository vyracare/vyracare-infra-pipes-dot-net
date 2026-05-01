terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    archive = {
      source = "hashicorp/archive"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  lambda_source_dir_input = trimspace(var.lambda_source_dir)
  lambda_source_dir       = abspath(local.lambda_source_dir_input)
  api_gateway_full_name   = "${var.api_gateway_name}-${var.env_suffix}"
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = local.api_gateway_full_name
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = var.cors_allow_origins
    allow_methods = ["OPTIONS", "GET", "POST", "PUT", "PATCH", "DELETE"]
    allow_headers = [
      "authorization",
      "content-type",
      "x-amz-date",
      "x-api-key",
      "x-amz-security-token",
      "x-amz-user-agent"
    ]
    max_age = 3600
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = local.lambda_source_dir
  output_path = "${path.module}/lambda.zip"
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.lambda_function_name}-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "backend_api" {
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_exec.arn
  handler          = var.lambda_handler
  runtime          = "dotnet8"
  memory_size      = var.lambda_memory_mb
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  publish          = true
  timeout          = 30

  environment {
    variables = var.lambda_environment_variables
  }
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.backend_api.function_name}"
  retention_in_days = 14

  tags = {
    Environment = var.env_suffix
    Project     = var.api_gateway_name
  }
}

resource "aws_lambda_alias" "backend_api_live" {
  name             = "live"
  description      = "Alias para API Gateway usar a versão publicada"
  function_name    = aws_lambda_function.backend_api.function_name
  function_version = aws_lambda_function.backend_api.version
}

resource "aws_lambda_provisioned_concurrency_config" "backend_api" {
  count = var.lambda_provisioned_concurrency > 0 ? 1 : 0

  function_name                     = aws_lambda_function.backend_api.function_name
  qualifier                         = aws_lambda_alias.backend_api_live.name
  provisioned_concurrent_executions = var.lambda_provisioned_concurrency

  depends_on = [aws_lambda_alias.backend_api_live]
}

resource "aws_lambda_permission" "apigw" {
  statement_id_prefix = "AllowAPIGatewayInvoke-"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend_api.function_name
  qualifier     = aws_lambda_alias.backend_api_live.name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_alias.backend_api_live.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "api_root" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /${var.route_base_path}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "api_proxy" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /${var.route_base_path}/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "swagger_root" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /swagger"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "swagger_proxy" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /swagger/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "health" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /health"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}
