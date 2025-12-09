@echo off
echo ========================================
echo NuGet Setup for Flutter TTS
echo ========================================
echo.

REM Create directory
if not exist "C:\Tools\nuget" mkdir "C:\Tools\nuget"

REM Download NuGet if it doesn't exist
if not exist "C:\Tools\nuget\nuget.exe" (
    echo Downloading NuGet.exe...
    powershell -Command "Invoke-WebRequest -Uri 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile 'C:\Tools\nuget\nuget.exe'"
    if exist "C:\Tools\nuget\nuget.exe" (
        echo NuGet downloaded successfully!
    ) else (
        echo ERROR: Failed to download NuGet
        pause
        exit /b 1
    )
) else (
    echo NuGet.exe already exists
)

REM Set environment variables
echo.
echo Setting environment variables...
setx NUGET_EXE "C:\Tools\nuget\nuget.exe"
setx PATH "%PATH%;C:\Tools\nuget"

REM Set for current session
set NUGET_EXE=C:\Tools\nuget\nuget.exe
set PATH=%PATH%;C:\Tools\nuget

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo IMPORTANT: Close and reopen your terminal/IDE
echo Then run: flutter clean
echo Then run: flutter pub get
echo Then run: flutter run -d windows
echo.
pause

