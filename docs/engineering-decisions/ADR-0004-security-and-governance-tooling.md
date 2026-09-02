# ADR-0004: Security and Governance Tooling

## Context
The capstone requires security and automation as an explicit success criterion, and recommends Trivy,
Checkov, and Gitleaks by name. "High maintenance" and inconsistent practices across teams are named business
problems that a uniform, automatically-enforced security baseline directly addresses.

## Problem
Which security scanning tools cover secrets, dependency/image vulnerabilities, and infrastructure
misconfiguration, and how should they be enforced so no team can accidentally skip them?

## Decision
Adopt exactly the guide's recommended trio, each targeting a distinct surface:
- **Gitleaks** — secret scanning across the full git diff.
- **Trivy** — dependency vulnerabilities (filesystem mode over `app/ims`) and container image vulnerabilities
  (image mode over the built image), both failing the build on CRITICAL/HIGH.
- **Checkov** — Terraform static analysis, failing on HIGH/CRITICAL misconfiguration.

All three run inside `reusable-security-scan.yml`/`reusable-terraform.yml` (see ADR-0002) so every consuming
application inherits them automatically rather than opting in, and the same checks are runnable locally via
`scripts/security-scan.ps1` / `scripts/validate-terraform.ps1` so developers get identical feedback before
ever opening a PR.

## Alternatives Considered
- **Snyk / Dependabot alone**: strong dependency-vulnerability coverage but no secret-scanning or
  IaC-misconfiguration coverage in one product tier without a paid plan; the guide's three-tool combination
  gives full-surface coverage using only free, open-source tools.
- **`git-secrets` instead of Gitleaks**: narrower pattern set and no maintained SARIF output for CI
  integration; Gitleaks has broader default rules and is explicitly named in the guide.
- **`tfsec` instead of/alongside Checkov**: functionally overlapping with Checkov for Terraform; adding both
  would duplicate effort without covering a new surface. Checkov was kept because it's explicitly named in
  the guide and also supports scanning Dockerfiles, giving one tool two use cases.

## Trade-offs
- Hard-failing the build on any CRITICAL/HIGH finding (rather than warn-only) means a legitimate but
  currently-unfixable finding blocks merges until explicitly suppressed with a reasoned inline comment
  (`governance-spec.md` §3) — a deliberate friction to prevent silent accumulation of accepted risk.
- Running Trivy/Checkov via GitHub Actions marketplace actions ties the platform to those actions' maintained
  release cadence; version pins (`workflow-spec.md` R2) are the mitigation, with a scheduled bump process left
  as a platform-team maintenance task.

## Consequences
- Every PR touching `app/**`, `infrastructure/**`, or `.github/workflows/**` is gated by all three tools with
  no per-team opt-out, directly satisfying the capstone's "security and automation" evaluation criterion.
- Local and CI results come from the same tool versions/config, so "it passed on my machine" and "it failed
  in CI" should only diverge due to actual environment differences (e.g. stale local image cache), not
  different rule sets.

## Rationale
Gitleaks + Trivy + Checkov, wired into the same reusable workflows every application already inherits, gives
full secret/dependency/image/IaC coverage using only the guide's recommended, free, open-source tooling —
with zero additional opt-in burden on application teams.
