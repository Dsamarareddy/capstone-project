# Module: iam-app-role

Creates the two IAM roles every ECS Fargate service needs:
- **Execution role** — what ECS itself uses to pull the container image and ship logs (AWS managed
  `AmazonECSTaskExecutionRolePolicy`), plus `secretsmanager:GetSecretValue` scoped to `allowed_resources` when
  provided (so containers can inject DB credentials as ECS `secrets`).
- **Task role** — what the *application code* is allowed to do via the AWS SDK at runtime, scoped exactly to
  `allowed_actions` on `allowed_resources`. If either is empty, no runtime policy is attached (no `*:*`
  fallback) — the caller must explicitly opt into every permission the app needs.

## Inputs
| Name | Type | Default | Description |
|---|---|---|---|
| `name` | string | — | Name prefix for both roles |
| `allowed_actions` | list(string) | `[]` | IAM actions the task role may perform |
| `allowed_resources` | list(string) | `[]` | ARNs those actions apply to (also used for execution-role secret access) |
| `tags` | map(string) | `{}` | Common tags |

## Outputs
| Name | Description |
|---|---|
| `execution_role_arn` | ECS execution role ARN |
| `task_role_arn` | ECS task role ARN |

## Example
```hcl
module "iam" {
  source            = "../../modules/iam-app-role"
  name              = "dev-ims"
  allowed_actions   = ["s3:GetObject", "s3:PutObject"]
  allowed_resources = ["arn:aws:s3:::dev-ims-uploads/*"]
  tags              = { Environment = "dev", Application = "ims", ManagedBy = "terraform" }
}
```
