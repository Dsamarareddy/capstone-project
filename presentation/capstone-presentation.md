---
marp: true
theme: default
paginate: true
size: 16:9
style: |
  section { font-size: 26px; }
  h1 { color: #1a3c6e; }
  h2 { color: #1a3c6e; }
  code { font-size: 0.8em; }
---

# Advanced AI-Driven Cloud & DevSecOps Capstone
## From One App to a Reusable Internal Developer Platform

**group1-advanced** · Platform Engineer submission
Acme Retail Ltd. — Inventory Management System (IMS) onboarding

---

## Customer Background & Business Problems

Acme Retail Ltd. is modernizing its engineering org. IMS is ready to ship, but:

- Duplicate pipelines
- Duplicate Terraform
- Different repository structures
- Inconsistent AI specifications
- Long onboarding
- High maintenance

**Mission:** stop solving this per-application. Build reusable platform capabilities every team can adopt.

---

## Engineering Approach Followed

1. Understand the business problem
2. Break the solution into engineering domains
3. Write AI Engineering Specifications (.md) — **the primary artifact**
4. Use an AI coding agent (Claude Code) to generate the implementation from those specs
5. Review, validate, refactor, and secure the generated solution
6. Test, document, and package the final solution

Every domain below has a spec written *first*, then implemented — not the reverse.

---

## The 6 Required AI Engineering Specifications

| Spec | Answers |
|---|---|
| `platform-spec.md` | What is the platform, and what problem does it solve? |
| `terraform-modules-spec.md` | What infrastructure is reusable, and how is it validated without a cloud account? |
| `workflow-spec.md` | How is CI/CD shared instead of duplicated? |
| `repo-template-spec.md` | How does a new team onboard with minimal customization? |
| `governance-spec.md` | What security/review standards apply to everyone, uniformly? |
| `developer-experience-spec.md` | How is the platform self-service? |

All six live in `docs/ai-specifications/` and cross-link each other.

---

## Platform Architecture

```
 Shared Platform Assets                       Consuming Application Repos
 ----------------------                       ----------------------------
 Terraform modules  ----module source--->      app/ims  (this capstone's reference app)
 Reusable workflows ----workflow_call--->       .github/workflows/ci.yml, terraform.yml
 service-repo-template ---scaffolds--->        A NEW team's repo (billing-service, etc.)
 Governance + Dev-experience scripts --------> applies identically to every consumer
```

Full rendered Mermaid diagrams: `docs/architecture/platform-architecture.md` and
`docs/architecture/ims-architecture.md` — both apps call the same reusable workflows and
source the same Terraform modules; only inputs differ.

- Shared Terraform modules: `networking`, `ecr`, `iam-app-role`, `rds-postgres`, `s3-bucket`, `ecs-fargate-service`
- Shared GitHub Actions: `reusable-ci`, `reusable-security-scan`, `reusable-terraform`
- `templates/service-repo-template/` — what a second team copies to onboard
- No hosted portal (Backstage, etc.) — deliberately out of scope; see ADR-0001/0003

---

## Reference Application: Inventory Management System

- Node.js 20 / Express REST API + PostgreSQL 16
- CRUD on inventory items: `sku`, `name`, `quantity`, `warehouseLocation`, `reorderLevel`
- Multi-stage, non-root Dockerfile with `HEALTHCHECK`
- **8/8 tests passing** (Jest + Supertest, `pg-mem` in-memory Postgres — zero external services needed to prove correctness)
- `docker-compose.yml` for the local live demo (api + postgres)
- `openapi.yaml` documents every endpoint

```
GET    /health
GET    /items          POST   /items
GET    /items/:id      PUT    /items/:id      DELETE /items/:id
```

---

## Reusable Terraform Modules (AWS)

| Module | Purpose |
|---|---|
| `networking` | VPC, public/private subnets, NAT, security groups |
| `ecr` | Scanned, lifecycle-managed container registry |
| `iam-app-role` | Least-privilege execution + task roles (no `*:*` policies) |
| `rds-postgres` | Encrypted Postgres, private-subnet-only, creds in Secrets Manager |
| `s3-bucket` | Encrypted, versioned, public-access-blocked bucket |
| `ecs-fargate-service` | Fargate service + ALB with dedicated, correctly-scoped security groups |

`infrastructure/environments/dev` composes all six for IMS.
A second team reuses the *same* modules via a pinned git ref — only variables change.

---

## Reusable CI/CD (GitHub Actions)

```
App push/PR   -> ci.yml        -> workflow_call -> reusable-ci.yml
                                -> workflow_call -> reusable-security-scan.yml
Infra push/PR -> terraform.yml -> workflow_call -> reusable-terraform.yml
```

- Caller workflows (`ci.yml`, `terraform.yml`) contain **zero build/test/scan logic** — inputs only
- All logic lives once, in `reusable-*.yml` — fix once, every consumer benefits
- Security scanning runs on every PR, not just after merge

---

## Governance & Security Gates

Every PR touching `app/**`, `infrastructure/**`, or `.github/workflows/**` is gated by:

| Tool | Surface | Fails on |
|---|---|---|
| Gitleaks | Full repo diff | Any secret |
| Trivy (fs) | App dependencies | CRITICAL/HIGH CVE |
| Trivy (image) | Built container | CRITICAL/HIGH CVE |
| Checkov | Terraform | HIGH/CRITICAL misconfig |

Plus: `CODEOWNERS` (platform vs. app ownership), PR template with a security-sensitive-surface checklist,
`SECURITY.md`. Same checks run locally via `scripts/security-scan.ps1` before a PR is even opened.

---

## Developer Experience — Self-Service Onboarding

```powershell
./scripts/bootstrap.ps1                                   # npm install + .env seed
docker compose -f app/ims/docker-compose.yml up --build    # local live demo
./scripts/security-scan.ps1                                 # same gates as CI, locally
./scripts/validate-terraform.ps1                             # same terraform checks as CI, locally
./scripts/new-service.ps1 -Name billing-service              # onboard a NEW team in seconds
```

A new team goes from zero to a running `/health` endpoint, wired CI/CD, and Terraform-ready infrastructure
by editing **variables and inputs only** — no workflow or module logic changes required.

---

## Engineering Decisions (ADRs)

| ADR | Decision |
|---|---|
| 0001 | AWS + ECS Fargate over EKS/Lambda; validate via `terraform validate`+Checkov, not `apply` |
| 0002 | GitHub Actions `workflow_call` reusable workflows over composite actions or copy-paste |
| 0003 | Copyable repo template + scaffold script over a hosted Backstage-style portal |
| 0004 | Gitleaks + Trivy + Checkov, hard-failing on CRITICAL/HIGH, enforced identically local & CI |

Full Context / Problem / Decision / Alternatives / Trade-offs / Consequences / Rationale in
`docs/engineering-decisions/`.

---

## Validation Performed This Session

- ✅ `npm test` — 8/8 IMS API tests passing (pg-mem, zero external services)
- ✅ All GitHub Actions workflow YAML parsed successfully (Python `yaml.safe_load`)
- ✅ Manual cross-module consistency review (variable/output names match across every module boundary)
- ✅ Real, incremental local git history — no AI prompts or chat history committed
- 🔜 `terraform validate` / `docker compose up` / `./scripts/security-scan.ps1` — documented exact commands
  for the reviewer to run (see root `README.md` "Live Demo" section)

---

## Mapping to Success Criteria

| Reviewer checks | Where |
|---|---|
| Understanding of the business problem | This deck; `docs/ai-specifications/platform-spec.md` §2 |
| Quality of AI Engineering Specifications | `docs/ai-specifications/*.md` (all 6, cross-linked) |
| Engineering quality of the final solution | `app/ims`, `infrastructure/`, passing test suite |
| Security and automation | `reusable-security-scan.yml`, `SECURITY.md`, ADR-0004 |
| Validation of AI-generated artifacts | This slide + root README "what was actually run" section |
| Documentation and communication | `docs/architecture/*`, ADRs, this presentation |

---

## Live Demo

1. `docker compose -f app/ims/docker-compose.yml up --build`
2. `curl http://localhost:3000/health`
3. `curl -X POST http://localhost:3000/items -H "Content-Type: application/json" -d '{"sku":"SKU-100","name":"Pallet Jack","quantity":5,"warehouseLocation":"A1","reorderLevel":1}'`
4. `curl http://localhost:3000/items`
5. `./scripts/security-scan.ps1` (Gitleaks / Trivy / Checkov via container images)
6. `./scripts/validate-terraform.ps1` (once Terraform is on PATH)

---

# Thank You

**group1-advanced** — a reusable Internal Developer Platform, not a one-off app.

Repository layout, specs, modules, workflows, template, governance, and demo scripts are all in this repo —
ready for a second application team to onboard.
