# AI Engineering Specification: Repository Template

| Field | Value |
|---|---|
| Spec ID | TPL |
| Status | Accepted (implemented) |
| Owner | Platform team (`/templates/` → `@platform-team`) |
| Last updated | 2026-10-10 |
| Related specs | [platform-spec.md](platform-spec.md) · [workflow-spec.md](workflow-spec.md) · [terraform-modules-spec.md](terraform-modules-spec.md) · [governance-spec.md](governance-spec.md) · [developer-experience-spec.md](developer-experience-spec.md) |
| Related ADRs | ADR-0003 (repo template & onboarding) |

---

## 1. Purpose & Scope

Define `templates/service-repo-template/`, the single starting point for every new application repository,
and the scaffolding contract implemented by `python scripts/idp.py new-service`. In scope: template layout,
placeholder conventions, the minimal Flask skeleton, inherited workflows/Terraform/spec stubs, and the
onboarding procedure.

## 2. Business Problem Addressed

| Problem | Contribution |
|---|---|
| BP3 Different repository structures | Every service starts from the same layout. |
| BP5 Long onboarding | One command scaffolds a working, tested repo. |
| BP4 Inconsistent AI specifications | Template ships the six spec stubs with the standard 12 sections. |
| BP1/BP2 Duplicate pipelines/Terraform | Template references shared workflows/modules instead of copying them. |

## 3. Context / Current State

```
templates/service-repo-template/
  README.md                         onboarding checklist, "run locally"
  app/
    service/__init__.py
    service/app.py                  create_app(); GET /health only
    tests/__init__.py
    tests/test_health.py            1 test: /health 200 and service == placeholder
    requirements.txt                flask==3.0.3, gunicorn==23.0.0
    requirements-dev.txt            -r requirements.txt, pytest==8.3.3, ruff==0.7.1
    Dockerfile                      python:3.12-alpine multi-stage, uid 1001, HEALTHCHECK, gunicorn
  infrastructure/
    main.tf                         git-sourced shared modules @ ref=modules/v1.0.0
    variables.tf                    aws_region, app_name, environment_name, container_image_tag, container_port
    outputs.tf                      alb_dns_name, ecr_repository_url
  .github/workflows/
    ci.yml                          reusable-ci + reusable-security-scan (remote, @main placeholder)
    terraform.yml                   reusable-terraform on infrastructure/
  docs/ai-specifications/           6 fill-in stubs (same 12 sections as this directory)
```

Not included in the template (inherited from the org/platform instead): `CODEOWNERS`,
`PULL_REQUEST_TEMPLATE.md`, `SECURITY.md` — see §10.

## 4. Requirements

| ID | Level | Requirement |
|---|---|---|
| TPL-R1 | MUST | Template is runnable immediately: `pip install -r requirements-dev.txt && python -m service.app` serves `/health` on `$PORT` (default 3000), and `python -m pytest -q` passes. |
| TPL-R2 | MUST | The placeholder string is exactly `TODO-service-name`; every occurrence is replaced by `idp new-service` in files with extensions `.json .tf .py .txt .yml .yaml .md .ini .example`. |
| TPL-R3 | MUST | Every file a team must edit carries a `TODO(new-service):` marker; platform-owner follow-ups use `TODO(platform-owner):`. |
| TPL-R4 | MUST | Terraform uses `git::https://github.com/<org>/group1-advanced.git//infrastructure/modules/<name>?ref=modules/v1.0.0`; module `source` lines are not edited by teams. |
| TPL-R5 | MUST | Workflows are callers only (no `steps:`), using `<org>/group1-advanced/.github/workflows/reusable-*.yml`. |
| TPL-R6 | MUST | No application-specific (IMS/inventory) logic or naming in the template. |
| TPL-R7 | MUST | The Dockerfile keeps the platform container contract (platform-spec.md §5.2). |
| TPL-R8 | MUST | `idp new-service` refuses an existing target directory and rejects names that are not lowercase kebab-case. |
| TPL-R9 | SHOULD | The scaffold shape mirrors `app/ims` + `infrastructure/environments/dev` (same modules, same variables). |
| TPL-R10 | MAY | `--git` initialises a repo with an initial commit `chore: scaffold <name> from platform template`. |

## 5. Interfaces / Contracts

### 5.1 Scaffolding command
| Command / flag | Default | Behaviour |
|---|---|---|
| `python scripts/idp.py new-service <name>` | — | Copies template (ignoring `.venv`, `__pycache__`, `.pytest_cache`), substitutes placeholder |
| `--output <dir>` | sibling of repo: `<repo>/../<name>` | Target directory |
| `--git` | off | `git init`, `git add -A`, initial commit |
| `./scripts/new-service.ps1 -Name <n> [-OutputPath <dir>]` | — | Legacy standalone PowerShell implementation of the same copy + substitution (no name validation, no `--git`) |

Name rule (code): `name == name.lower()` and `name.replace("-", "").isalnum()`.

