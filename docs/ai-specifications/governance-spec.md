# AI Engineering Specification: Governance & Security Standards

| Field | Value |
|---|---|
| Spec ID | GOV |
| Status | Accepted (implemented; branch protection documented, not configured) |
| Owner | Platform team (`@platform-team`) |
| Last updated | 2026-10-10 |
| Related specs | [platform-spec.md](platform-spec.md) · [workflow-spec.md](workflow-spec.md) · [terraform-modules-spec.md](terraform-modules-spec.md) · [repo-template-spec.md](repo-template-spec.md) · [developer-experience-spec.md](developer-experience-spec.md) |
| Related ADRs | ADR-0004 (security & governance tooling) |

---

## 1. Purpose & Scope

Define the review, ownership, security-gate, secrets, documentation, and versioning standards applied
uniformly to every repository on the platform, so security posture does not depend on which team built a
service. Covers: `.github/CODEOWNERS`, `.github/PULL_REQUEST_TEMPLATE.md`, `SECURITY.md`, the scan gates in
`reusable-security-scan.yml` / `reusable-terraform.yml`, the local `idp scan`, ADRs, and change management
for shared assets.

## 2. Business Problem Addressed

| Problem | Contribution |
|---|---|
| BP4 Inconsistent AI specifications | Fixed 12-section spec structure + ADR template enforced via review (CODEOWNERS on `docs/ai-specifications/`). |
| BP3 Different repo structures | Governance files ship in the template, so every repo inherits them. |
| BP6 High maintenance | Central gates and versioning policy; no per-team security tooling to maintain. |
| BP1/BP2 Duplication | Gates are defined once in reusable workflows. |

## 3. Context / Current State

- `CODEOWNERS` (placeholders `@platform-team`, `@ims-team`; effective only once hosted on GitHub):

| Path | Owner |
|---|---|
| `/infrastructure/` | `@platform-team` |
| `/.github/workflows/` | `@platform-team` |
| `/templates/` | `@platform-team` |
| `/scripts/` | `@platform-team` |
| `/docs/ai-specifications/` | `@platform-team` |
| `/docs/engineering-decisions/` | `@platform-team` |
| `/app/ims/` | `@ims-team` |

- PR template sections: *What changed*, *Why*, *How was this tested?*, *Security-sensitive surfaces touched?*
  (auth, IAM, secrets, network, none), *Checklist* (CI green, security gate green, docs updated).
- `SECURITY.md`: scope, automated gates, private vulnerability reporting via CODEOWNERS contacts.
- ADRs: `ADR-0001` cloud & compute, `ADR-0002` reusable workflow strategy, `ADR-0003` repo template &
  onboarding, `ADR-0004` security & governance tooling. Sections: Context, Problem, Decision, Alternatives
  Considered, Trade-offs, Consequences, Rationale.
- Two real Trivy findings were found in CI and fixed (transitive `qs` override in the former Node app; switch
  to Alpine base + strip package manager). The Python image keeps the same mitigations (`apk upgrade`, pip
  removed).

## 4. Requirements

| ID | Level | Requirement |
|---|---|---|
| GOV-R1 | MUST | PRs touching app code pass `ci` and `security-scan` jobs; PRs touching `infrastructure/**` pass `terraform.yml` (fmt/validate/Checkov). No bypass. |
| GOV-R2 | MUST | Changes to platform-owned paths (table §3) require `@platform-team` review via CODEOWNERS. |
| GOV-R3 | MUST | Every PR uses the PR template and declares security-sensitive surfaces; any checked box requires platform review. |
| GOV-R4 | MUST | No secret is committed (Gitleaks, full history). `.env` is gitignored; only `.env.example` with local demo values is committed. |
| GOV-R5 | MUST | Deployed secrets come from Secrets Manager (`rds-postgres` generated credentials) injected via ECS `secrets`, never baked into images or Terraform variable defaults. |
| GOV-R6 | MUST | Trivy (fs and image) fails on CRITICAL/HIGH; Checkov fails on any failed check (`soft_fail: false`); Gitleaks fails on any finding. |
| GOV-R7 | MUST | Accepted risks are suppressed inline with a reason (`# checkov:skip=<ID>: <reason>`, or a commented `.trivyignore` entry), never by removing or soft-failing a step. |
| GOV-R8 | MUST | Containers run as non-root (uid 1001); base images use a pinned tag family (`python:3.12-alpine`, `postgres:16.4-bookworm`), not `latest`. |
| GOV-R9 | MUST | Python dependencies are pinned with `==` in `requirements*.txt`. |
| GOV-R10 | MUST | IAM changes (`iam-app-role` or any `aws_iam_*`) are reviewed for least privilege; no `*` actions. |
| GOV-R11 | MUST | Architecturally significant decisions get an ADR using the fixed sections. |
| GOV-R12 | MUST | Shared modules/workflows are versioned by git tag (`modules/vX.Y.Z`, `workflows/vX.Y.Z`); breaking changes bump the major version and note it in the asset's README. |
| GOV-R13 | SHOULD | Deprecated shared assets remain functional for at least one minor version with a migration note. |
| GOV-R14 | SHOULD | Branch protection on `main`: required review, required checks (`CI`, `Security Scan`, Terraform jobs), up-to-date branches, no force-push. |
| GOV-R15 | SHOULD | Local scanner images used by `idp scan` are pinned to versions (currently `:latest`; see §10). |

## 5. Interfaces / Contracts

