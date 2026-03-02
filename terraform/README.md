# Executive OS Terraform Deployment

Provisions the cloud infrastructure for the Executive OS backend.

## What This Creates

| Resource | AWS Service | Purpose |
|---|---|---|
| RDS PostgreSQL | `aws_db_instance` | Persistent state with pgvector support |
| Secrets Manager | `aws_secretsmanager_secret` | JWT + DB credentials |
| App Runner | `aws_apprunner_service` | Auto-deployed FastAPI backend |

## Prerequisites

- [Terraform 1.7+](https://developer.hashicorp.com/terraform/downloads)
- AWS CLI configured with a profile that has IAM permissions for RDS, App Runner, and Secrets Manager
- An [App Runner GitHub connection](https://docs.aws.amazon.com/apprunner/latest/dg/manage-connections.html) created in the AWS console (you'll need its ARN)

## Steps

### 1. Copy and configure variables
```bash
cp terraform.tfvars.example terraform.tfvars
# Fill in your values — especially db_pass, jwt_secret, github_connection_arn
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Preview the plan
```bash
terraform plan
```

### 4. Deploy
```bash
terraform apply
```

### 5. Enable pgvector on the database
After apply completes, connect to the RDS instance and run:
```sql
CREATE EXTENSION IF NOT EXISTS vector;
```
Then, from the backend, run Alembic migrations:
```bash
cd ../backend && alembic upgrade head
```

### 6. Wire up iOS & Next.js
The `backend_url` output is the HTTPS endpoint for the App Runner service. Set it as:
- **iOS**: `baseURL` in `APIService.swift`
- **Next.js**: `NEXT_PUBLIC_BACKEND_URL` environment variable in Vercel

## GitHub Actions Secrets Required

Set these in your repository Settings → Secrets → Actions:

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | AWS credentials |
| `AWS_SECRET_ACCESS_KEY` | AWS credentials |
| `DB_USER` | Postgres username |
| `DB_PASS` | Postgres password |
| `JWT_SECRET` | Random 256-bit secret |
| `GH_APPRUNNER_ARN` | App Runner GitHub connection ARN |
| `GH_REPO_URL` | Your GitHub repo URL |
| `VERCEL_TOKEN` | Vercel personal access token |
| `VERCEL_ORG_ID` | Vercel organization ID |
| `VERCEL_PROJECT_ID` | Vercel project ID |

> [!CAUTION]
> Never commit `terraform.tfvars` to version control. It contains production secrets. It is listed in `.gitignore`.
