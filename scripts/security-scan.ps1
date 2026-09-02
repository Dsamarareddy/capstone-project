#Requires -Version 5.1
<#
.SYNOPSIS
    Runs the same Gitleaks / Trivy / Checkov gates locally that CI runs (reusable-security-scan.yml),
    via container images - no local tool installs required beyond a container runtime.
.DESCRIPTION
    Auto-detects `podman` or `docker` on PATH and uses whichever is found (podman first).
    Writes SARIF/JSON reports to security-reports/ (gitignored).
#>
[CmdletBinding()]
param(
    [string]$AppDir = 'app/ims',
    [string]$TerraformDir = 'infrastructure'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$runtime = $null
foreach ($candidate in @('podman', 'docker')) {
    if (Get-Command $candidate -ErrorAction SilentlyContinue) {
        $runtime = $candidate
        break
    }
}

if (-not $runtime) {
    throw "Neither podman nor docker was found on PATH. Install one of them to run local security scans (CI runs these regardless via GitHub-hosted runners)."
}

Write-Host "==> Using container runtime: $runtime" -ForegroundColor Cyan

$reportsDir = Join-Path $repoRoot 'security-reports'
New-Item -ItemType Directory -Force -Path $reportsDir | Out-Null

$exitCode = 0

Write-Host "==> Gitleaks: scanning full repository for secrets" -ForegroundColor Cyan
& $runtime run --rm -v "${repoRoot}:/repo" zricethezav/gitleaks:latest detect --source=/repo --report-path=/repo/security-reports/gitleaks-report.json --redact
if ($LASTEXITCODE -ne 0) { Write-Warning "Gitleaks found potential secrets - see security-reports/gitleaks-report.json"; $exitCode = 1 }

Write-Host "==> Trivy: scanning $AppDir for dependency vulnerabilities" -ForegroundColor Cyan
& $runtime run --rm -v "${repoRoot}:/repo" aquasec/trivy:latest fs --severity CRITICAL,HIGH --exit-code 1 --format json --output /repo/security-reports/trivy-fs-report.json "/repo/$AppDir"
if ($LASTEXITCODE -ne 0) { Write-Warning "Trivy found CRITICAL/HIGH dependency vulnerabilities - see security-reports/trivy-fs-report.json"; $exitCode = 1 }

Write-Host "==> Checkov: scanning $TerraformDir for misconfigurations" -ForegroundColor Cyan
& $runtime run --rm -v "${repoRoot}:/repo" bridgecrew/checkov:latest -d "/repo/$TerraformDir" --compact --output json --output-file-path /repo/security-reports/checkov-report.json
if ($LASTEXITCODE -ne 0) { Write-Warning "Checkov found HIGH/CRITICAL misconfigurations - see security-reports/checkov-report.json"; $exitCode = 1 }

Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "All local security gates passed. Reports written to security-reports/." -ForegroundColor Green
} else {
    Write-Host "One or more security gates reported findings. Review security-reports/ before opening a PR." -ForegroundColor Red
}
exit $exitCode
