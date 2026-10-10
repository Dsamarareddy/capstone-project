## What changed

<!-- Describe the change. Link the issue/ticket if there is one. -->

## Why

<!-- The problem this solves or the capability it adds. -->

## How was this tested?

<!-- e.g. `python scripts/idp.py ci`, `python scripts/idp.py scan`, `python scripts/idp.py tf-validate`, manual docker compose run -->

## Security-sensitive surfaces touched?

- [ ] Authentication / authorization
- [ ] IAM roles or policies (`infrastructure/modules/iam-app-role`, or any `aws_iam_*` resource)
- [ ] Secrets handling (`.env.example`, Secrets Manager references, CI `secrets:`)
- [ ] Network/security groups
- [ ] None of the above

If any box above is checked, this PR requires platform-team review per `.github/CODEOWNERS` and
`docs/ai-specifications/governance-spec.md`.

## Checklist

- [ ] CI (`ci.yml` / `terraform.yml`) is green
- [ ] Security scan gate is green (or findings are explicitly suppressed with a reasoned inline comment)
- [ ] Docs updated (README, AI specifications, or an ADR) if this change affects them
