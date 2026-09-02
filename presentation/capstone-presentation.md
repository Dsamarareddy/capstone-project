---
marp: true
theme: default
paginate: true
size: 16:9
style: |
  section {
    font-size: 24px;
    font-family: "Segoe UI", Calibri, Arial, sans-serif;
    color: #1c2b39;
    background: #ffffff;
  }
  h1 { color: #0b3d66; font-size: 1.7em; margin-bottom: 0.1em; }
  h2 { color: #0b3d66; font-size: 1.3em; }
  code { font-size: 0.75em; background: #eef2f6; }
  table { font-size: 0.62em; border-collapse: collapse; width: 100%; }
  th { background: #0b3d66; color: #fff; padding: 6px 10px; text-align: left; }
  td { padding: 6px 10px; border-bottom: 1px solid #dbe3ea; vertical-align: top; }
  tr:nth-child(even) td { background: #f5f8fa; }
  .pill { display:inline-block; background:#0b3d66; color:#fff; border-radius:12px; padding:2px 12px; font-size:0.55em; letter-spacing:1px; }
  .pipeline { display:flex; align-items:stretch; gap:6px; margin-top: 14px; }
  .stage { flex:1; background:#eef4fa; border:2px solid #0b3d66; border-radius:8px; padding:10px 6px; text-align:center; font-size:0.62em; }
  .stage b { display:block; font-size:1.15em; color:#0b3d66; margin-bottom:4px; }
  .arrow { display:flex; align-items:center; font-size:1.3em; color:#0b3d66; }
  .fail { margin-top:14px; background:#fdeceb; border-left:5px solid #c0392b; padding:8px 14px; font-size:0.62em; }
  .arch { border:2px dashed #0b3d66; border-radius:10px; padding:14px; margin-top:10px; }
  .arch-row { display:flex; gap:10px; margin-bottom:10px; }
  .subnet { flex:1; border:2px solid #4a90c4; border-radius:8px; padding:8px; }
  .subnet.private { border-color:#c0392b; }
  .subnet-title { font-size:0.55em; font-weight:bold; color:#0b3d66; margin-bottom:6px; }
  .box { background:#eef4fa; border:1px solid #4a90c4; border-radius:6px; padding:6px 8px; font-size:0.55em; margin-bottom:6px; }
  .sidebox { flex:1; background:#fff8e6; border:1px solid #c79a2b; border-radius:8px; padding:8px; font-size:0.55em; }
  .result-ok { color: #1a7a3c; font-weight: bold; }
  .result-warn { color: #b8860b; font-weight: bold; }
  ul { font-size: 0.85em; }
  li { margin-bottom: 6px; }
---

<!-- Slide 1 -->
<div style="text-align:center; margin-top:20%;">

# Capstone Project
## Group – 1 (Advanced)

<span class="pill">AI-DRIVEN CLOUD &amp; DEVSECOPS</span>

<div style="margin-top:2em; font-size:0.8em; color:#4a5b6b;">
Acme Retail Ltd. — Inventory Management System (IMS)<br/>
Internal Developer Platform · Platform Engineer submission
</div>
</div>

---

## Problem Statement

Acme Retail Ltd. is modernizing its engineering organization. A new Inventory Management System (IMS) is
ready for deployment, but engineering processes are inconsistent, manual, and difficult to scale across
multiple application teams.

- **Duplicate pipelines** — *every team hand-rolls its own CI/CD, and it drifts over time*
- **Duplicate Terraform** — *infrastructure reinvented per application, no shared modules*
- **Different repository structures** — *no consistent layout for a new engineer to learn once*
- **Inconsistent AI specifications** — *AI-generated code ships with no standard spec to validate against*
- **Long onboarding** — *a new application team takes weeks to reach a working pipeline*
- **High maintenance** — *fixing one issue means fixing it N times, once per team*

---

## Our Solution — Spec-Driven, Automated, Secure

Build a reusable **Internal Developer Platform**: AI Engineering Specifications (structured `.md` documents
with requirements, design, and acceptance criteria) drive every generated artifact — Terraform, workflows,
the repo template, and governance — so a second team onboards by changing variables, not logic.

- **AI Engineering Specs** — *6 domains (platform, terraform, workflow, repo-template, governance, developer-experience), each with requirements & acceptance criteria*
- **Containerized app** — *IMS packaged as a secure, non-root Docker image with health-check readiness*
- **Terraform IaC** — *6 reusable modules compose the entire environment, eliminating duplicate infrastructure*
- **Reusable CI/CD pipeline** — *`workflow_call` architecture — app repos are thin callers, zero duplicated logic*
- **3 security tools** — *Gitleaks + Trivy + Checkov, zero tolerance, gating every pull request*
- **Automated testing** — *Jest + Supertest suite runs in CI — 8/8 passing*

---

## IMS CI/CD Pipeline
### Automated, Secure, Reusable Software Delivery

<div class="pipeline">
  <div class="stage"><b>AI Specs</b>Design</div>
  <div class="arrow">→</div>
  <div class="stage"><b>Lint</b>eslint</div>
  <div class="arrow">→</div>
  <div class="stage"><b>Test</b>jest</div>
  <div class="arrow">→</div>
  <div class="stage"><b>Security</b>3 tools</div>
  <div class="arrow">→</div>
  <div class="stage"><b>Build</b>Docker</div>
  <div class="arrow">→</div>
  <div class="stage"><b>Deploy</b>ECS Fargate</div>
  <div class="arrow">→</div>
  <div class="stage"><b>Smoke Test</b>curl /health</div>
</div>

<div class="fail">If any stage fails → pipeline stops → nothing reaches production</div>

Every stage above is a <code>workflow_call</code> to a **reusable** GitHub Actions workflow — the app-level
`ci.yml` only supplies inputs (app path, image name), never step logic.

---

## Architecture — AWS Deployment

<div class="arch">
  <div style="font-size:0.55em; font-weight:bold; color:#0b3d66; margin-bottom:8px;">VPC — 10.0.0.0/16 (module: networking)</div>
  <div class="arch-row">
    <div class="subnet">
      <div class="subnet-title">PUBLIC SUBNET</div>
      <div class="box">Application Load Balancer<br/>(HTTP :80, optional HTTPS :443)</div>
    </div>
    <div class="subnet private">
      <div class="subnet-title">PRIVATE SUBNET · dedicated security groups</div>
      <div class="box">ECS Fargate Service — IMS API<br/>(module: ecs-fargate-service)</div>
      <div class="box">RDS PostgreSQL<br/>Perf. Insights · Enhanced Monitoring<br/>(module: rds-postgres)</div>
    </div>
  </div>
  <div class="arch-row">
    <div class="sidebox">📦 <b>ECR</b><br/>Scan-on-push image registry</div>
    <div class="sidebox">🔐 <b>Secrets Manager</b><br/>Auto-generated DB credentials</div>
    <div class="sidebox">📊 <b>CloudWatch</b><br/>App logs + VPC Flow Logs</div>
    <div class="sidebox">🛡️ <b>IAM (iam-app-role)</b><br/>Least-privilege exec + task roles</div>
  </div>
</div>

A dev-cost-optimized, private-by-default architecture — encryption everywhere, least-privilege IAM, and zero
resources reachable except the ALB — all from the same six reusable Terraform modules. See ADR-0001.

---

## Security — Three Tools, Zero Tolerance

| LAYER | TOOL | WHAT IT SCANS | WHAT IT BLOCKS |
|---|---|---|---|
| 01 | **Gitleaks** | Full git history (all commits) | Passwords, AWS keys, API secrets, private keys, DB connection strings |
| 02 | **Trivy** | Built container image + app dependencies | CRITICAL/HIGH CVEs in OS packages and npm libraries |
| 03 | **Checkov** | All 6 Terraform modules | Misconfigured security groups, missing encryption, open ports, non-least-privilege IAM |

Security is not an afterthought — it's a mandatory pipeline gate (`reusable-security-scan.yml`,
`reusable-terraform.yml`). Code cannot reach production without passing all 3 tools.

---

## Validation — Real Results From This Build

Every artifact traces back to the spec it came from, and was actually run — not just written.

| ARTIFACT | FROM SPEC | VALIDATION METHOD | RESULT |
|---|---|---|---|
| Application Code (IMS) | `platform-spec.md` | Jest + Supertest (pg-mem, no live DB) | <span class="result-ok">✅ 8/8 tests passed</span> |
| Terraform Modules (×6) | `terraform-modules-spec.md` | Checkov static analysis, via Podman | <span class="result-ok">✅ 0 failed / 164 passed / 24 reasoned skips</span> (from 40 failed on the first real run) |
| Docker Image + Live Demo | `workflow-spec.md` | `podman build` + real container run | <span class="result-ok">✅ Built; full CRUD verified over real HTTP + real Postgres</span> |
| CI/CD Workflows | `workflow-spec.md` | `yaml.safe_load` parse, every workflow file | <span class="result-ok">✅ All 7 files parsed successfully</span> |
| Security Configs | `governance-spec.md` | Gitleaks + Checkov execution, via Podman | Gitleaks: <span class="result-ok">0 findings</span> · Checkov: <span class="result-ok">0 failed</span> · Trivy: <span class="result-warn">blocked by network TLS interception</span> (documented, not bypassed) |
| Repo Template | `repo-template-spec.md` | Structural review + TODO-marker audit | <span class="result-ok">✅ Fully generic, no IMS-specific naming</span> |
| Documentation | all 6 specs + `governance-spec.md` | Cross-link check, ADR rationale review | <span class="result-ok">✅ 6 specs + 4 ADRs authored, cross-linked</span> |

---

<div style="text-align:center; margin-top:25%;">

# Thank You

<div style="font-size:0.7em; font-style:italic; color:#4a5b6b; margin-top:1em;">
"From duplicate pipelines to a reusable platform — validated, not just written."
</div>

<div style="margin-top:2em; font-size:0.6em; color:#4a5b6b;">
group1-advanced · Inventory Management System · Internal Developer Platform
</div>
</div>
