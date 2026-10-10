#Requires -Version 5.1
<#
.SYNOPSIS
    Runs terraform fmt/init/validate across every shared module and environment.
.DESCRIPTION
    Thin wrapper kept for backwards compatibility; the logic lives in scripts/idp.py.
#>
[CmdletBinding()]
param()

& (Join-Path $PSScriptRoot 'idp.ps1') tf-validate
exit $LASTEXITCODE
