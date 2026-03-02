output "backend_url" {
  description = "URL of the deployed FastAPI backend on App Runner"
  value       = aws_apprunner_service.backend.service_url
}

output "db_endpoint" {
  description = "PostgreSQL RDS endpoint — use this as DB_HOST"
  value       = aws_db_instance.executiveos.address
}

output "secrets_arn" {
  description = "ARN of the Secrets Manager secret holding JWT and DB credentials"
  value       = aws_secretsmanager_secret.executiveos_secrets.arn
}
