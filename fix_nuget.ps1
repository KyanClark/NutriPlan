# Comprehensive NuGet Fix for Flutter TTS on Windows
# Run this script as Administrator for best results

Write-Host "=== NuGet Fix for Flutter TTS ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Ensure NuGet directory exists
$nugetDir = "C:\Tools\nuget"
$nugetPath = "$nugetDir\nuget.exe"

if (-not (Test-Path $nugetDir)) {
    Write-Host "Creating NuGet directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $nugetDir -Force | Out-Null
}

# Step 2: Download NuGet if missing
if (-not (Test-Path $nugetPath)) {
    Write-Host "Downloading NuGet.exe..." -ForegroundColor Yellow
    $nugetUrl = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
    try {
        Invoke-WebRequest -Uri $nugetUrl -OutFile $nugetPath -UseBasicParsing
        Write-Host "✓ Downloaded NuGet.exe successfully!" -ForegroundColor Green
    } catch {
        Write-Host "✗ Error downloading NuGet: $_" -ForegroundColor Red
        Write-Host "Please download manually from: $nugetUrl" -ForegroundColor Yellow
        Write-Host "Save it to: $nugetPath" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "✓ NuGet.exe found at: $nugetPath" -ForegroundColor Green
}

# Step 3: Add to User PATH
Write-Host "`nUpdating PATH environment variable..." -ForegroundColor Yellow
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$nugetDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$nugetDir", "User")
    Write-Host "✓ Added to User PATH" -ForegroundColor Green
} else {
    Write-Host "✓ Already in User PATH" -ForegroundColor Green
}

# Step 4: Add to System PATH (requires admin)
$systemPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($systemPath -notlike "*$nugetDir*") {
    try {
        [Environment]::SetEnvironmentVariable("Path", "$systemPath;$nugetDir", "Machine")
        Write-Host "✓ Added to System PATH" -ForegroundColor Green
    } catch {
        Write-Host "⚠ Could not add to System PATH (requires admin): $_" -ForegroundColor Yellow
        Write-Host "  User PATH should be sufficient." -ForegroundColor Yellow
    }
} else {
    Write-Host "✓ Already in System PATH" -ForegroundColor Green
}

# Step 5: Set NUGET_EXE environment variable (CMake looks for this)
Write-Host "`nSetting NUGET_EXE environment variable..." -ForegroundColor Yellow
[Environment]::SetEnvironmentVariable("NUGET_EXE", $nugetPath, "User")
try {
    [Environment]::SetEnvironmentVariable("NUGET_EXE", $nugetPath, "Machine")
    Write-Host "✓ Set NUGET_EXE for System" -ForegroundColor Green
} catch {
    Write-Host "⚠ Could not set NUGET_EXE for System (requires admin)" -ForegroundColor Yellow
}
$env:NUGET_EXE = $nugetPath
Write-Host "✓ Set NUGET_EXE for current session" -ForegroundColor Green

# Step 6: Update current session PATH
$env:Path += ";$nugetDir"

# Step 7: Verify NuGet works
Write-Host "`nVerifying NuGet installation..." -ForegroundColor Cyan
try {
    $nugetVersion = & $nugetPath help 2>&1 | Select-String -Pattern "NuGet Version" | Select-Object -First 1
    if ($nugetVersion) {
        Write-Host "✓ $nugetVersion" -ForegroundColor Green
    } else {
        # Try direct command
        $testResult = & $nugetPath 2>&1
        if ($LASTEXITCODE -eq 0 -or $testResult -like "*NuGet*") {
            Write-Host "✓ NuGet is working!" -ForegroundColor Green
        } else {
            Write-Host "⚠ NuGet may not be working correctly" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "✗ Error verifying NuGet: $_" -ForegroundColor Red
}

# Step 8: Verify PATH in current session
Write-Host "`nVerifying PATH in current session..." -ForegroundColor Cyan
if ($env:Path -like "*$nugetDir*") {
    Write-Host "✓ NuGet directory is in current session PATH" -ForegroundColor Green
} else {
    Write-Host "⚠ NuGet directory not in current session PATH" -ForegroundColor Yellow
}

# Step 9: Test nuget command
Write-Host "`nTesting 'nuget' command..." -ForegroundColor Cyan
try {
    $testCmd = Get-Command nuget -ErrorAction Stop
    Write-Host "✓ 'nuget' command found at: $($testCmd.Source)" -ForegroundColor Green
} catch {
    Write-Host "⚠ 'nuget' command not found in PATH (may need to restart terminal)" -ForegroundColor Yellow
    Write-Host "  Full path: $nugetPath" -ForegroundColor Gray
}

Write-Host "`n=== Setup Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Close and reopen your terminal/IDE (IMPORTANT!)" -ForegroundColor White
Write-Host "2. Run: flutter clean" -ForegroundColor White
Write-Host "3. Run: flutter pub get" -ForegroundColor White
Write-Host "4. Run: flutter run -d windows" -ForegroundColor White
Write-Host ""
Write-Host "If it still doesn't work, try:" -ForegroundColor Yellow
Write-Host "  - Restart your computer" -ForegroundColor White
Write-Host "  - Or run: `$env:NUGET_EXE='$nugetPath'; flutter run -d windows" -ForegroundColor White

