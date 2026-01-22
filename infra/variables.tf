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
  default     = "9t2mw7tno9"
}

variable "lambda_function_name" {
  default = "vyracare-auth-dev"
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
