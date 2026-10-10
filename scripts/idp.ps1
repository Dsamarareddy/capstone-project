#Requires -Version 5.1
<#
.SYNOPSIS
    Windows wrapper for the self-service platform CLI (scripts/idp.py).
.EXAMPLE
    ./scripts/idp.ps1 new-service billing-service
    ./scripts/idp.ps1 ci --skip-containers
#>
$python = if (Get-Command python -ErrorAction SilentlyContinue) { 'python' } elseif (Get-Command py -ErrorAction SilentlyContinue) { 'py' } else { throw 'Python 3.10+ is required on PATH.' }
& $python (Join-Path $PSScriptRoot 'idp.py') @args
exit $LASTEXITCODE
