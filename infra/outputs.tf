output "api_gateway_url" {
  description = "URL base do API Gateway para chamadas do front-end"
  value       = "https://${aws_apigatewayv2_api.http_api.id}.execute-api.${var.region}.amazonaws.com"
}

output "cognito_user_pool_id" {
  description = "ID do Cognito User Pool"
  value       = aws_cognito_user_pool.user_pool.id
}

output "cognito_user_pool_client_id" {
  description = "ID do Cognito App Client (para login no front-end)"
  value       = aws_cognito_user_pool_client.app_client.id
}

output "lambda_function_name" {
  description = "Nome da função Lambda que atende o API Gateway"
  value       = aws_lambda_function.auth_api.function_name
}
