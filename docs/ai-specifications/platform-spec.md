# AI Engineering Specification: Platform

| Field | Value |
|---|---|
| Spec ID | PLAT |
| Status | Accepted (implemented) |
| Owner | Platform team (`@platform-team`, see `.github/CODEOWNERS`) |
| Last updated | 2026-10-10 |
| Related specs | [terraform-modules-spec.md](terraform-modules-spec.md) · [workflow-spec.md](workflow-spec.md) · [repo-template-spec.md](repo-template-spec.md) · [governance-spec.md](governance-spec.md) · [developer-experience-spec.md](developer-experience-spec.md) |
| Related ADRs | ADR-0001 (cloud & compute), ADR-0002 (reusable workflows), ADR-0003 (repo template & onboarding), ADR-0004 (security & governance tooling) |

---

## 1. Purpose & Scope

This is the umbrella specification for the Acme Retail Ltd. **Internal Developer Platform (IDP)**. It defines
what the platform is, which components make it up, how application teams consume it, and the contract every
other specification in this directory refines. It is written to be executed by an AI coding agent or a human
engineer: every requirement is testable, and every interface named here exists in the repository.

**In scope**

| Component | Location | Detailed spec |
|---|---|---|
| Shared Terraform module library (6 modules) | `infrastructure/modules/*` | terraform-modules-spec.md |
| Reference environment composition | `infrastructure/environments/dev` | terraform-modules-spec.md |
| Reusable GitHub Actions workflows (3) + callers (2) | `.github/workflows/` | workflow-spec.md |
| Service repository template | `templates/service-repo-template/` | repo-template-spec.md |
| Governance files and security gates | `.github/CODEOWNERS`, `.github/PULL_REQUEST_TEMPLATE.md`, `SECURITY.md`, `reusable-security-scan.yml` | governance-spec.md |
| Self-service developer CLI | `scripts/idp.py` (+ `idp.ps1`, `idp` wrappers, legacy `*.ps1`) | developer-experience-spec.md |
| Reference application: Inventory Management System (IMS) | `app/ims/` | this spec, §5.3 |
| Architecture decisions | `docs/engineering-decisions/ADR-000{1..4}-*.md` | governance-spec.md §6 |

**Out of scope** — see §10.

## 2. Business Problem Addressed

| # | Acme Retail problem | How the platform addresses it | Primary spec |
|---|---|---|---|
| BP1 | Duplicate pipelines | One set of `on: workflow_call` workflows; app pipelines are inputs-only callers | workflow-spec.md |
| BP2 | Duplicate Terraform | Six composable modules; environments only pass variables | terraform-modules-spec.md |
| BP3 | Different repository structures | One repo template, scaffolded by `idp new-service` | repo-template-spec.md |
| BP4 | Inconsistent AI specifications | Six specs with a fixed 12-section structure; template ships the same skeleton | all specs |
| BP5 | Long onboarding | `idp doctor` → `idp new-service` → `idp bootstrap` → `idp ci`, no tickets to the platform team | developer-experience-spec.md |
| BP6 | High maintenance | Fixes land once in a shared asset and propagate by version bump (git `ref`) | governance-spec.md §versioning |

## 3. Context / Current State

The IMS started as a one-off application with its own pipeline and infrastructure. It has been refactored so
that it consumes only shared assets:

- **Application:** Python 3.12 / Flask 3 / Flask-SQLAlchemy / marshmallow, served by gunicorn on port 3000.
  Products CRUD, cart, checkout, orders, stats, and a browser UI at `/`.
- **CI:** `.github/workflows/ci.yml` calls `reusable-ci.yml` then `reusable-security-scan.yml`.
- **IaC:** `.github/workflows/terraform.yml` calls `reusable-terraform.yml` for each of the 6 modules and the
  `dev` environment.
- **Infra:** `infrastructure/environments/dev` composes networking → ecr → rds-postgres → iam-app-role →
  ecs-fargate-service.
- **Local run:** `docker compose` (`app/ims/docker-compose.yml`) or `python scripts/idp.py up` (Postgres
  16.4 + API containers on network `ims-net`).

There is no shared AWS account, registry, or GitHub organisation for this capstone. All validation is
therefore local or static (pytest, ruff, YAML parsing, `terraform validate`, Checkov, Trivy, Gitleaks).

## 4. Requirements

