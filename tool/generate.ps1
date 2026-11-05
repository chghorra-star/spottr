# Regenerates all code generation output. Run after changing the Drift schema
# or the ARB files, and commit the result — CI fails if it is stale.
#   powershell -ExecutionPolicy Bypass -File tool/generate.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host '== Localizations' -ForegroundColor Cyan
Push-Location 'app'
try {
  # gen-l10n must run inside the app package: from the workspace root it
  # reads the root pubspec, finds no `generate: true`, and does nothing.
  flutter gen-l10n
} finally {
  Pop-Location
}
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host '== Drift' -ForegroundColor Cyan
Push-Location 'app'
try {
  dart run build_runner build --delete-conflicting-outputs
} finally {
  Pop-Location
}
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host '== Drift schema snapshots' -ForegroundColor Cyan
Push-Location 'app'
try {
  # The snapshot of the *current* schemaVersion, plus the helpers that let a
  # test start a database at an older one. A bumped schemaVersion with no
  # snapshot leaves the migration untested, which is the one piece of code
  # here that only ever runs on somebody else's phone.
  dart run drift_dev schema dump lib/data/local/database.dart drift_schemas/
  if ($LASTEXITCODE -ne 0) { Pop-Location; exit $LASTEXITCODE }
  dart run drift_dev schema generate drift_schemas/ test/data/generated_migrations/
} finally {
  Pop-Location
}
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ''
Write-Host 'Generated code is up to date.' -ForegroundColor Green
