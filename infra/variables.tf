variable "region" {
  type = string
  default = "us-east-1"
}

variable "env_suffix" {
  type = string
  default = "dev"
}

variable "api_id" {
  default = "e5sydc9xvc"
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
