provider "aws" {
  region = var.aws_region
}

####################
# PostgreSQL RDS
####################
resource "aws_db_instance" "executiveos" {
  identifier          = "executiveos-db"
  engine              = "postgres"
  engine_version      = "15.4"
  instance_class      = "db.t3.medium"
  allocated_storage   = 20
  db_name             = var.db_name
  username            = var.db_user
  password            = var.db_pass
  publicly_accessible = false
  skip_final_snapshot = true
  apply_immediately   = true

  tags = {
    Project = "ExecutiveOS"
  }
}

####################
# Secrets Manager
####################
resource "aws_secretsmanager_secret" "executiveos_secrets" {
  name        = "executiveos/app_secrets"
  description = "ExecutiveOS JWT and DB credentials"
}

resource "aws_secretsmanager_secret_version" "executiveos_secrets_version" {
  secret_id = aws_secretsmanager_secret.executiveos_secrets.id
  secret_string = jsonencode({
    JWT_SECRET   = var.jwt_secret
    DATABASE_URL = "postgresql://${var.db_user}:${var.db_pass}@${aws_db_instance.executiveos.address}:5432/${var.db_name}"
  })
}

####################
# App Runner (FastAPI Backend)
####################
resource "aws_apprunner_service" "backend" {
  service_name = "executiveos-backend"

  source_configuration {
    authentication_configuration {
      connection_arn = var.github_connection_arn
    }
    code_repository {
      repository_url = var.github_repo_url
      source_code_version {
        type  = "BRANCH"
        value = var.github_branch
      }
      code_configuration {
        configuration_source = "API"
        code_configuration_values {
          runtime      = "PYTHON_3"
          build_command = "pip install -r requirements.txt"
          start_command = "uvicorn main:app --host 0.0.0.0 --port 8080"
          port          = "8080"
          runtime_environment_variables = {
            DATABASE_URL = "postgresql://${var.db_user}:${var.db_pass}@${aws_db_instance.executiveos.address}:5432/${var.db_name}"
            JWT_SECRET   = var.jwt_secret
          }
        }
      }
    }
  }

  tags = {
    Project = "ExecutiveOS"
  }
}
