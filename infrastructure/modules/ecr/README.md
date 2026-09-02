# Module: ecr

Private ECR repository with scan-on-push enabled and a lifecycle policy that expires untagged images after
14 days and caps retained tagged images.

## Inputs
| Name | Type | Default | Description |
|---|---|---|---|
| `name` | string | — | Repository name |
| `image_tag_mutability` | string | `IMMUTABLE` | `MUTABLE` or `IMMUTABLE` |
| `max_image_count` | number | `20` | Tagged images retained before expiry |
| `tags` | map(string) | `{}` | Common tags |

## Outputs
| Name | Description |
|---|---|
| `repository_url` | Push/pull URL for the repository |
| `repository_arn` | ARN of the repository |

## Example
```hcl
module "ecr" {
  source = "../../modules/ecr"
  name   = "dev-ims"
  tags   = { Environment = "dev", Application = "ims", ManagedBy = "terraform" }
}
```
