# AI Engineering Specification: Repository Template

## 1. Purpose
Give every new application team a single starting point (`templates/service-repo-template/`) that already
wires up the platform's reusable workflows, Terraform module sourcing, governance files, and AI specification
stubs — so "different repository structures" and "long onboarding" stop being platform problems.

## 2. What the template contains
```
service-repo-template/
  README.md                          onboarding instructions + checklist
  app/                                minimal Express skeleton (health endpoint only) to replace with real app
    src/server.js
    Dockerfile
    package.json
  infrastructure/
    main.tf                           sources shared modules by pinned ref, variables only differ per app
    variables.tf
    outputs.tf
  .github/workflows/
    ci.yml                            calls reusable-ci.yml + reusable-security-scan.yml
    terraform.yml                     calls reusable-terraform.yml
  docs/ai-specifications/             blank stubs for the 6 specs, pre-filled with section headers
```

## 3. Onboarding Procedure (what a new team actually does)
1. Copy `templates/service-repo-template/` into a new repository (or run `scripts/new-service.ps1 -Name
   <service-name>` from this platform repo, which does the copy + placeholder substitution automatically).
2. Replace `app/` with the real application code, keeping the `Dockerfile` contract (multi-stage, non-root,
   `HEALTHCHECK`, exposes `/health`).
3. Edit `infrastructure/main.tf` variables (`app_name`, `container_port`, sizing) — module `source` lines are
   left untouched, pointing at the platform's shared modules.
4. Edit `.github/workflows/ci.yml`/`terraform.yml` inputs (`app_dir`, `image_name`) — no workflow logic is
   added.
5. Fill in the 6 AI specification stubs under `docs/ai-specifications/` for the new service.
6. Open a PR — governance checks (CODEOWNERS review, PR template, security scan gate) apply automatically
   because they are inherited from the copied `.github/` files.

## 4. Requirements
- R1: The template MUST be runnable immediately after copy (`npm install && npm start` serves `/health`)
  before any customization — proves the baseline isn't broken.
- R2: The template's Terraform MUST reference shared modules via a pinned `ref` (git tag/commit), never a
  relative path outside the template's own repo (relative paths only work inside this monorepo-style
  capstone submission; real onboarding uses a versioned module registry/git ref).
- R3: The template MUST NOT contain any application-specific business logic — only the minimal skeleton
  needed to prove the wiring works.
- R4: Every file a new team is expected to edit MUST contain a `# TODO(new-service):` marker comment
  explaining what to change.
- R5: `scripts/new-service.ps1` MUST be idempotent-safe (refuses to overwrite an existing target directory)
  and MUST substitute the service name into `package.json`, `main.tf` tags, and workflow `image_name` inputs.

## 5. Minimal Customization Checklist (what "reusable with minimal customization" means concretely)
| Change required | Change NOT required |
|---|---|
| App name / port / image name (variables) | Workflow YAML structure |
| Terraform variable values (sizing, env name) | Terraform module internals |
| Real application code under `app/` | CI/CD pipeline steps |
| AI specification content for the new service | Governance files (CODEOWNERS pattern, PR template) |

## 6. Acceptance Criteria
- [ ] `templates/service-repo-template` has no reference to `ims` or inventory-specific naming — fully
      generic.
- [ ] Every editable file has a `TODO(new-service)` marker.
- [ ] `scripts/new-service.ps1 -Name sample-billing-service` (dry-run reviewed) produces a directory structure
      identical in shape to `app/ims` + `infrastructure/environments/dev`, differing only in names/variables.

## 7. Related Specifications
`platform-spec.md` · `workflow-spec.md` · `terraform-modules-spec.md` · `developer-experience-spec.md` ·
`governance-spec.md`
