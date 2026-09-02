#Requires -Version 5.1
<#
.SYNOPSIS
    One-command local dev setup for the IMS reference application.
.DESCRIPTION
    Installs app/ims npm dependencies and seeds a local .env file if one doesn't already exist.
    Does not require Docker/Terraform to complete - those are only needed for the live demo / infra steps.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$appDir = Join-Path $repoRoot 'app\ims'

if (-not (Test-Path $appDir)) {
    throw "Expected app directory not found: $appDir"
}

Write-Host "==> Installing app/ims dependencies" -ForegroundColor Cyan
Push-Location $appDir
try {
    npm install
    if ($LASTEXITCODE -ne 0) { throw "npm install failed with exit code $LASTEXITCODE" }
} finally {
    Pop-Location
}

$envFile = Join-Path $appDir '.env'
$envExample = Join-Path $appDir '.env.example'
if (-not (Test-Path $envFile)) {
    Write-Host "==> Seeding app/ims/.env from .env.example" -ForegroundColor Cyan
    Copy-Item $envExample $envFile
} else {
    Write-Host "==> app/ims/.env already exists, leaving it untouched" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Bootstrap complete. Next steps:" -ForegroundColor Green
Write-Host "  1. docker compose -f app/ims/docker-compose.yml up --build   (or: podman compose ...)"
Write-Host "  2. curl http://localhost:3000/health"
Write-Host "  3. ./scripts/security-scan.ps1"
Write-Host "  4. ./scripts/validate-terraform.ps1"
