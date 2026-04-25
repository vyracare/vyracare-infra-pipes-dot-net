output "api_gateway_url" {
  description = "URL base do API Gateway"
  value       = "https://${aws_apigatewayv2_api.http_api.id}.execute-api.${var.region}.amazonaws.com"
}

output "lambda_function_name" {
  description = "Nome da função Lambda"
  value       = aws_lambda_function.backend_api.function_name
}
