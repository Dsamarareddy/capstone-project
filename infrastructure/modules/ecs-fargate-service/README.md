# Module: ecs-fargate-service

Runs one containerized service on ECS Fargate behind an internet-facing ALB: cluster, task definition,
service, target group/listener, CloudWatch log group, and its own dedicated security groups (ALB SG allows
inbound HTTP from `alb_ingress_cidr_blocks`; service SG allows inbound *only* from the ALB SG on
`container_port` — tasks are never directly reachable from the internet).

## Inputs
| Name | Type | Default | Description |
|---|---|---|---|
| `name` | string | — | Name prefix for cluster/service/ALB |
| `image_url` | string | — | Full image URL to run |
| `container_port` | number | `3000` | Port the container listens on |
| `health_check_path` | string | `/health` | ALB target group health check path |
| `cpu` / `memory` | number | `256` / `512` | Fargate task sizing |
| `desired_count` | number | `1` | Running task copies |
| `vpc_id` | string | — | VPC ID |
| `public_subnet_ids` | list(string) | — | Subnets for the ALB |
| `private_subnet_ids` | list(string) | — | Subnets for the Fargate tasks |
| `alb_ingress_cidr_blocks` | list(string) | `["0.0.0.0/0"]` | CIDRs allowed to reach the ALB |
| `execution_role_arn` / `task_role_arn` | string | — | From `iam-app-role` |
| `environment` | map(string) | `{}` | Plain env vars |
| `secrets` | map(string) | `{}` | `{ ENV_VAR = secretsmanager_arn }` injected as ECS secrets |
| `log_retention_days` | number | `400` | CloudWatch Logs retention |
| `log_kms_key_id` | string | `null` | CMK to encrypt the log group with; `null` uses CloudWatch's default |
| `certificate_arn` | string | `null` | ACM cert ARN; when set, adds a real `:443` listener + HTTP→HTTPS redirect. `null` (this capstone's dev environment - no domain) keeps plain HTTP on `:80` |
| `access_logs_bucket_id` | string | `null` | S3 bucket for ALB access logs; `null` skips logging |
| `enable_deletion_protection` | bool | `false` | ALB deletion protection (kept off in dev for clean `terraform destroy`) |
| `tags` | map(string) | `{}` | Common tags |

## Explicitly deferred (see inline `checkov:skip` comments in `main.tf`)
Attaching a WAF Web ACL is left to the calling environment (rule sets/rate limits are app-specific); the
HTTPS listener, access logging, and log-group KMS key are all real, working features — just off by default
because this capstone's dev environment has no domain, ACM certificate, or log bucket to point them at.

## Outputs
| Name | Description |
|---|---|
| `alb_dns_name` | Public DNS name to reach the service |
| `service_name` / `cluster_name` | ECS identifiers |
| `service_security_group_id` | SG attached to running tasks (e.g. to allow into the DB's SG) |

## Example
```hcl
module "ims_service" {
  source              = "../../modules/ecs-fargate-service"
  name                = "dev-ims"
  image_url           = "${module.ecr.repository_url}:latest"
  container_port      = 3000
  vpc_id              = module.networking.vpc_id
  public_subnet_ids   = module.networking.public_subnet_ids
  private_subnet_ids  = module.networking.private_subnet_ids
  execution_role_arn  = module.iam.execution_role_arn
  task_role_arn       = module.iam.task_role_arn
  secrets             = { DATABASE_SECRET_ARN = module.db.secret_arn }
  tags                = { Environment = "dev", Application = "ims", ManagedBy = "terraform" }
}
```