| ID | Level | Requirement |
|---|---|---|
| PLAT-R1 | MUST | Every reusable capability (module, workflow, template, script) lives in exactly one place and is consumed by reference (`uses:`, module `source`, CLI), never copy-pasted per application. |
| PLAT-R2 | MUST | A new application obtains CI, security scanning, and infrastructure by changing only inputs/variables (name, app dir, port, sizing) — no edits to workflow or module logic for the common case. |
| PLAT-R3 | MUST | All infrastructure is Terraform (`>= 1.5.0`, `hashicorp/aws ~> 5.0`) and is fmt/validate/Checkov-checked in CI before merge. |
| PLAT-R4 | MUST | Every PR touching application code runs Gitleaks, Trivy fs, and Trivy image gates (CRITICAL/HIGH fail). |
| PLAT-R5 | MUST | The full platform is demonstrable locally with Python 3.10+, git, and Docker or Podman; no cloud account is required. Terraform is optional locally (needed only for `idp tf-validate`). |
| PLAT-R6 | MUST | Every architecturally significant decision is recorded as an ADR in `docs/engineering-decisions/`. |
| PLAT-R7 | MUST | Every service exposes `GET /health` returning HTTP 200 JSON when healthy; the container `HEALTHCHECK` and the ALB target group both use it. |
| PLAT-R8 | MUST | Containers run as a non-root user and listen on the port given by `PORT` (default 3000). |
| PLAT-R9 | SHOULD | Consuming repos pin shared assets to a release tag (`modules/v1.0.0`, `workflows/v1.0.0`); `@main` is a placeholder only. |
| PLAT-R10 | SHOULD | The local CLI (`scripts/idp.py`) runs the same gates as CI so that "green locally" predicts "green in CI". |
| PLAT-R11 | MAY | Additional modules/workflows MAY be added if they follow the same interface conventions (terraform-modules-spec.md, workflow-spec.md). |

## 5. Interfaces / Contracts

### 5.1 Consumption contract for an application team

| Platform asset | How it is consumed | What the team changes |
|---|---|---|
| `reusable-ci.yml` | `jobs.<id>.uses:` | `app_dir`, `python_version`, `image_name` |
| `reusable-security-scan.yml` | `jobs.<id>.uses:` (`needs: ci`) | `app_dir`, `image_name`, `terraform_dir` |
| `reusable-terraform.yml` | `jobs.<id>.uses:` | `working_dir` |
| Terraform modules | `module "x" { source = ... }` | module input variables only |
| Repo template | `python scripts/idp.py new-service <name>` | app code, TODO(new-service) markers |
| Governance | inherited `.github/` files | team handle in CODEOWNERS |

### 5.2 Runtime contract for every service container

| Contract item | Value |
|---|---|
| Listen port | `$PORT`, default `3000` (`EXPOSE 3000`) |
| Health endpoint | `GET /health` → `200` JSON |
| User | non-root, uid `1001` (`appuser`) |
| Base image | `python:3.12-alpine`, multi-stage, `apk upgrade`, pip removed from runtime |
| Process | gunicorn (`wsgi:app` for IMS; `service.app:create_app()` for template) |
| Config | environment variables only; no secrets baked into images |

### 5.3 Reference application (IMS) contract

Configuration (`app/ims/app/__init__.py`, `database_url_from_env()`):

| Variable | Default | Effect |
|---|---|---|
| `DATABASE_URL` | — | If set, used verbatim as the SQLAlchemy URI (highest precedence) |
| `PGHOST` | — | If set (and no `DATABASE_URL`), builds `postgresql+psycopg2://PGUSER:PGPASSWORD@PGHOST:PGPORT/PGDATABASE` |
| `PGUSER` / `PGPASSWORD` / `PGDATABASE` | `ims` / `ims` / `ims` | Postgres connection parts |
| `PGPORT` | `5432` | Postgres port |
| (neither) | `sqlite:///inventory.db` | Local SQLite fallback |
| `API_KEY` | `demo-key` | Required `X-API-Key` value for product writes |
| `PORT` | `3000` | gunicorn bind port (Dockerfile `CMD`) |

HTTP endpoints (`app/ims/app/__init__.py`, `app/ims/app/routes.py`; documented in `app/ims/openapi.yaml`):

