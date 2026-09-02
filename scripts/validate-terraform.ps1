#Requires -Version 5.1
<#
.SYNOPSIS
    Runs terraform fmt/init/validate across every shared module and environment - the same
    checks reusable-terraform.yml runs in CI - so issues are caught before pushing.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    throw "terraform was not found on PATH. Install Terraform (https://developer.hashicorp.com/terraform/install) and re-run this script."
}

Write-Host "==> terraform fmt -check -recursive (whole infrastructure/ tree)" -ForegroundColor Cyan
Push-Location (Join-Path $repoRoot 'infrastructure')
try {
    terraform fmt -check -recursive
    if ($LASTEXITCODE -ne 0) {
        throw "terraform fmt found formatting issues. Run 'terraform fmt -recursive' inside infrastructure/ to fix, then re-run this script."
    }
} finally {
    Pop-Location
}

$targets = @(
    'infrastructure\modules\networking',
    'infrastructure\modules\ecr',
    'infrastructure\modules\iam-app-role',
    'infrastructure\modules\rds-postgres',
    'infrastructure\modules\s3-bucket',
    'infrastructure\modules\ecs-fargate-service',
    'infrastructure\environments\dev'
)

$failed = @()

foreach ($target in $targets) {
    $dir = Join-Path $repoRoot $target
    Write-Host ""
    Write-Host "==> Validating $target" -ForegroundColor Cyan
    Push-Location $dir
    try {
        terraform init -backend=false -input=false | Out-Null
        if ($LASTEXITCODE -ne 0) { $failed += "$target (init)"; continue }

        terraform validate
        if ($LASTEXITCODE -ne 0) { $failed += "$target (validate)"; continue }
    } finally {
        Pop-Location
    }
}

Write-Host ""
if ($failed.Count -eq 0) {
    Write-Host "All modules and environments passed terraform validate." -ForegroundColor Green
    exit 0
} else {
    Write-Host "Failed: $($failed -join ', ')" -ForegroundColor Red
    exit 1
}
