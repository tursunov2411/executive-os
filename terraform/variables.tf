variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for all resources"
}

variable "db_name" {
  type        = string
  default     = "executiveos"
  description = "PostgreSQL database name"
}

variable "db_user" {
  type        = string
  description = "PostgreSQL master username"
}

variable "db_pass" {
  type        = string
  sensitive   = true
  description = "PostgreSQL master password (min 8 chars)"
}

variable "jwt_secret" {
  type        = string
  sensitive   = true
  description = "JWT signing secret for API token auth"
}

variable "github_connection_arn" {
  type        = string
  description = "ARN of the AWS App Runner GitHub connection"
}

variable "github_repo_url" {
  type        = string
  description = "Git repository URL for the FastAPI backend (e.g. https://github.com/your-org/executive-os)"
}

variable "github_branch" {
  type        = string
  default     = "main"
  description = "Git branch to deploy from"
}
