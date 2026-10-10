#Requires -Version 5.1
<#
.SYNOPSIS
    Scaffolds a new service repository from templates/service-repo-template.
.DESCRIPTION
    Thin wrapper kept for backwards compatibility; the logic lives in scripts/idp.py.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Name,
    [string]$OutputPath
)

& (Join-Path $PSScriptRoot 'idp.ps1') new-service $Name @(if ($OutputPath) { '--output', $OutputPath })
exit $LASTEXITCODE