### 5.2 Files and what to customise
| File | Placeholder / TODO | Team action |
|---|---|---|
| `app/service/app.py` | `TODO-service-name`, TODO register blueprints | Replace with real routes; keep `create_app()` + `/health` |
| `app/tests/test_health.py` | asserts `service == "<name>"` | Add real tests |
| `app/Dockerfile` | TODO keep contract | Adjust `COPY`/`CMD` only if layout changes |
| `infrastructure/variables.tf` | `app_name` default, `container_port` | Set values |
| `infrastructure/main.tf` | TODO(platform-owner) `<org>` | Replaced by platform owner once hosted |
| `.github/workflows/ci.yml` | `app_dir: app`, `image_name` | Set if layout differs |
| `.github/workflows/terraform.yml` | `@main` | Pin tag when available |
| `docs/ai-specifications/*.md` | TODO(new-service) prompts | Fill in |

### 5.3 Template variables (`infrastructure/variables.tf`)
| Variable | Type | Default |
|---|---|---|
| `aws_region` | string | `"us-east-1"` |
| `app_name` | string | `"TODO-service-name"` |
| `environment_name` | string | `"dev"` |
| `container_image_tag` | string | `"latest"` |
| `container_port` | number | `3000` |

Outputs: `alb_dns_name`, `ecr_repository_url`.

### 5.4 Skeleton HTTP contract
| Method | Path | Response |
|---|---|---|
| GET | `/health` | 200 `{"status":"ok","service":"<name>","timestamp":"<ISO-8601 UTC>"}` |

## 6. Design Details

```mermaid
sequenceDiagram
    actor Dev
    participant CLI as idp new-service
    participant T as templates/service-repo-template
    participant R as ../<name>
    Dev->>CLI: python scripts/idp.py new-service billing-service --git
    CLI->>CLI: validate kebab-case; target must not exist
    CLI->>T: copytree (ignore .venv, __pycache__, .pytest_cache)
    T-->>R: files
    CLI->>R: replace TODO-service-name -> billing-service
    CLI->>R: git init + commit (if --git)
    CLI-->>Dev: next steps (replace app/service, set platform ref, fill specs)
    Dev->>R: python scripts/idp.py ci --app ../billing-service/app --skip-containers
```

Minimal customisation:

| Change required | Change NOT required |
|---|---|
| Service name (auto), port, sizing variables | Workflow logic |
| Application code in `app/service/` | Terraform module internals |
| Spec content | Dockerfile contract, CI steps |

## 7. Security Considerations

- Inherits all gates by calling the reusable security workflow with `terraform_dir: infrastructure` (Checkov
  runs on the service's Terraform too).
- Skeleton image is non-root, pip removed, `apk upgrade`d.
- No secrets or `.env` in the template.
- Remote `@main` refs are mutable; MUST be pinned once tags exist (TPL-R4/WF-R11).

## 8. Non-Functional Requirements

| ID | Requirement |
|---|---|
| TPL-N1 | Scaffold + first green test < 10 minutes. |
| TPL-N2 | Template stays small (one endpoint) so it is easy to review and replace. |
| TPL-N3 | Scaffolding is stdlib-only Python and works on Windows/macOS/Linux. |

## 9. Acceptance Criteria / Validation

| # | Check | Command | Result (2026-10-10) |
|---|---|---|---|
| 1 | Template tests | `python scripts/idp.py test --app templates/service-repo-template/app` | Pass, 1/1 |
| 2 | Template lint | `python scripts/idp.py lint --app templates/service-repo-template/app` | Pass (ruff clean) |
| 3 | Workflow YAML parses | see workflow-spec.md §9 | Pass |
| 4 | No IMS naming | `grep -ri "ims\|inventory" templates/service-repo-template` | Expected none in code |
| 5 | Scaffold | `python scripts/idp.py new-service sample-svc --output <tmp>` then test it | Supported; not re-run this revision |
| 6 | Template Terraform | `terraform init` in scaffold | Fails until `<org>` replaced (expected; TODO(platform-owner)) |

## 10. Out of Scope / Future Work

- Ship `CODEOWNERS`, PR template, and `SECURITY.md` inside the template (today they live only in the platform
  repo; the template README claims CODEOWNERS is inherited — it is not until added).
- GitHub "template repository" / cookiecutter publishing; `idp new-service --dry-run`.
- Stricter name validation (leading/trailing/double hyphens currently accepted).
- `.env.example` and docker-compose in the template.

## 11. Instructions for AI Coding Agents

- When generating a service from this template, run `idp new-service`; do not hand-copy.
- Preserve `create_app()`, `/health`, port 3000, and the Dockerfile contract.
- Do not edit module `source` lines or add `steps:` to workflows.
- Leave `TODO(platform-owner)` items for humans; resolve `TODO(new-service)` items.
- Changes to the template must keep `idp test --app templates/service-repo-template/app` passing and update
  §3/§5 here.

## 12. Change Log

| Date | Change |
|---|---|
| 2026-10-10 | Template app migrated to Flask skeleton (`service/app.py`, `tests/test_health.py`, pinned requirements, Python Dockerfile); scaffolding via `idp new-service` (`--output`, `--git`); rewritten to 12 sections. |
| Earlier | Node/Express skeleton scaffolded by `new-service.ps1`. |
