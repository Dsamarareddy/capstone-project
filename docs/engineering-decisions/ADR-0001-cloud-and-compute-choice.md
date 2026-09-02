# ADR-0001: Cloud Provider and Compute Choice

## Context
The platform needs one concrete, opinionated compute target so shared Terraform modules can be real and
useful rather than abstract. The capstone guide prefers AWS and states no shared cloud account/hosting
platform exists — the solution must be locally reproducible.

## Problem
Which cloud provider and compute model should the shared `ecs-fargate-service` module (and the platform in
general) target, given the constraint that validation must happen without a live cloud account?

## Decision
Target AWS, using ECS Fargate (not EKS/Kubernetes, not Lambda) for the reference application's compute, and
validate all Terraform locally via `fmt`/`validate`/Checkov rather than `apply`. A single NAT gateway (not
one per AZ) is used in the `networking` module to keep the reference dev environment's *design* realistic
without over-provisioning cost that would never actually be paid in this capstone.

## Alternatives Considered
- **EKS (Kubernetes)**: More powerful and closer to what "Kubernetes (Kind, Minikube, K3d)" in the guide's
  tooling list hints at, but adds substantial operational surface (cluster add-ons, IAM-for-service-accounts,
  ingress controllers) that doesn't change the core lesson (reusable modules/workflows) and would take
  disproportionate effort to validate locally.
- **AWS Lambda (serverless)**: Easier to validate locally via LocalStack, and cheaper, but doesn't match the
  guide's Docker-first tooling list (Docker is explicitly called out; a container-based compute model is a
  more natural match) and IMS's always-on CRUD workload doesn't need Lambda's scale-to-zero benefit.
- **Azure**: Explicitly allowed as an alternative by the guide, but AWS is the guide's stated preference and
  the team's assumed familiarity target.

## Trade-offs
- ECS Fargate is simpler to operate than EKS but is AWS-specific (no portability to Azure/GCP without
  rewriting the module) — acceptable since multi-cloud portability was explicitly out of scope
  (`platform-spec.md` §3).
- Not running `terraform apply` in CI means a real deployment has never been exercised end-to-end by this
  capstone; the mitigation is that `terraform validate` + Checkov catch syntax/logic/security-posture errors,
  and the module interfaces were designed to be `apply`-ready.
- Single NAT gateway is a single point of failure for private-subnet egress; acceptable for `dev`, called out
  explicitly as a `prod` follow-up in the `networking` module's README.

## Consequences
- New application teams onboarding via the template get a working ECS Fargate deployment shape by default;
  teams needing serverless or Kubernetes must diverge from the template (documented as an explicit exception
  in their own `repo-template-spec.md` stub, per `repo-template-spec.md` §4 R4 TODO markers).
- The live demo for this capstone runs via `docker compose`/`podman compose`, not a real ECS deployment —
  documented clearly in the root README so evaluators don't expect a live AWS URL.

## Rationale
AWS ECS Fargate is the smallest compute model that still exercises every category of shared infrastructure
concern (networking, IAM, secrets, load balancing, container registry, logging) that a real application team
would need, while staying validate-only friendly for this capstone's no-cloud-account constraint.
