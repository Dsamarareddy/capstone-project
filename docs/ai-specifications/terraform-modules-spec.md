# AI Engineering Specification: Terraform Modules

## 1. Purpose
Define a shared library of Terraform modules that every application team composes to provision its AWS
infrastructure, eliminating duplicate, drifted, hand-rolled Terraform per application.

## 2. Cloud Target & Validation Strategy
- Cloud: AWS (per the capstone's preferred stack).
- No shared AWS account exists for this capstone, so modules are validated locally without `apply`:
  `terraform fmt -check`, `terraform validate`, and static analysis with Checkov (see
  `scripts/validate-terraform.ps1`). Real `apply` runs are the consuming team's responsibility once they have
  an account/credentials — the modules are written to be `apply`-ready (correct provider constraints, no
  placeholder resources).
- Modules do not hardcode account IDs, regions, or credentials; these are always caller-supplied variables.

## 3. Module Catalog

| Module | Purpose | Key inputs | Key outputs |
|---|---|---|---|
| `networking` | VPC, public/private subnets across 2 AZs, IGW, route tables, security groups | `vpc_cidr`, `az_count`, `name` | `vpc_id`, `private_subnet_ids`, `public_subnet_ids`, `app_security_group_id` |
| `ecr` | Private container registry repo with image scanning + lifecycle policy | `name`, `image_tag_mutability` | `repository_url`, `repository_arn` |
| `iam-app-role` | Least-privilege execution + task role for a containerized service | `name`, `allowed_actions`, `allowed_resources` | `execution_role_arn`, `task_role_arn` |
| `rds-postgres` | Single-AZ (dev) / Multi-AZ (prod-capable) Postgres instance in private subnets | `identifier`, `subnet_ids`, `vpc_security_group_ids`, `instance_class`, `allocated_storage`, `engine_version` | `endpoint`, `port`, `db_name`, `secret_arn` |
| `s3-bucket` | Generic private bucket: encryption at rest, versioning, public-access block | `bucket_name`, `versioning_enabled` | `bucket_id`, `bucket_arn` |
| `ecs-fargate-service` | ECS cluster + Fargate task definition + service + ALB for one app | `name`, `image_url`, `container_port`, `vpc_id`, `subnet_ids`, `execution_role_arn`, `task_role_arn`, `desired_count` | `alb_dns_name`, `service_name`, `cluster_name` |

## 4. Requirements
- R1: Every module MUST declare an explicit `required_providers` / `required_version` block (Terraform >= 1.5,
  `hashicorp/aws` ~> 5.0).
- R2: Every module MUST expose `variables.tf` (with `description` and `type` on every variable) and
  `outputs.tf` (with `description` on every output) — no undocumented interface.
- R3: No module may hardcode a region, account ID, CIDR beyond a sane default, or secret value.
- R4: Every resource that stores data at rest (`s3-bucket`, `rds-postgres`) MUST enable encryption by default,
  overridable only explicitly.
- R5: `rds-postgres` MUST NOT place the instance in a public subnet and MUST generate/store credentials via
  `aws_secretsmanager_secret`, never as a plain `variable` default.
- R6: `iam-app-role` MUST scope policies to the specific actions/resources passed in — no `*:*` policies.
- R7: `ecs-fargate-service` MUST enable container insights/logging to CloudWatch and set a non-root container
  user is enforced at the image level (see `workflow-spec.md` Dockerfile requirements), not the Terraform
  level.
- R8: Modules are composed, not forked: `infrastructure/environments/<env>/main.tf` calls modules by relative
  `source = "../../modules/<name>"`; a new application's environment repo (via the repo template) calls them
  by pinned git `source` + `ref` (a tag), so upstream module fixes propagate on a version bump.

## 5. Naming & Tagging Convention
- Resource name prefix: `<env>-<app>-<resource>` (e.g. `dev-ims-db`).
- Mandatory tags on every resource: `Environment`, `Application`, `ManagedBy = "terraform"`,
  `Repository`.

## 6. Reference Composition (this repo)
`infrastructure/environments/dev` composes `networking` → `ecr` + `iam-app-role` → `rds-postgres` →
`ecs-fargate-service` to stand up the full IMS stack. See `docs/architecture/ims-architecture.md` for the
resulting diagram.

## 7. Acceptance Criteria
- [ ] `terraform fmt -check -recursive` passes across `infrastructure/`.
- [ ] `terraform validate` passes for every module and for `environments/dev` (run per-directory after
      `terraform init`).
- [ ] Checkov reports zero HIGH/CRITICAL findings against `infrastructure/` (documented exceptions only, with
      inline `#checkov:skip=<CHECK_ID>:<reason>`).
- [ ] A second application can reuse all six modules by writing a new `environments/<name>` directory with
      different variable values only.

## 8. Related Specifications
`platform-spec.md` · `workflow-spec.md` (Terraform CI) · `governance-spec.md` (security gates)
