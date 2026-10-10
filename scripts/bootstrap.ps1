#Requires -Version 5.1
<#
.SYNOPSIS
    One-command local dev setup for the IMS reference application.
.DESCRIPTION
    Creates app/ims/.venv, installs Python dependencies and seeds a local .env file if one doesn't
    already exist. Thin wrapper around `scripts/idp.py bootstrap`.
#>
[CmdletBinding()]
param([string]$App = 'app/ims')

& (Join-Path $PSScriptRoot 'idp.ps1') bootstrap --app $App
exit $LASTEXITCODE
