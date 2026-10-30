# Regenerates all code generation output. Run after changing the Drift schema
# or the ARB files, and commit the result — CI fails if it is stale.
#   powershell -ExecutionPolicy Bypass -File tool/generate.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host '== Localizations' -ForegroundColor Cyan
flutter gen-l10n --project-dir app
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host '== Drift' -ForegroundColor Cyan
Push-Location 'app'
try {
  dart run build_runner build --delete-conflicting-outputs
} finally {
  Pop-Location
}
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ''
Write-Host 'Generated code is up to date.' -ForegroundColor Green
