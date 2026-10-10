# Architecture Documentation

Architecture documentation for the **Acme Retail Ltd. Internal Developer Platform (IDP)**, the `group1-advanced`
repository. It started from a one-off Inventory Management System (IMS) and turned what the IMS needed into
reusable platform capabilities: reusable GitHub Actions workflows, Terraform modules for AWS, a service repository
template, governance files, and a self-service CLI (`scripts/idp.py`).

All diagrams are Mermaid and render natively on GitHub.

| Document | What it covers |
|---|---|
| [platform-architecture.md](platform-architecture.md) | The IDP as a whole: platform assets, how a team onboards with `idp new-service`, how several teams reuse the same modules and workflows, and how versions are managed. |
| [ims-architecture.md](ims-architecture.md) | The IMS reference application: Flask components, data model (ER diagram), checkout flow, local runtime, and API summary. |
| [cicd-pipeline.md](cicd-pipeline.md) | The CI/CD pipeline: caller workflows, `reusable-ci.yml`, `reusable-security-scan.yml`, `reusable-terraform.yml`, the gates they enforce, and the matching local `idp` commands. |
| [aws-deployment-architecture.md](aws-deployment-architecture.md) | The AWS target defined in `infrastructure/`: VPC, ALB, ECS Fargate, ECR, RDS, Secrets Manager, IAM, CloudWatch; traffic flow and how modules map to resources. |
| [security-architecture.md](security-architecture.md) | DevSecOps controls in layers, from the developer machine through PR, CI, image, infrastructure and runtime, with a threat-to-control table. |

Related material:

- `docs/ai-specifications/`: the specs the platform was built from.
- `docs/engineering-decisions/`: ADRs (cloud/compute choice, reusable workflow strategy, repo template, security tooling).
- `SECURITY.md`, `.github/CODEOWNERS`, `.github/PULL_REQUEST_TEMPLATE.md`: governance.
