# Module: s3-bucket

Generic private S3 bucket: KMS encryption at rest by default (AWS-managed `aws/s3` key — pass a customer CMK
via a follow-up if a specific application needs one), versioning, full public-access block, a lifecycle rule
that aborts stale multipart uploads and expires noncurrent versions after 90 days, and optional access
logging — the baseline every application's storage should start from.

## Inputs
| Name | Type | Default | Description |
|---|---|---|---|
| `bucket_name` | string | — | Globally-unique bucket name |
| `versioning_enabled` | bool | `true` | Enable object versioning |
| `force_destroy` | bool | `false` | Allow deletion with objects still present (dev-only) |
| `access_log_bucket_id` | string | `null` | Bucket to send access logs to; `null` skips logging |
| `tags` | map(string) | `{}` | Common tags |

## Explicitly out of scope (see inline `checkov:skip` comments in `main.tf`)
Cross-region replication and object-change event notifications are consumer-specific concerns a generic
bucket module shouldn't assume — layer them on top in the calling environment if a specific application
needs them.

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
