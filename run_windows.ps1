# Flutter Windows Build Script with NuGet Setup
# This script ensures NuGet is available and sets environment variables before building

Write-Host "=== Flutter Windows Build with NuGet Setup ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Setup NuGet
$nugetDir = "C:\Tools\nuget"
$nugetPath = "$nugetDir\nuget.exe"

# Create directory if needed
if (-not (Test-Path $nugetDir)) {
    Write-Host "Creating NuGet directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $nugetDir -Force | Out-Null
}

# Download NuGet if missing
if (-not (Test-Path $nugetPath)) {
    Write-Host "Downloading NuGet.exe..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile $nugetPath -UseBasicParsing
        Write-Host "✓ Downloaded NuGet.exe successfully!" -ForegroundColor Green
    } catch {
        Write-Host "✗ Error downloading NuGet: $_" -ForegroundColor Red
        Write-Host "Please download manually from: https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -ForegroundColor Yellow
        Write-Host "Save it to: $nugetPath" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "✓ NuGet.exe found at: $nugetPath" -ForegroundColor Green
}

# Step 2: Set environment variables for THIS session (CMake will use these)
Write-Host "`nSetting environment variables..." -ForegroundColor Yellow
$env:NUGET_EXE = $nugetPath
$env:Path = "$nugetDir;$env:Path"

# Also set permanently for future sessions
[Environment]::SetEnvironmentVariable("NUGET_EXE", $nugetPath, "User")
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$nugetDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$nugetDir", "User")
    Write-Host "✓ Added to permanent PATH" -ForegroundColor Green
}

Write-Host "✓ Environment variables set:" -ForegroundColor Green
Write-Host "  NUGET_EXE = $env:NUGET_EXE" -ForegroundColor Gray
Write-Host "  PATH includes: $nugetDir" -ForegroundColor Gray

# Step 3: Verify NuGet works
Write-Host "`nVerifying NuGet..." -ForegroundColor Yellow
try {
    $testResult = & $nugetPath 2>&1 | Select-Object -First 1
    Write-Host "✓ NuGet is working!" -ForegroundColor Green
} catch {
    Write-Host "⚠ Warning: Could not verify NuGet" -ForegroundColor Yellow
}

# Step 4: Clean and build
Write-Host "`n=== Building Flutter App ===" -ForegroundColor Cyan
Write-Host ""

# Clean first
Write-Host "Running flutter clean..." -ForegroundColor Yellow
flutter clean

Write-Host "`nRunning flutter pub get..." -ForegroundColor Yellow
flutter pub get

# Patch CMakeLists.txt to check NUGET_EXE environment variable
Write-Host "`nPatching CMakeLists.txt..." -ForegroundColor Yellow
& ".\fix_cmake_nuget.ps1"

Write-Host "`nRunning flutter run -d windows..." -ForegroundColor Yellow
Write-Host "(Environment variables are set for this session)" -ForegroundColor Gray
Write-Host ""

# Run flutter with the environment variables set
flutter run -d windows

