# Runs the same gates as CI, locally. From the repo root:
#   powershell -ExecutionPolicy Bypass -File tool/check.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$pureDartPackages = @(
  'pose_core',
  'exercise_library',
  'coach_engine',
  'plan_engine',
  'harness'
)

function Invoke-Step {
  param([string]$Name, [scriptblock]$Body)
  Write-Host ''
  Write-Host "== $Name" -ForegroundColor Cyan
  & $Body
  if ($LASTEXITCODE -ne 0) {
    Write-Host "FAILED: $Name" -ForegroundColor Red
    exit $LASTEXITCODE
  }
}

Invoke-Step 'Resolve workspace' { flutter pub get }

Invoke-Step 'Analyze' { flutter analyze }

foreach ($pkg in $pureDartPackages) {
  $testDir = Join-Path $root "packages\$pkg\test"
  if (Test-Path $testDir) {
    $hasTests = @(Get-ChildItem -Path $testDir -Filter '*_test.dart' -ErrorAction SilentlyContinue).Count -gt 0
  } else {
    $hasTests = $false
  }

  if ($hasTests) {
    Invoke-Step "dart test $pkg" {
      Push-Location "packages\$pkg"
      try { dart test } finally { Pop-Location }
    }
  } else {
    Write-Host "no tests yet in $pkg, skipping" -ForegroundColor DarkGray
  }
}

Invoke-Step 'flutter test app' {
  Push-Location 'app'
  try { flutter test } finally { Pop-Location }
}

Invoke-Step 'flutter test pose_camera' {
  Push-Location 'packages\pose_camera'
  try { flutter test } finally { Pop-Location }
}

Write-Host ''
Write-Host 'All checks passed.' -ForegroundColor Green
