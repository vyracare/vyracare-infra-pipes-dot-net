variable "region" {
  type    = string
  default = "us-east-1"
}

variable "env_suffix" {
  type    = string
  default = "dev"
}

variable "cors_allow_origins" {
  description = "Allowed origins for API Gateway CORS"
  type        = list(string)
  default     = ["*"]
}

variable "api_gateway_name" {
  description = "Nome base do API Gateway"
  type        = string
}

variable "lambda_function_name" {
  description = "Nome da função Lambda"
  type        = string
}

variable "lambda_handler" {
  description = "Assembly/handler .NET da Lambda"
  type        = string
}

variable "route_base_path" {
  description = "Base path exposta no API Gateway sem barra inicial"
  type        = string

  validation {
    condition     = trimspace(var.route_base_path) != "" && !startswith(var.route_base_path, "/")
    error_message = "route_base_path must be non-empty and must not start with '/'."
  }
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

variable "lambda_memory_mb" {
  description = "Lambda memory in MB"
  type        = number
  default     = 1024
}

variable "lambda_provisioned_concurrency" {
  description = "Provisioned concurrency (0 disables)"
  type        = number
  default     = 0
}
