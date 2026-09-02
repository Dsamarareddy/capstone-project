# group1-advanced — AI-Driven Cloud & DevSecOps Internal Developer Platform

Capstone submission for Acme Retail Ltd.'s AI-Driven Cloud & DevSecOps Modernization Program.

**Role:** Platform Engineer
**Mission:** Turn the one-off engineering built for the Inventory Management System (IMS) into a reusable
Internal Developer Platform (IDP) — shared Terraform modules, reusable GitHub Actions workflows, a repo
template, governance standards, and developer-experience tooling — so any application team can onboard with
minimal customization.

> This README is a placeholder overview updated incrementally as each part of the platform is built.
> The final version (with full run instructions, architecture summary, and demo script) lands at the end of
> the build — see `docs/engineering-decisions/` for the ADRs explaining every major choice made along the way.

## Repository structure

```
README.md
app/ims/                       Sample application: Inventory Management System (Node.js/Express + Postgres)
infrastructure/modules/        Reusable Terraform modules (networking, ecr, ecs-fargate-service, rds-postgres, s3-bucket, iam-app-role)
infrastructure/environments/   Environment compositions that consume the shared modules (dev/ = IMS)
templates/service-repo-template/  Starter repo a new application team copies to onboard onto the platform
.github/workflows/             Reusable + caller GitHub Actions workflows (CI, security scanning, Terraform)
scripts/                       Developer-experience tooling (bootstrap, scaffold new service, security scan, terraform validate)
docs/ai-specifications/        The 6 required AI Engineering Specifications (primary artifact of this capstone)
docs/architecture/             Platform and IMS architecture diagrams (Mermaid)
docs/engineering-decisions/    Architecture Decision Records (ADR format)
presentation/                  Capstone presentation deck (Marp source + exported PPTX/PDF)
SECURITY.md                    Vulnerability reporting / security policy
```

## Status

Build in progress — tracked against the plan at `docs/engineering-decisions/` and the AI specs in
`docs/ai-specifications/`. Each part is committed incrementally.
