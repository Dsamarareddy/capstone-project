# AI Engineering Specification: Developer Experience

## 1. Purpose
Make the platform self-service: an engineer should be able to bootstrap a local dev environment, scaffold a
new service, and run the same checks CI runs — all from documented scripts, without asking the platform team
for help. This directly addresses the "long onboarding" and "high maintenance" business problems.

## 2. Self-Service Tooling (`scripts/`)

| Script | Purpose | Usage |
|---|---|---|
| `bootstrap.ps1` | One-command local dev setup: installs `app/ims` npm deps, copies `.env.example` → `.env` if missing, prints next steps | `./scripts/bootstrap.ps1` |
| `new-service.ps1` | Scaffolds a new application from `templates/service-repo-template`, substituting the service name into `package.json`, Terraform tags, and workflow inputs | `./scripts/new-service.ps1 -Name billing-service` |
| `security-scan.ps1` | Runs the same Gitleaks/Trivy/Checkov checks locally that CI runs, via container images (no local tool installs required) | `./scripts/security-scan.ps1` |
| `validate-terraform.ps1` | Runs `terraform fmt -check`, `terraform init -backend=false`, `terraform validate` across every module and environment | `./scripts/validate-terraform.ps1` |

## 3. Local Demo Path (what "run it yourself" means)
1. `./scripts/bootstrap.ps1`
2. `docker compose -f app/ims/docker-compose.yml up --build` (or `podman compose ...`) — brings up the IMS API
   + Postgres.
3. Exercise the API (`curl http://localhost:3000/health`, `curl http://localhost:3000/items`, etc. — see
   `app/ims/openapi.yaml`).
4. `./scripts/security-scan.ps1` — same gates as CI, run locally before opening a PR.
5. `./scripts/validate-terraform.ps1` — same Terraform checks as CI, run locally.

No live AWS account, shared registry, or shared Kubernetes cluster is required to complete this path, per the
capstone's local-reproducibility rule.

## 4. Documentation Standards
- Every module, workflow, script, and app has a `README.md` (or header comment for scripts) stating: purpose,
  inputs, outputs/side effects, and a runnable example.
- Diagrams are Mermaid, embedded directly in Markdown (renders on GitHub with no extra tooling) rather than
  binary image formats, so they stay diffable and reviewable in PRs.
- Architecture Decision Records use a fixed template (see `governance-spec.md` §5) so decisions are scannable
  across the project.

## 5. Requirements
- R1: Every script MUST work from a fresh clone with only Node.js + Docker/Podman + Terraform installed — no
  hidden dependency on the original author's machine state.
- R2: Every script MUST fail loudly (non-zero exit, clear message) rather than silently continuing, so
  developers get fast feedback.
- R3: `new-service.ps1` MUST refuse to overwrite an existing directory (see `repo-template-spec.md` R5).
- R4: The local demo path (§3) MUST be achievable in under 10 minutes on a machine that already has the
  prerequisites installed.

## 6. Acceptance Criteria
- [ ] All four scripts exist, are documented in this spec and in the root `README.md`, and run without error
      on a machine with only Node/Docker(or Podman)/Terraform installed.
- [ ] The local demo path in §3 is reproduced verbatim in the root `README.md`'s "Live Demo" section.

## 7. Related Specifications
`platform-spec.md` · `repo-template-spec.md` · `governance-spec.md`
