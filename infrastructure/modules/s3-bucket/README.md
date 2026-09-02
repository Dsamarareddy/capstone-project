# Module: s3-bucket

Generic private S3 bucket: AES256 encryption at rest by default, versioning, and full public-access block —
the baseline every application's storage should start from.

## Inputs
| Name | Type | Default | Description |
|---|---|---|---|
| `bucket_name` | string | — | Globally-unique bucket name |
| `versioning_enabled` | bool | `true` | Enable object versioning |
| `force_destroy` | bool | `false` | Allow deletion with objects still present (dev-only) |
| `tags` | map(string) | `{}` | Common tags |

## Outputs
| Name | Description |
|---|---|
| `bucket_id` | Bucket name/ID |
| `bucket_arn` | Bucket ARN |

## Example
```hcl
module "uploads_bucket" {
  source      = "../../modules/s3-bucket"
  bucket_name = "dev-ims-uploads"
  tags        = { Environment = "dev", Application = "ims", ManagedBy = "terraform" }
}
```
