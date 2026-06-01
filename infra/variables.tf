variable "region" {
  type    = string
  default = "us-east-1"
}

variable "env_suffix" {
  type    = string
  default = "dev"
}

variable "cors_allow_origins" {
  description = "Allowed origins for API Gateway CORS (use * to allow all)"
  type        = list(string)
  default     = ["*"]
}

variable "api_id" {
  description = "Existing API Gateway ID to reuse"
  default     = "ef39m2gyya"
}

variable "authorizer_id" {
  description = "Existing API Gateway authorizer id for jwt-authorizer"
  type        = string
  default     = "ybcgn2"
}

variable "route_id_auth_login" {
  description = "Existing route id for POST /api/auth/login"
  type        = string
  default     = "zu799q8"
}

variable "route_id_auth_register" {
  description = "Existing route id for POST /api/auth/register"
  type        = string
  default     = "zycxv1m"
}

variable "route_id_auth_first_access_check" {
  description = "Existing route id for POST /api/auth/first-access/check"
  type        = string
  default     = "om3xvqs"
}

variable "route_id_auth_first_access_set_password" {
  description = "Existing route id for POST /api/auth/first-access/set-password"
  type        = string
  default     = "1pcuvk4"
}

variable "route_id_auth_forgot_password" {
  description = "Existing route id for POST /api/auth/forgot-password"
  type        = string
  default     = "iz6zzl9"
}

variable "lambda_function_name" {
  default = "vyracare-auth"
}

variable "lambda_source_dir" {
  type        = string
  description = "Absolute path to the published Lambda project directory"
  nullable    = false

  validation {
    condition     = trimspace(var.lambda_source_dir) != ""
    error_message = "lambda_source_dir must be a non-empty path."
  }
}

variable "user_pool_client_id" {
  default = "424aitrab2nma4ttgi0314dfst"
}

variable "user_pool_id" {
  default = "us-east-1_yZNKvAZTf"
}

variable "lambda_memory_mb" {
  description = "Lambda memory in MB (increases CPU proportionally)"
  type        = number
  default     = 1024
}

variable "lambda_provisioned_concurrency" {
  description = "Provisioned concurrency (0 disables)"
  type        = number
  default     = 0
}

variable "lambda_environment_variables" {
  description = "Environment variables injected into the Lambda function"
  type        = map(string)
  default     = {}
}