| Method | Path | Auth | Success | Errors |
|---|---|---|---|---|
| GET | `/` | — | 200 HTML UI | — |
| GET | `/health` | — | 200 `{"status":"ok","database":"ok"}` (executes `SELECT 1`) | 500 if DB unreachable |
| GET | `/api/v1/products` | — | 200 `{items,page,per_page,total,pages}` | 400 bad `sort` |
| GET | `/api/v1/products/<id>` | — | 200 | 404 |
| POST | `/api/v1/products` | `X-API-Key` | 201 | 400 validation, 401, 409 duplicate SKU |
| PUT | `/api/v1/products/<id>` | `X-API-Key` | 200 (full replace) | 400, 401, 404, 409 |
| PATCH | `/api/v1/products/<id>` | `X-API-Key` | 200 (partial) | 400, 401, 404, 409 |
| DELETE | `/api/v1/products/<id>` | `X-API-Key` | 204 (also removes cart lines) | 401, 404 |
| GET | `/api/v1/stats` | — | 200 `{total_products,total_units,inventory_value,low_stock,orders}` (`low_stock` = quantity < 5) | — |
| GET | `/api/v1/cart` | — | 200 `{items,total}` | — |
| POST | `/api/v1/cart` | — | 201 (`product_id`, `quantity` default 1, merges existing line) | 400, 404, 409 over stock |
| PUT | `/api/v1/cart/<item_id>` | — | 200 | 400, 404, 409 |
| DELETE | `/api/v1/cart/<item_id>` | — | 200 | 404 |
| DELETE | `/api/v1/cart` | — | 200 (cart cleared) | — |
| POST | `/api/v1/cart/checkout` | — | 201 order; stock decremented, cart emptied | 400 empty cart, 409 insufficient stock |
| GET | `/api/v1/orders` | — | 200 list, newest first | — |

Product list query parameters: `search` (case-insensitive on name or SKU), `category` (exact), `in_stock=true`,
`sort` (one of `id,name,price,quantity,category,created_at`; prefix `-` for descending; default `id`), `page`
(default 1), `per_page` (default 10, capped at 100). All errors are JSON `{"error": <name>, "message": <text>}`.

Data model (`models.py`): `Product(id, sku unique ≤40, name ≤120, category default "General", quantity ≥0,
price ≥0, created_at, updated_at)`, `CartItem(id, product_id unique FK, quantity ≥1)`, `Order(id, total,
items JSON snapshot, created_at)`. Validation in `schemas.py` (marshmallow). Seed data loaded by `seed.py` on
startup; tables created with `db.create_all()`.

## 6. Design Details

```mermaid
flowchart TB
    subgraph Platform["Platform repo (this repo)"]
        TFM["Terraform modules<br/>networking, ecr, iam-app-role,<br/>rds-postgres, s3-bucket, ecs-fargate-service"]
        WF["Reusable workflows<br/>reusable-ci / -security-scan / -terraform"]
        TMPL["templates/service-repo-template"]
        GOV["CODEOWNERS, PR template,<br/>SECURITY.md, ADRs"]
        CLI["scripts/idp.py"]
    end
    subgraph IMS["Reference app: app/ims"]
        A1[Flask app] --> C1[ci.yml]
        I1[environments/dev] --> T1[terraform.yml]
    end
    subgraph New["New service (scaffolded)"]
        A2[app/service] --> C2[ci.yml]
        I2[infrastructure/main.tf] --> T2[terraform.yml]
    end
    C1 & C2 -. workflow_call .-> WF
    T1 & T2 -. workflow_call .-> WF
    I1 -. "source ../../modules/*" .-> TFM
    I2 -. "source git::...?ref=modules/v1.0.0" .-> TFM
    CLI -- "new-service" --> New
    CLI -- "lint/test/build/scan/up" --> IMS
    GOV -. applies to .-> IMS & New
```

Target runtime (AWS, defined but not applied in this capstone):

```mermaid
flowchart LR
    U[Client] --> ALB["ALB :80 (or :443 with certificate_arn)"]
    ALB --> ECS["ECS Fargate task<br/>IMS container :3000"]
    ECS --> RDS[("RDS Postgres 16.4<br/>private subnets")]
    ECS -. secrets .-> SM[Secrets Manager]
    ECS -. logs .-> CW[CloudWatch Logs]
    ECR[ECR repo] -. image .-> ECS
```

Design principles: composition over forking; inputs are the only customization surface; local parity with
CI; every gate is fail-closed with documented, inline exceptions only.

## 7. Security Considerations

