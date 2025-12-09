# Quick NuGet Setup Script
# Run this in your PowerShell terminal

Write-Host "=== Setting up NuGet for Flutter TTS ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Create directory
$nugetDir = "C:\Tools\nuget"
$nugetPath = "$nugetDir\nuget.exe"

if (-not (Test-Path $nugetDir)) {
    Write-Host "Creating directory: $nugetDir" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $nugetDir -Force | Out-Null
}

# Step 2: Download NuGet if missing
if (-not (Test-Path $nugetPath)) {
    Write-Host "Downloading NuGet.exe..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile $nugetPath -UseBasicParsing
        Write-Host "✓ Downloaded successfully!" -ForegroundColor Green
    } catch {
        Write-Host "✗ Error downloading: $_" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✓ NuGet.exe already exists" -ForegroundColor Green
}

# Step 3: Add to current session PATH
Write-Host "`nAdding to current session PATH..." -ForegroundColor Yellow
if ($env:Path -notlike "*$nugetDir*") {
    $env:Path += ";$nugetDir"
    Write-Host "✓ Added to current session PATH" -ForegroundColor Green
} else {
    Write-Host "✓ Already in current session PATH" -ForegroundColor Green
}

# Step 4: Set NUGET_EXE for current session
$env:NUGET_EXE = $nugetPath
Write-Host "✓ Set NUGET_EXE = $nugetPath" -ForegroundColor Green

# Step 5: Test it
Write-Host "`nTesting NuGet..." -ForegroundColor Cyan
try {
    $result = & $nugetPath 2>&1 | Select-Object -First 1
    Write-Host "✓ NuGet is working!" -ForegroundColor Green
    Write-Host "  You can now run: nuget" -ForegroundColor Gray
} catch {
    Write-Host "⚠ Warning: Could not verify NuGet" -ForegroundColor Yellow
}

# Step 6: Make it permanent (optional)
Write-Host "`nMaking it permanent..." -ForegroundColor Yellow
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$nugetDir*") {
    try {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$nugetDir", "User")
        Write-Host "✓ Added to User PATH (permanent)" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Could not add to User PATH: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "✓ Already in User PATH" -ForegroundColor Green
}

[Environment]::SetEnvironmentVariable("NUGET_EXE", $nugetPath, "User")
Write-Host "✓ Set NUGET_EXE permanently" -ForegroundColor Green

Write-Host "`n=== Setup Complete! ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "You can now use 'nuget' in this terminal." -ForegroundColor White
Write-Host "For new terminals, restart your IDE or run this script again." -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  flutter clean" -ForegroundColor White
Write-Host "  flutter pub get" -ForegroundColor White
Write-Host "  flutter run -d windows" -ForegroundColor White

