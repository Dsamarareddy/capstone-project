# group1-advanced — AI-Driven Cloud & DevSecOps Internal Developer Platform

Capstone submission for Acme Retail Ltd.'s AI-Driven Cloud & DevSecOps Modernization Program.

**Role:** Platform Engineer
**Mission:** Turn the one-off engineering built for the Inventory Management System (IMS) into a reusable
Internal Developer Platform (IDP) — shared Terraform modules, reusable GitHub Actions workflows, a repo
template, governance standards, and developer-experience tooling — so any application team can onboard with
minimal customization. See `presentation/capstone-presentation.md` for the full narrative walkthrough.

## Repository structure

```
README.md
app/ims/                       Sample application: Inventory Management System (Node.js/Express + Postgres)
infrastructure/modules/        Reusable Terraform modules (networking, ecr, ecs-fargate-service, rds-postgres, s3-bucket, iam-app-role)
infrastructure/environments/   Environment compositions that consume the shared modules (dev/ = IMS)
templates/service-repo-template/  Starter repo a new application team copies to onboard onto the platform
.github/workflows/             Reusable + caller GitHub Actions workflows (CI, security scanning, Terraform)
.github/CODEOWNERS, PULL_REQUEST_TEMPLATE.md   Governance
scripts/                       Developer-experience tooling (bootstrap, scaffold new service, security scan, terraform validate)
docs/ai-specifications/        The 6 required AI Engineering Specifications (primary artifact of this capstone)
docs/architecture/             Platform and IMS architecture diagrams (Mermaid)
docs/engineering-decisions/    Architecture Decision Records (ADR format)
presentation/                  Capstone presentation deck (Marp source, exportable to PPTX/PDF)
SECURITY.md                    Vulnerability reporting / security policy
```

## Prerequisites

| Tool | Needed for |
|---|---|
| Node.js 20+ / npm | Running/testing the IMS app |
| Git | Version control (this repo is a local git repo — see note below on remotes) |
| Docker Desktop **or** Podman | Building/running the live demo containers |
| Terraform >= 1.5 | Validating the Terraform modules |
| Python 3 (optional) | Re-running the YAML-validity check this session used |

> This repo was built and committed **locally only** — no GitHub remote was configured or pushed to during
> this session. Push it to a repo named `group1-advanced` yourself when you're ready to submit, per the
> capstone guide's naming convention.

## Live Demo

```powershell
./scripts/bootstrap.ps1                                          # npm install + seed .env

# Docker Desktop:
docker compose -f app/ims/docker-compose.yml up --build

# Podman (no `podman compose` plugin installed on this machine - wire it manually instead):
podman network create ims-net
podman run -d --name ims-db --network ims-net -e POSTGRES_USER=ims -e POSTGRES_PASSWORD=ims -e POSTGRES_DB=ims postgres:16.4-bookworm
podman build -t ims:demo -f app/ims/Dockerfile app/ims
podman run -d --name ims-api --network ims-net -p 3000:3000 `
  -e PGHOST=ims-db -e PGPORT=5432 -e PGUSER=ims -e PGPASSWORD=ims -e PGDATABASE=ims ims:demo

curl http://localhost:3000/health
curl -X POST http://localhost:3000/items -H "Content-Type: application/json" `
  -d '{"sku":"SKU-100","name":"Pallet Jack","quantity":5,"warehouseLocation":"A1","reorderLevel":1}'
curl http://localhost:3000/items
```

Then, once Terraform/a container runtime is confirmed on PATH:
```powershell
./scripts/validate-terraform.ps1     # terraform fmt/init/validate across every module + environment
./scripts/security-scan.ps1          # Gitleaks + Trivy (fs & image) + Checkov, via container images
```

## What was actually validated in this build session

- ✅ `npm test` in `app/ims` — **8/8 tests passing** (Jest + Supertest against `pg-mem`, no external services)
- ✅ Every `.github/workflows/*.yml` (including the template's) parses as valid YAML (`python -c "yaml.safe_load(...)"`)
- ✅ Manual cross-module review: every Terraform module's outputs match what `environments/dev/main.tf` and
  `templates/service-repo-template/infrastructure/main.tf` consume
- ✅ **Live demo actually run** with Podman (no `docker compose`/`podman-compose` plugin installed, so the
  containers were wired manually — see the exact commands above): built `ims:demo` from the real Dockerfile,
  ran it against a real `postgres:16.4-bookworm` container, and exercised the full CRUD lifecycle over HTTP —
  `GET /health` → `POST /items` → `GET /items` → `GET /items/:id` → `PUT /items/:id` → `DELETE /items/:id` →
  confirmed 404 after delete. Every response matched the OpenAPI contract in `app/ims/openapi.yaml`.
- ✅ `./scripts/security-scan.ps1` — run for real via Podman:
  - **Gitleaks**: clean, 0 findings.
  - **Checkov**: first real run found 40 failed checks; each was triaged individually (see
    `docs/engineering-decisions/ADR-0004-security-and-governance-tooling.md` addendum for the full
    breakdown) — real fixes applied for about 20 (including deleting one genuinely dead/orphaned security
    group Checkov's "attached to another resource" check caught), the remaining 24 explicitly deferred with
    a reasoned inline `#checkov:skip=<ID>:<reason>` comment each (ACM/WAF/cross-region-replication style
    items this capstone's no-domain dev environment can't satisfy, plus cost/complexity trade-offs already
    exposed as module variables). **Final result: 0 failed / 164 passed / 24 reasoned skips.**
  - **Trivy**: failed to download its vulnerability DB via this script — `x509: certificate signed by
    unknown authority` against `mirror.gcr.io`, i.e. this machine sits behind a TLS-intercepting corporate
    network/proxy whose root CA isn't trusted inside the container. GitHub-hosted runners don't sit behind
    that proxy, so once this repo was actually pushed to GitHub, Trivy ran for real in CI and found two
    rounds of genuine CVEs — both fixed (see `ADR-0004` addendum for the full breakdown): a transitive `qs`
    dependency (fixed via an npm `overrides` entry) and 13 CRITICAL/HIGH findings in the container image
    (npm's own bundled deps + unpatchable Debian OS packages, fixed by stripping npm from the runtime stage
    and switching the base image to `node:20.20.2-alpine`). Re-scanned locally with Trivy's `--insecure` flag
    to confirm: **0 CRITICAL/HIGH findings**, down from 13.
- 🔜 `terraform validate` — Terraform wasn't resolvable on this machine's PATH by the end of this session
  (the download appears not to have been extracted to the folder already added to PATH); re-run
  `./scripts/validate-terraform.ps1` once `terraform --version` works.

## Status

All six domains are built: specs, IMS reference app, Terraform modules, reusable workflows, repo template +
dev-experience scripts, governance, architecture docs + ADRs, and the presentation deck. See git history
(`git log --oneline`) for the incremental build order.
