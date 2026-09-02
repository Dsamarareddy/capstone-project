# Security Policy

## Scope

This policy covers the group1-advanced Internal Developer Platform: the reference application (`app/ims`),
the shared Terraform modules (`infrastructure/modules`), the reusable GitHub Actions workflows
(`.github/workflows`), and the service repository template (`templates/service-repo-template`).

## Automated Security Gates

Every pull request touching `app/**`, `infrastructure/**`, or `.github/workflows/**` is automatically gated
by `reusable-security-scan.yml`:

| Check | Tool | Fails the build on |
|---|---|---|
| Secret scanning | Gitleaks | Any detected secret in the diff |
| Dependency vulnerabilities | Trivy (filesystem mode) | CRITICAL/HIGH CVEs in `app/ims` dependencies |
| Container image vulnerabilities | Trivy (image mode) | CRITICAL/HIGH CVEs in the built image |
| Infrastructure misconfiguration | Checkov | HIGH/CRITICAL Terraform misconfigurations |

Run the same checks locally before opening a PR with `./scripts/security-scan.ps1`.

## Reporting a Vulnerability

If you discover a security issue in this platform (a vulnerability in the IMS application, a Terraform
module misconfiguration, or a workflow that could leak secrets):

1. Do not open a public GitHub issue describing the vulnerability.
2. Contact the platform-team owners listed in `.github/CODEOWNERS` directly.
3. Include: affected component, reproduction steps, and potential impact.

We aim to acknowledge reports within 3 business days.

## Supported Versions

This is a capstone/reference platform; only the `main` branch is supported. Terraform modules and reusable
workflows are versioned by git tag (see `docs/ai-specifications/governance-spec.md` §6) — only the latest
tagged version of each receives security fixes.
