# Platform Architecture

## Overview

The group1-advanced platform is a set of git-native reusable assets — not a hosted service — because no
shared cloud account or internal-developer-portal hosting exists for this capstone. Every application team
consumes the same modules, workflows, and template; only inputs differ.

```mermaid
flowchart TB
    subgraph Shared["Shared Platform Assets"]
        direction LR
        TFM["Terraform Modules\n(networking, ecr, iam-app-role,\nrds-postgres, s3-bucket,\necs-fargate-service)"]
        WF["Reusable GitHub Actions\n(reusable-ci, reusable-security-scan,\nreusable-terraform)"]
        TMPL["service-repo-template"]
        GOV["Governance\n(CODEOWNERS, PR template, SECURITY.md)"]
        DX["Dev-experience scripts\n(bootstrap, new-service,\nsecurity-scan, validate-terraform)"]
    end

    subgraph IMS["app/ims (this repo's reference app)"]
        IMSApp["Express + Postgres API"]
        IMSCI[".github/workflows/ci.yml"]
        IMSInfra["infrastructure/environments/dev"]
    end

    subgraph NewTeam["A new application team (onboards via the template)"]
        NewApp["Their app code"]
        NewCI[".github/workflows/ci.yml (copied)"]
        NewInfra["infrastructure/main.tf (copied)"]
    end

    IMSCI -->|workflow_call| WF
    NewCI -->|workflow_call, cross-repo ref| WF
    IMSInfra -->|module source, relative path| TFM
    NewInfra -->|module source, pinned git ref| TFM
    TMPL -.scaffolds.-> NewTeam
    GOV -.applies to.-> IMS
    GOV -.applies to.-> NewTeam
    DX -.self-service for.-> IMS
    DX -.self-service for.-> NewTeam
```

## Why this shape (not a hosted IDP portal)

A Backstage-style portal was considered and rejected for this capstone — see
`docs/engineering-decisions/ADR-0001-cloud-and-compute-choice.md` and
`ADR-0003-repo-template-and-onboarding.md` for the reasoning. In short: it would require a shared hosting
environment this capstone explicitly cannot assume exists, and it would not change the underlying mechanism
(reusable modules/workflows) that actually solves the stated business problems.

## Request flow for the reference application (IMS)

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant GH as GitHub Actions (ci.yml)
    participant ECR as ECR (module: ecr)
    participant ECS as ECS Fargate (module: ecs-fargate-service)
    participant ALB as ALB
    participant RDS as RDS Postgres (module: rds-postgres)
    participant Client as API Client

    Dev->>GH: push / PR
    GH->>GH: reusable-ci (lint, test, build image)
    GH->>GH: reusable-security-scan (Gitleaks, Trivy, Checkov)
    GH-->>ECR: (post-merge, manual step in this capstone) push image
    Client->>ALB: HTTPS request
    ALB->>ECS: forward to healthy task (target group health check: /health)
    ECS->>RDS: query via Secrets-Manager-injected credentials
    RDS-->>ECS: result set
    ECS-->>ALB: response
    ALB-->>Client: response
```

See `docs/architecture/ims-architecture.md` for the IMS-specific resource diagram.
