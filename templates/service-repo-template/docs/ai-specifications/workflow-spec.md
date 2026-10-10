# AI Engineering Specification: CI/CD Workflows — TODO-service-name

<!-- TODO(new-service): fill in every section for this service. Platform reference:
     docs/ai-specifications/workflow-spec.md in the group1-advanced platform repo. Keep the 12 section headings
     so specs stay consistent across every service. Consume the platform reusable workflows as-is; document only the inputs this service passes. -->

| Field | Value |
|---|---|
| Spec ID | WF |
| Status | TODO(new-service): Draft / Accepted |
| Owner | TODO(new-service): owning team handle |
| Last updated | TODO(new-service): YYYY-MM-DD |
| Related specs | [platform-spec.md](platform-spec.md) · [terraform-modules-spec.md](terraform-modules-spec.md) · [workflow-spec.md](workflow-spec.md) · [repo-template-spec.md](repo-template-spec.md) · [governance-spec.md](governance-spec.md) · [developer-experience-spec.md](developer-experience-spec.md) |

## 1. Purpose & Scope
TODO(new-service): what this spec covers for this service, and what it does not.

## 2. Business problem addressed
TODO(new-service): which platform business problems (duplicate pipelines, duplicate Terraform, different repo
structures, inconsistent AI specs, long onboarding, high maintenance) and which service problem this addresses.

## 3. Context / current state
TODO(new-service): the caller workflows in .github/workflows/ and the reusable workflows they call.

## 4. Requirements
| ID | Level | Requirement |
|---|---|---|
| WF-R1 | MUST | TODO(new-service) |

## 5. Interfaces / contracts
TODO(new-service): the with: inputs passed in ci.yml (app_dir, python_version, image_name, terraform_dir) and terraform.yml (working_dir). Tables MUST match the code exactly.

## 6. Design details
TODO(new-service): key design decisions; add a Mermaid diagram where helpful.

## 7. Security considerations
TODO(new-service): data sensitivity, secrets, IAM, network exposure specific to this service.

## 8. Non-functional requirements
TODO(new-service): performance, availability, cost, observability targets.

## 9. Acceptance criteria / validation
TODO(new-service): concrete commands and their latest results, e.g. `python scripts/idp.py ci --app <path-to-this-app>`.

## 10. Out of scope / future work
TODO(new-service)

## 11. Instructions for AI coding agents
TODO(new-service): how an agent should use this spec, files it may touch, guardrails (never weaken platform
security gates, never edit shared module `source` lines or add steps to caller workflows).

## 12. Change log
| Date | Change |
|---|---|
| TODO(new-service) | Scaffolded from the platform repo template. |
