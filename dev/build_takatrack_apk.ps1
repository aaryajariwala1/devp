# ============================================================
# TakaTrack APK Builder
# Run this script in PowerShell as Administrator
# ============================================================

$ErrorActionPreference = "Stop"
$FlutterDir = "C:\flutter"
$ProjectDir = "C:\dev\taka_track"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   TakaTrack APK Builder" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Step 1: Check if Flutter is already installed
if (Test-Path "$FlutterDir\bin\flutter.bat") {
    Write-Host "[OK] Flutter already installed at $FlutterDir" -ForegroundColor Green
} else {
    Write-Host "[1/5] Downloading Flutter SDK (~600MB)..." -ForegroundColor Yellow
    $flutterZip = "$env:TEMP\flutter_windows.zip"
    Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.32.1-stable.zip" `
        -OutFile $flutterZip -UseBasicParsing
    Write-Host "[1/5] Extracting Flutter..." -ForegroundColor Yellow
    Expand-Archive -Path $flutterZip -DestinationPath "C:\" -Force
    Remove-Item $flutterZip
    Write-Host "[OK] Flutter extracted to $FlutterDir" -ForegroundColor Green
}

# Step 2: Add Flutter to PATH for this session
$env:PATH = "$FlutterDir\bin;$env:PATH"
Write-Host "[2/5] Flutter added to PATH" -ForegroundColor Green

# Step 3: Accept Android licenses (non-interactive)
Write-Host "[3/5] Accepting Android SDK licenses..." -ForegroundColor Yellow
$yes = "y`ny`ny`ny`ny`ny`ny`ny`ny`n"
$yes | & "$FlutterDir\bin\flutter.bat" doctor --android-licenses 2>&1 | Out-Null
Write-Host "[OK] Licenses accepted" -ForegroundColor Green

# Step 4: Get packages
Write-Host "[4/5] Running flutter pub get..." -ForegroundColor Yellow
Set-Location $ProjectDir
& "$FlutterDir\bin\flutter.bat" pub get
Write-Host "[OK] Packages downloaded" -ForegroundColor Green

# Step 5: Build debug APK
Write-Host "[5/5] Building APK (this takes 3-5 minutes on first run)..." -ForegroundColor Yellow
& "$FlutterDir\bin\flutter.bat" build apk --debug --target-platform android-arm64

$apkPath = "$ProjectDir\build\app\outputs\flutter-apk\app-debug.apk"
if (Test-Path $apkPath) {
    $apkSize = [math]::Round((Get-Item $apkPath).Length / 1MB, 1)
    Write-Host "" 
    Write-Host "================================================" -ForegroundColor Green
    Write-Host "   APK BUILT SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "   Size: ${apkSize}MB" -ForegroundColor Green
    Write-Host "   Path: $apkPath" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Copy APK to phone:" -ForegroundColor Cyan
    Write-Host "  adb install `"$apkPath`"" -ForegroundColor White
    Write-Host "  OR copy the file manually via USB" -ForegroundColor White
    
    # Copy to Desktop for easy access
    $desktopPath = [System.Environment]::GetFolderPath('Desktop')
    Copy-Item $apkPath "$desktopPath\TakaTrack-debug.apk" -Force
    Write-Host ""
    Write-Host "  APK also copied to your Desktop!" -ForegroundColor Green
} else {
    Write-Host "Build failed. Check errors above." -ForegroundColor Red
}
