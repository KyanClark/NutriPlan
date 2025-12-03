# Build script for Windows that ensures NuGet is available
# This script sets up NuGet and builds the Flutter app

param(
    [switch]$Clean = $false
)

Write-Host "=== Flutter Windows Build Script ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Ensure NuGet is available
$nugetDir = "C:\Tools\nuget"
$nugetPath = "$nugetDir\nuget.exe"

# Download NuGet if it doesn't exist
if (-not (Test-Path $nugetPath)) {
    Write-Host "NuGet not found. Downloading..." -ForegroundColor Yellow
    if (-not (Test-Path $nugetDir)) {
        New-Item -ItemType Directory -Path $nugetDir -Force | Out-Null
    }
    
    $nugetUrl = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
    try {
        Invoke-WebRequest -Uri $nugetUrl -OutFile $nugetPath -UseBasicParsing
        Write-Host "✓ Downloaded NuGet.exe" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to download NuGet: $_" -ForegroundColor Red
        Write-Host "Please download manually from: $nugetUrl" -ForegroundColor Yellow
        Write-Host "Save to: $nugetPath" -ForegroundColor Yellow
        exit 1
    }
}

# Step 2: Set environment variables for this session
Write-Host "Setting up environment variables..." -ForegroundColor Yellow
$env:NUGET_EXE = $nugetPath
$env:Path = "$nugetDir;$env:Path"

# Also set for User (persistent)
[Environment]::SetEnvironmentVariable("NUGET_EXE", $nugetPath, "User")
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$nugetDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$nugetDir", "User")
}

Write-Host "✓ Environment variables set" -ForegroundColor Green
Write-Host "  NUGET_EXE = $nugetPath" -ForegroundColor Gray
Write-Host ""

# Step 3: Verify NuGet
Write-Host "Verifying NuGet..." -ForegroundColor Yellow
try {
    $testResult = & $nugetPath 2>&1
    Write-Host "✓ NuGet is working" -ForegroundColor Green
} catch {
    Write-Host "⚠ Warning: Could not verify NuGet" -ForegroundColor Yellow
}

# Step 4: Clean if requested
if ($Clean) {
    Write-Host "`nCleaning Flutter build..." -ForegroundColor Yellow
    flutter clean
    Write-Host "✓ Clean complete" -ForegroundColor Green
}

# Step 5: Get dependencies
Write-Host "`nGetting Flutter dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to get dependencies" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Dependencies installed" -ForegroundColor Green

# Step 6: Build and run
Write-Host "`nBuilding and running Flutter app..." -ForegroundColor Yellow
Write-Host ""

flutter run -d windows

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n✗ Build failed!" -ForegroundColor Red
    Write-Host "`nTroubleshooting tips:" -ForegroundColor Yellow
    Write-Host "1. Make sure Visual Studio Build Tools are installed" -ForegroundColor White
    Write-Host "2. Try running: flutter doctor -v" -ForegroundColor White
    Write-Host "3. Check if CMake is installed: cmake --version" -ForegroundColor White
    exit 1
}

