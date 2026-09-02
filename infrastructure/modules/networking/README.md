# Module: networking

Provisions a VPC with public + private subnets across N availability zones, an internet gateway, a single NAT
gateway (dev-cost-optimized — see `docs/engineering-decisions/ADR-0001-cloud-and-compute-choice.md` for the
single-NAT trade-off), route tables, and a default application security group.

## Inputs
| Name | Type | Default | Description |
|---|---|---|---|
| `name` | string | — | Name prefix for all resources |
| `vpc_cidr` | string | `10.0.0.0/16` | CIDR block for the VPC |
| `az_count` | number | `2` | Number of AZs to spread subnets across |
| `tags` | map(string) | `{}` | Common tags |

## Outputs
| Name | Description |
|---|---|
| `vpc_id` | ID of the VPC |
| `public_subnet_ids` | List of public subnet IDs |
| `private_subnet_ids` | List of private subnet IDs |
| `app_security_group_id` | ID of the default app security group |

## Example
```hcl
module "networking" {
  source   = "../../modules/networking"
  name     = "dev-ims"
  vpc_cidr = "10.0.0.0/16"
  az_count = 2
  tags     = { Environment = "dev", Application = "ims", ManagedBy = "terraform" }
}
```
