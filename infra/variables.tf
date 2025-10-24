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
  description = "Path to the published Lambda project directory"
  default     = null
}

variable "user_pool_client_id" {
  default = "424aitrab2nma4ttgi0314dfst"
}

variable "user_pool_id" {
  default = "us-east-1_yZNKvAZTf"
}
