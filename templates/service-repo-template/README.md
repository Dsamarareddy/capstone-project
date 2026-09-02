# Service Repository Template

Starting point for any new application team onboarding onto the group1-advanced Internal Developer Platform.
Copy this directory (or run `scripts/new-service.ps1 -Name <your-service>` from the platform repo root) into
a new repository and follow the checklist below. See `docs/ai-specifications/repo-template-spec.md` in the
platform repo for the full specification this template implements.

## Onboarding checklist
- [ ] Replace `app/` with your real application code, keeping the Dockerfile contract: multi-stage build,
      non-root user, `HEALTHCHECK`, and an exposed `/health` endpoint.
- [ ] Edit `infrastructure/variables.tf` values (`app_name`, `container_port`, sizing) — do **not** change the
      module `source` lines in `infrastructure/main.tf`; they point at the platform's versioned shared
      modules.
- [ ] Edit `.github/workflows/ci.yml` inputs (`app_dir`, `image_name`) to match your app.
- [ ] Fill in `docs/ai-specifications/*.md` for your service (stubs are pre-filled with section headers).
- [ ] Open a PR — CODEOWNERS review and the security-scan gate apply automatically because they're inherited
      from this template's `.github/` files.

## What you get for free (no customization needed)
- CI: lint, test, container build (`reusable-ci.yml`)
- Security: Gitleaks + Trivy (fs & image) + Checkov, gating every PR (`reusable-security-scan.yml`)
- Infrastructure: VPC, ECR, least-privilege IAM, RDS Postgres, ECS Fargate + ALB, all as versioned shared
  Terraform modules (`reusable-terraform.yml` validates them in CI)

## Run locally
```powershell
cd app
npm install
npm start        # serves /health on :3000 immediately, before you've written any real routes
```

Every file you're expected to edit is marked with a `# TODO(new-service):` comment.
