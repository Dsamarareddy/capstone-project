# Module: rds-postgres

Single PostgreSQL RDS instance in private subnets only, with an auto-generated master password stored in
Secrets Manager (never a plaintext Terraform variable) — the execution role from `iam-app-role` is granted
`secretsmanager:GetSecretValue` on this secret so the running container can fetch credentials at start time
instead of them being baked into an image or task definition.

## Inputs
| Name | Type | Default | Description |
|---|---|---|---|
| `identifier` | string | — | RDS instance identifier |
| `db_name` | string | — | Default database name |
| `vpc_id` | string | — | VPC ID the instance's own security group is created in |
| `subnet_ids` | list(string) | — | **Private** subnet IDs for the DB subnet group |
| `allowed_security_group_ids` | list(string) | `[]` | Security groups (e.g. an ECS service SG) permitted to connect on 5432 |
| `instance_class` | string | `db.t4g.micro` | Instance size |
| `allocated_storage` | number | `20` | Storage in GiB |
| `engine_version` | string | `16.4` | Postgres version |
| `multi_az` | bool | `false` | Standby replica in a second AZ |
| `master_username` | string | `ims_admin` | Master username |
| `tags` | map(string) | `{}` | Common tags |

## Outputs
| Name | Description |
|---|---|
| `endpoint` | DB host |
| `port` | DB port |
| `db_name` | Default database name |
| `secret_arn` | Secrets Manager ARN holding `{username, password, host, port, dbname}` |
| `db_security_group_id` | The instance's own security group ID (for attaching ingress rules post-creation, breaking dependency cycles) |

## Example
```hcl
module "db" {
  source                     = "../../modules/rds-postgres"
  identifier                 = "dev-ims-db"
  db_name                    = "ims"
  vpc_id                     = module.networking.vpc_id
  subnet_ids                 = module.networking.private_subnet_ids
  allowed_security_group_ids = [module.ims_service.service_security_group_id]
  tags                       = { Environment = "dev", Application = "ims", ManagedBy = "terraform" }
}
```

> Note: this creates a dependency cycle risk if the ECS service also needs `db.secret_arn` at creation time.
> `environments/dev/main.tf` breaks the cycle by creating the DB first with an empty
> `allowed_security_group_ids`, then a second `aws_security_group_rule` (see that file) once the ECS service's
> security group exists.
