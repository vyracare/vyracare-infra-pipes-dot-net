terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

provider "aws" {
  region = var.region
}

# ------------------------------
# Cognito User Pool + App Client
# ------------------------------
resource "aws_cognito_user_pool" "user_pool" {
  name = "vyracare-user-pool-${var.env_suffix}"
  auto_verified_attributes = ["email"]
}

resource "aws_cognito_user_pool_client" "app_client" {
  name            = "vyracare-spa-client-${var.env_suffix}"
  user_pool_id    = aws_cognito_user_pool.user_pool.id
  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  allowed_oauth_flows       = ["code"]
  allowed_oauth_scopes      = ["openid", "email", "profile"]
  allowed_oauth_flows_user_pool_client = true

  callback_urls = ["http://localhost:4200/"]
  logout_urls   = ["http://localhost:4200/"]
}

# ------------------------------
# API Gateway
# ------------------------------
resource "aws_apigatewayv2_api" "http_api" {
  name          = "vyracare-api-${var.env_suffix}"
  protocol_type = "HTTP"
}

# ------------------------------
# Lambda Function
# ------------------------------
locals {
  lambda_source_dir = (
    var.lambda_source_dir != null && trimspace(var.lambda_source_dir) != ""
    ? abspath(var.lambda_source_dir)
    : abspath("${path.module}/../backend/Vyracare.Auth/publish")
  )
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = local.lambda_source_dir
  output_path = "${path.module}/lambda.zip"
}

resource "aws_iam_role" "lambda_exec" {
  name = "vyracare-lambda-exec-${var.env_suffix}"
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

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.auth_api.function_name}"
  retention_in_days = 14

  tags = {
    Environment = var.env_suffix
    Project     = "vyracare-auth"
  }

  lifecycle {
    prevent_destroy = true   # não apaga os logs existentes
    ignore_changes  = [retention_in_days] # evita recriação por mudança de retenção
  }
}


resource "aws_lambda_function" "auth_api" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_exec.arn
  handler       = "Vyracare.Auth" # apenas o nome do assembly!
  runtime       = "dotnet8"
  filename      = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  publish = true
  timeout = 30
}



resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}


# ------------------------------
# API Gateway Integration + Authorizer
# ------------------------------
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.http_api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.auth_api.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  api_id          = aws_apigatewayv2_api.http_api.id
  name            = "jwt-authorizer"
  authorizer_type = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.app_client.id]
    issuer   = "https://cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.user_pool.id}"
  }
}

# ------------------------------
# Rotas
# ------------------------------
resource "aws_apigatewayv2_route" "auth_login" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /api/auth/login"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "auth_register" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /api/auth/register"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# ------------------------------
# Stage
# ------------------------------
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}
