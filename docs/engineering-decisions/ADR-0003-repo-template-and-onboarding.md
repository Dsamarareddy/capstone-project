# ADR-0003: Repository Template and Onboarding Model

## Context
"Different repository structures" and "long onboarding" are named business problems. New application teams
today invent their own layout, discover CI/CD and Terraform conventions by trial and error, and take a long
time to reach their first green pipeline.

## Problem
How does a new team get a consistent repository structure and a working baseline (CI green, security scan
green, infra plan-able) with minimal effort, without the platform team hosting a portal service?

## Decision
Ship a copyable directory, `templates/service-repo-template/`, plus a scaffolding script
(`scripts/new-service.ps1`) that copies it and substitutes the service name. The template is not a live
service (no Backstage/portal); it's a git-native starting point. `docs/ai-specifications/repo-template-spec.md`
defines exactly what must and must not be customized during onboarding.

## Alternatives Considered
- **Backstage software templates**: the industry-standard answer to this problem, but requires a hosted
  Backstage instance, a software catalog, and a scaffolder backend — infrastructure this capstone explicitly
  cannot assume exists ("cloud infrastructure may not be provided"). Rejected for this submission's scope,
  though `platform-spec.md` §3 notes it as an explicit non-goal rather than an oversight.
- **`degit`/`cookiecutter`-style external templating tool**: adds a dependency not in the guide's recommended
  stack; a PowerShell script using the tools already present (Node.js, filesystem copy) was preferred for
  zero additional install burden matching the "Provided/Recommended Tools" list.
- **A GitHub "template repository" (native GitHub feature)**: viable once this platform actually lives on
  GitHub as its own repo — noted as the natural next step once `<org>/group1-advanced` exists (see the
  `TODO(platform-owner)` markers in the template's workflow files), but doesn't work standalone inside a
  single capstone submission repo.

## Trade-offs
- The template's Terraform module `source` lines use a placehoder `git::https://github.com/<org>/...` URL
  since no real GitHub org/repo exists yet for this capstone — a real onboarding would need that filled in
  and a `modules/v1.0.0` tag cut, both called out as `TODO(platform-owner)` items.
- `new-service.ps1` does simple text substitution rather than a templating engine (Handlebars/Jinja) —
  sufficient for the one placeholder (`TODO-service-name`) this template currently has; would need
  revisiting if the template grows more variable substitution points.

## Consequences
- A new team can go from `./scripts/new-service.ps1 -Name X` to a running `/health` endpoint in under a
  minute, and to "fully wired CI/CD + Terraform" by only editing variables/inputs — validated by this ADR's
  acceptance criterion in `repo-template-spec.md` §6.

## Rationale
A copyable template plus a small scaffolding script solves the stated problems (repo structure consistency,
onboarding speed) with tooling already present, deferring the heavier "hosted developer portal" investment to
a future iteration once the platform has a real GitHub home and more than one real consuming team.
