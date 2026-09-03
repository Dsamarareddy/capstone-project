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

## Addendum: Real Local Run Results (this build session)

`./scripts/security-scan.ps1` was actually executed against this repository via Podman, not just written:

- **Gitleaks**: clean, 0 findings (`security-reports/gitleaks-report.json`).
- **Checkov**: the first real run found 40 failed checks across the six Terraform modules. Each was triaged
  individually rather than blanket-suppressed:
  - **Fixed for real** (~20 checks): a genuinely dead/unused security group was deleted (it was orphaned by
    the `ecs-fargate-service`/`rds-postgres` security-group redesign — Checkov's "SG attached to another
    resource" check caught a real bug, not just a style issue); the VPC's default security group is now
    locked to no rules; VPC Flow Logs, RDS Enhanced Monitoring, Performance Insights, DDL query logging,
    `rds.force_ssl`, KMS encryption on ECR/S3, an S3 lifecycle rule, auto minor-version upgrades, and
    `drop_invalid_header_fields` on the ALB were all added.
  - **Explicitly deferred** (24 checks, each with an inline `#checkov:skip=<ID>:<reason>` comment in the
    relevant module's `main.tf`): Multi-AZ, deletion protection, IAM database auth, secret rotation/CMK,
    enhanced-monitoring cost trade-offs the module already makes configurable via variables, and everything
    that depends on an ACM certificate/owned domain this capstone's local/dev environment doesn't have
    (HTTPS listener, WAF, cross-region replication). Every skip explains *why*, per `governance-spec.md` §3's
    requirement that suppressions be reasoned, not silent.
  - **Result after fixes**: 0 failed / 164 passed / 24 reasoned skips.
- **Trivy**: failed to run against this repo's own local Podman initially — its vulnerability-database
  download hit `x509: certificate signed by unknown authority` against `mirror.gcr.io`, indicating this
  machine sits behind a TLS-intercepting network (a corporate proxy/firewall whose root CA isn't trusted
  inside the container). GitHub-hosted runners don't sit behind that proxy, so `reusable-security-scan.yml`
  ran there for real once this repo was pushed to GitHub, and found two rounds of genuine findings, both
  fixed:
  - **Filesystem scan**: `qs@6.15.3` (pulled in transitively via `express` → `body-parser`), vulnerable to
    GHSA-x5fp-wj9c-mxmx and GHSA-4mjr-xmp4-gh2g. A plain `npm audit fix` couldn't reach it without a major
    Express bump, so fixed via an npm `overrides` entry pinning `qs@6.16.0`. `npm audit`: 0 vulnerabilities;
    all 8 Jest tests still pass.
  - **Image scan**: 13 CRITICAL/HIGH findings — npm's own bundled dependencies (`tar`, `minimatch`, `glob`,
    `cross-spawn`, `pacote`, `sigstore`) inside the stale `node:20.17.0-bookworm-slim` base image, plus
    Debian OS packages (`perl-base`, `zlib1g`, `util-linux`, `ncurses`), several marked `will_not_fix` /
    `affected` by Debian itself with no patch available at all. Fixed by (1) deleting npm/npx/corepack from
    the final runtime stage — it only ever runs `node`, never `npm`, so this eliminates that CVE source
    entirely rather than chasing it per base-image bump — and (2) switching the base image to
    `node:20.20.2-alpine` (the app has zero native dependencies, verified with a real `podman build` + run +
    live `/health` check against Postgres), which drops the whole Debian package set those CVEs lived in,
    plus an `apk upgrade` at build time to pick up an OpenSSL patch newer than the base image's pinned
    snapshot. Re-scanned locally (using Trivy's `--insecure` flag as a one-off diagnostic workaround for this
    network's TLS interception, not a permanent CI change): **0 CRITICAL/HIGH findings**, down from 13.
