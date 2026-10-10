#Requires -Version 5.1
<#
.SYNOPSIS
    Runs Gitleaks, Trivy and Checkov locally via containers (same gates as CI).
.DESCRIPTION
    Thin wrapper kept for backwards compatibility; the logic lives in scripts/idp.py.
#>
[CmdletBinding()]
param(
    [string]$AppDir = 'app/ims',
    [string]$TerraformDir = 'infrastructure'
)

& (Join-Path $PSScriptRoot 'idp.ps1') scan --app $AppDir --terraform-dir $TerraformDir
exit $LASTEXITCODE