### 5.1 Security gates
| Gate | Where (CI) | Where (local) | Target | Fails on |
|---|---|---|---|---|
| Gitleaks | `reusable-security-scan.yml` `secrets-scan` | `idp scan` (`zricethezav/gitleaks:latest detect --redact`) | whole repo, full history | any secret |
| Trivy fs | `dependency-scan` | `idp scan` (`aquasec/trivy:latest fs --severity CRITICAL,HIGH --exit-code 1`) | `app_dir` / `--app` | CRITICAL, HIGH |
| Trivy image | `image-scan` | — (build with `idp build`, scan manually) | `<image_name>:ci-<sha>` | CRITICAL, HIGH |
| Checkov | `reusable-terraform.yml` per dir; `terraform-scan` when `terraform_dir` set | `idp scan` (`bridgecrew/checkov:latest -d infrastructure --compact --quiet`), skip with `--skip-iac` | Terraform | any failed check |

Local reports: `security-reports/gitleaks-report.json` (directory created by `idp scan`).

### 5.2 Exceptions register (summary)
All accepted Checkov exceptions are inline in module `main.tf` files; the full list is in
terraform-modules-spec.md §7. No `.trivyignore` exists today (no accepted Trivy findings).

### 5.3 ADR contract
File `docs/engineering-decisions/ADR-NNNN-<kebab-title>.md`, H1 `ADR-NNNN: <Title>`, sections in order:
Context, Problem, Decision, Alternatives Considered, Trade-offs, Consequences, Rationale.

### 5.4 AI specification contract
Every spec (platform and service) uses sections 1–12: Purpose & Scope; Business problem; Context; Requirements
(ID-prefixed, RFC 2119); Interfaces; Design; Security; NFRs; Acceptance; Out of scope; AI agent instructions;
Change log.

## 6. Design Details

```mermaid
flowchart LR
    PR[Pull request] --> TPL[PR template:<br/>security surfaces]
    PR --> CO{CODEOWNERS<br/>path match}
    CO -->|platform paths| PT[@platform-team review]
    CO -->|app/ims| AT[@ims-team review]
    PR --> G1[Gitleaks] & G2[Trivy fs] & G3[Trivy image] & G4[Checkov]
    G1 & G2 & G3 & G4 --> M{All green +<br/>approved?}
    PT & AT --> M
    M -->|yes| MERGE[Merge to main]
    M -->|no| FIX[Fix or inline<br/>reasoned suppression]
```

Defence in depth: local (`idp scan`) → PR gates → review → (future) deploy-time policy.

## 7. Security Considerations

- Placeholder CODEOWNERS handles provide no enforcement until replaced and the repo is on GitHub.
- `app/ims/.env.example` and `docker-compose.yml` contain local demo credentials (`ims/ims`, `demo-key`);
  these are intentionally non-secret and MUST NOT be reused in any deployed environment.
- The IMS `API_KEY` default (`demo-key`) applies if no env var is set; deployments MUST inject a real key from
  Secrets Manager (not done in `environments/dev` today).
- Checkov OSS has no severity data without a platform API key, so the gate is "any failed check", which is
  stricter than "HIGH/CRITICAL".

## 8. Non-Functional Requirements

| ID | Requirement |
|---|---|
| GOV-N1 | Gates are deterministic for a given commit (pinned deps; base tag families). |
| GOV-N2 | Gate output is human-readable in logs and machine-readable (SARIF) as artifacts. |
| GOV-N3 | Local scans need only a container runtime (no tool installs). |
| GOV-N4 | Governance adds no per-team maintenance: inherited from template, enforced centrally. |

## 9. Acceptance Criteria / Validation

| # | Check | How | Status (2026-10-10) |
|---|---|---|---|
| 1 | Governance files exist | `ls .github/CODEOWNERS .github/PULL_REQUEST_TEMPLATE.md SECURITY.md` | Pass |
| 2 | Four gates implemented | inspect `reusable-security-scan.yml` | Pass |
| 3 | ADRs present with fixed sections | `grep -h '^## ' docs/engineering-decisions/*.md` | Pass (ADR-0001..0004) |
| 4 | Deps pinned | `requirements*.txt` use `==` | Pass |
| 5 | Non-root image | `USER appuser` in Dockerfiles | Pass |
| 6 | Local scan | `python scripts/idp.py scan` | Not re-run after the Python migration |
| 7 | YAML/lint/tests | `python scripts/idp.py ci --skip-containers` | Pass (ruff clean, 6/6 tests) |

## 10. Out of Scope / Future Work

- Configure branch protection/rulesets once hosted (GOV-R14).
- Pin `idp scan` scanner images (`gitleaks`, `trivy`, `checkov`) to versions matching CI.
- Run `security-scan` on infrastructure-only PRs and on a schedule (nightly CVE re-scan).
- SBOM generation (Trivy `--format cyclonedx`) and image signing (cosign).
- Pre-commit hook running Gitleaks locally.
- Secret rotation for RDS credentials; OPA/conftest policies on `terraform plan`.

## 11. Instructions for AI Coding Agents

- Never disable, soft-fail, or skip a gate to get green CI; fix the finding, or add an inline reasoned
  suppression and list it in terraform-modules-spec.md §7.
- Never write real secrets, tokens, account IDs, or personal data into code, tests, docs, or examples.
- When touching IAM, networking, auth, or secrets, state it in the PR template and keep least privilege.
- Pin every new dependency (`==`) and base image tag family.
- Record any decision with real alternatives as a new ADR using §5.3.
- Keep CODEOWNERS paths in sync when adding top-level directories.

## 12. Change Log

| Date | Change |
|---|---|
| 2026-10-10 | Rewritten to 12-section structure; gates table with CI and local (`idp scan`) equivalents; CODEOWNERS table from file; ADR and spec contracts; noted Checkov "any failed check" semantics and unpinned local scanner images. Platform migrated to Python/Flask; `idp` CLI added. |
| Earlier | Initial governance spec. |
