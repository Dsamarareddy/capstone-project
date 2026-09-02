# Environment: dev (IMS)

Composes the six shared modules in `infrastructure/modules/` into the full IMS stack: VPC → ECR + RDS →
least-privilege IAM roles → ECS Fargate service + ALB, with a root-level security group rule wiring the
running service into the database (see the note in `../../modules/rds-postgres/README.md` about why that
rule lives here rather than inside a module).

This is also the reference a second application team copies conceptually via
`templates/service-repo-template/infrastructure/main.tf` — same module sources, different variable values.

## Validate locally (no AWS account required)
```powershell
cd infrastructure/environments/dev
terraform init -backend=false
terraform fmt -check -recursive ../../..
terraform validate
```
Or run `../../../scripts/validate-terraform.ps1` from the repo root to check every module + environment at
once.

## Deploy (requires real AWS credentials — not part of this capstone's local demo)
```powershell
cp terraform.tfvars.example terraform.tfvars   # edit values as needed
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```
After `apply`, build and push the IMS image to the `ecr_repository_url` output, then the ECS service will
pull it on the next deployment/force-new-deployment.