- Shift-left gates on every PR (governance-spec.md §4): Gitleaks, Trivy fs + image, Checkov.
- Least-privilege IAM via `iam-app-role` (no wildcard actions unless a caller passes them; empty resources ⇒ no policy).
- DB credentials generated by `random_password` and stored in Secrets Manager (never a variable default).
- RDS is never public (`publicly_accessible = false`, private subnets only).
- IMS write endpoints require `X-API-Key`; the default `demo-key` is for local use only and MUST be overridden
  in any deployed environment (see §10 known gaps).
- Images: non-root, pip/setuptools removed, OS packages upgraded at build.

## 8. Non-Functional Requirements

| ID | Category | Requirement |
|---|---|---|
| PLAT-N1 | Reproducibility | Fresh clone + `python scripts/idp.py doctor && python scripts/idp.py bootstrap && python scripts/idp.py ci --skip-containers` works on Windows/macOS/Linux. |
| PLAT-N2 | Onboarding time | A new service is scaffolded and passing its own tests in under 10 minutes. |
| PLAT-N3 | Observability | `/health` on every service; gunicorn access logs to stdout; CloudWatch log group in AWS. |
| PLAT-N4 | Portability | Docker and Podman are both supported (`idp` auto-detects, preferring podman). |
| PLAT-N5 | Cost | Dev defaults are minimal: `db.t4g.micro`, 20 GiB, single-AZ, Fargate 256 CPU / 512 MiB, 1 task. |
| PLAT-N6 | Maintainability | No reusable logic outside `reusable-*.yml`, `infrastructure/modules/`, `scripts/idp.py`. |

## 9. Acceptance Criteria / Validation

| # | Check | Command | Result (2026-10-10) |
|---|---|---|---|
| AC1 | IMS lint | `python scripts/idp.py lint` | Pass (ruff clean) |
| AC2 | IMS tests | `python scripts/idp.py test` | Pass, 6/6 (`tests/test_api.py`, in-memory SQLite) |
| AC3 | Template test | `python scripts/idp.py test --app templates/service-repo-template/app` | Pass, 1/1 |
| AC4 | Local CI (no containers) | `python scripts/idp.py ci --skip-containers` | Pass |
| AC5 | Workflow YAML parses | `python -c "import yaml,glob;[yaml.safe_load(open(f)) for f in glob.glob('.github/workflows/*.yml')]"` | Pass |
| AC6 | Terraform validate | `python scripts/idp.py tf-validate` | **Not run locally** — terraform not installed on the authoring machine; enforced in CI by `terraform.yml` |
| AC7 | Container live run | `python scripts/idp.py up` then `status` | **Not re-verified** after the Python migration |
| AC8 | All 6 specs present, 12-section structure, cross-linked | review | Pass |

## 10. Out of Scope / Future Work

- Hosted developer portal (Backstage); `idp` CLI is the self-service surface instead.
- Multi-cloud; AWS only.
- `terraform plan/apply` and image push in CI (needs credentials + OIDC role).
- Known gaps to fix:
  - No `API_KEY` is injected in ECS, so the default `demo-key` would apply.
  - The cart is global (single shared cart, no users/sessions).
- Release tagging (`modules/v1.0.0`, `workflows/v1.0.0`) once the repo is hosted on GitHub.

## 11. Instructions for AI Coding Agents

1. Read this spec first, then the component spec for the area you are changing.
2. Never duplicate logic into an app-level workflow or environment; add or extend a shared asset instead and
   expose the variation as an input/variable.
3. Before adding a new interface (endpoint, variable, input, CLI flag), update the relevant interface table in
   the same change. Tables MUST match code.
4. Keep `GET /health`, port 3000, non-root, and the Dockerfile contract intact.
5. After changes run `python scripts/idp.py ci --skip-containers` (and `ci` if a container runtime is
   available, `tf-validate` if terraform is installed). Report which checks you could not run.
6. Do not invent features; put ideas in §10 of the relevant spec.
7. Do not commit secrets, `.env`, or real account IDs; do not weaken a security gate to make CI pass.

## 12. Change Log

| Date | Change |
|---|---|
| 2026-10-10 | Rewritten to 12-section structure. IMS migrated from Node/Express to Python 3.12/Flask; added `scripts/idp.py` self-service CLI; documented IMS API, config precedence, and known gaps. |
| Earlier | Initial platform spec (Node-based IMS, PowerShell scripts). |
