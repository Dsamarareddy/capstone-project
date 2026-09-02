#Requires -Version 5.1
<#
.SYNOPSIS
    Scaffolds a new application repository from templates/service-repo-template.
.DESCRIPTION
    Copies the repo template to a new directory and substitutes the service name into
    package.json, Terraform variable defaults, and workflow inputs. Refuses to overwrite
    an existing target directory (safe by default).
.PARAMETER Name
    Name of the new service (kebab-case recommended, e.g. billing-service).
.PARAMETER OutputPath
    Where to create the new service directory. Defaults to a sibling directory of this repo.
.EXAMPLE
    ./scripts/new-service.ps1 -Name billing-service
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$templateDir = Join-Path $repoRoot 'templates\service-repo-template'

if (-not (Test-Path $templateDir)) {
    throw "Template directory not found: $templateDir"
}

if (-not $OutputPath) {
    $OutputPath = Join-Path (Split-Path -Parent $repoRoot) $Name
}

if (Test-Path $OutputPath) {
    throw "Target directory already exists, refusing to overwrite: $OutputPath"
}

Write-Host "==> Copying template to $OutputPath" -ForegroundColor Cyan
Copy-Item -Path $templateDir -Destination $OutputPath -Recurse -Force

Write-Host "==> Substituting service name 'TODO-service-name' -> '$Name'" -ForegroundColor Cyan
$textExtensions = @('.json', '.tf', '.js', '.yml', '.yaml', '.md')
$files = Get-ChildItem -Path $OutputPath -Recurse -File | Where-Object { $textExtensions -contains $_.Extension }

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    if ($content -match 'TODO-service-name') {
        $updated = $content -replace 'TODO-service-name', $Name
        Set-Content -Path $file.FullName -Value $updated -NoNewline
        Write-Host "    updated: $($file.FullName.Substring($OutputPath.Length + 1))"
    }
}

Write-Host ""
Write-Host "Service '$Name' scaffolded at $OutputPath" -ForegroundColor Green
Write-Host "Remaining manual steps (all marked with TODO(new-service) / TODO(platform-owner) comments):"
Write-Host "  1. Replace app/ with your real application code."
Write-Host "  2. Set the platform repo path/ref in infrastructure/main.tf and .github/workflows/*.yml."
Write-Host "  3. Fill in docs/ai-specifications/*.md for this service."
