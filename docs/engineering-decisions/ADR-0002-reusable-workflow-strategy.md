# ADR-0002: Reusable Workflow Strategy

## Context
"Duplicate pipelines" is listed as a top business problem. Every application team currently maintains its own
CI/CD YAML with copy-pasted lint/test/build/scan logic that drifts over time.

## Problem
How should CI/CD logic be shared across application repositories using only GitHub Actions (the guide's
stated CI/CD tool) — no third-party CI product, no custom-built orchestrator?

## Decision
Use GitHub Actions' native `on: workflow_call` reusable workflows. All actual logic lives in
`reusable-ci.yml`, `reusable-security-scan.yml`, and `reusable-terraform.yml`. Every application-level
workflow (`ci.yml`, `terraform.yml`, and the copies inside `templates/service-repo-template`) is a thin
caller: triggers + `uses:` + `with:` inputs only, never inline steps.

## Alternatives Considered
- **Composite actions** (`uses: ./.github/actions/foo`): reusable at the *step* level, not the *job* level;
  would still require each app repo to assemble its own job/permissions/matrix structure, leaving room for
  drift. Reusable workflows were chosen because they reuse the whole job graph, not just steps.
- **Copy-paste with a linter to catch drift**: rejected outright — this is the exact problem being solved,
  not a mitigation of it.
- **A separate orchestration tool (e.g. a custom GitHub App, Backstage software templates with a CI plugin)**:
  more powerful but requires infrastructure to host, which the capstone doesn't provide; native GitHub
  Actions reusable workflows require zero additional hosting.

## Trade-offs
- Cross-repository reuse (a real second application repo calling `reusable-ci.yml` from this platform repo)
  requires either a public repo or the caller repo having access via `permissions` — documented as a
  `TODO(platform-owner)` in the template's workflow files, since this capstone's onboarding demo happens
  inside one monorepo-style submission rather than truly separate repositories.
- Debugging a failing reusable workflow requires jumping into the platform repo's Actions logs, not just the
  calling repo's — mitigated by uploading SARIF/artifact outputs the caller repo's UI still surfaces.

## Consequences
- Fixing a bug in, e.g., the Trivy scan step is a one-line change in `reusable-security-scan.yml` that every
  consuming application picks up on its next run — no per-repo backport needed.
- Onboarding a new application's CI/CD is limited to editing `with:` inputs (see
  `repo-template-spec.md` §5 "Minimal Customization Checklist").

## Rationale
Reusable workflows are the GitHub-native mechanism that most directly maps to "one place per capability,
consumed by reference" (`platform-spec.md` R1) without introducing any tooling beyond what the guide already
lists (GitHub Actions).
