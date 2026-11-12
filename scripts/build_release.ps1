# build_release.ps1 — Build release AAB (for Play Store) and APK (for WhatsApp/testing)
param (
    [switch]$SkipTests
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   Spotnook Release Build Pipeline" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. Read current version from pubspec.yaml
$pubspec = Get-Content (Join-Path $projectRoot "pubspec.yaml") -Raw
if ($pubspec -match 'version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)') {
    $versionName = $matches[1]
    $versionCode = $matches[2]
    Write-Host "[1/5] Target Version: $versionName (Version Code: $versionCode)" -ForegroundColor Green
} else {
    Write-Error "Could not parse version from pubspec.yaml"
    exit 1
}

# 2. Run unit & widget tests unless skipped
if (-not $SkipTests) {
    Write-Host "[2/5] Running tests (flutter test)..." -ForegroundColor Yellow
    & flutter test
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Tests failed! Fix tests before building a release."
        exit $LASTEXITCODE
    }
    Write-Host "      All tests passed successfully!" -ForegroundColor Green
} else {
    Write-Host "[2/5] Skipping tests as requested (-SkipTests)" -ForegroundColor Gray
}

# 3. Build release AAB using Gradle bundleRelease (uses upload-keystore.jks)
Write-Host "[3/5] Building release App Bundle (.aab)..." -ForegroundColor Yellow
$gradlew = Join-Path $projectRoot "android\gradlew.bat"
& $gradlew -p (Join-Path $projectRoot "android") bundleRelease --console=plain
if ($LASTEXITCODE -ne 0) {
    Write-Error "Gradle bundleRelease failed!"
    exit $LASTEXITCODE
}

# 4. Build release APK for direct testing / WhatsApp
Write-Host "[4/5] Building release APK (.apk)..." -ForegroundColor Yellow
& flutter build apk --release
if ($LASTEXITCODE -ne 0) {
    Write-Error "flutter build apk --release failed!"
    exit $LASTEXITCODE
}

# 5. Copy artifacts to store_assets directory
Write-Host "[5/5] Packaging artifacts into store_assets/..." -ForegroundColor Yellow
$storeAssets = Join-Path $projectRoot "store_assets"
if (-not (Test-Path $storeAssets)) {
    New-Item -ItemType Directory -Path $storeAssets | Out-Null
}

$aabSource = Join-Path $projectRoot "build\app\outputs\bundle\release\app-release.aab"
$apkSource = Join-Path $projectRoot "build\app\outputs\flutter-apk\app-release.apk"

$aabDest = Join-Path $storeAssets "Spotnook-v$versionName.aab"
$apkDest = Join-Path $storeAssets "Spotnook-v$versionName.apk"

Copy-Item -Force $aabSource $aabDest
Copy-Item -Force $apkSource $apkDest

Write-Host "`nBUILD COMPLETE!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "1. Play Store Release (.aab) [Upload to Play Console]:" -ForegroundColor White
Write-Host "   $aabDest" -ForegroundColor Yellow
Get-Item $aabDest | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize

Write-Host "2. Direct Test APK (.apk) [Send via WhatsApp/Drive]:" -ForegroundColor White
Write-Host "   $apkDest" -ForegroundColor Yellow
Get-Item $apkDest | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize
Write-Host "==========================================" -ForegroundColor Green

