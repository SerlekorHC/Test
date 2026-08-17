$ErrorActionPreference = 'Stop'

param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [string]$ExpectedSha256 = '55ea8cb52ac16e62f436e37f9fdb4e978d7b9f75814a9d42e8b69d05e3b496ad'
)

if (-not (Test-Path -Path $Path)) {
    throw "ISO not found: $Path"
}

$actual = (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Host "Actual:   $actual"
Write-Host "Expected: $ExpectedSha256"

if ($actual -eq $ExpectedSha256.ToLowerInvariant()) {
    Write-Host "Checksum matches. The ISO is valid."
    exit 0
}

Write-Host "Checksum mismatch. The ISO is not valid for this install path." -ForegroundColor Red
exit 1
