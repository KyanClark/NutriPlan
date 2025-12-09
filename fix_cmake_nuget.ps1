# Fix CMakeLists.txt to skip NuGet check (since TTS is disabled on Windows)
# This script patches the flutter_tts CMakeLists.txt after Flutter generates it

$cmakeFile = "windows\flutter\ephemeral\.plugin_symlinks\flutter_tts\windows\CMakeLists.txt"

if (Test-Path $cmakeFile) {
    Write-Host "Patching CMakeLists.txt to skip NuGet (TTS disabled on Windows)..." -ForegroundColor Yellow
    
    $content = Get-Content $cmakeFile -Raw
    
    # Replace the NuGet check to make it optional (just skip if not found)
    $oldText = @'
################ NuGet intall begin ################
find_program(NUGET_EXE NAMES nuget)
if(NOT NUGET_EXE)
	message("NUGET.EXE not found.")
	message(FATAL_ERROR "Please install this executable, and run CMake again.")
endif()

exec_program(${NUGET_EXE}
    ARGS install "Microsoft.Windows.CppWinRT" -Version 	2.0.210503.1 -ExcludeVersion -OutputDirectory ${CMAKE_BINARY_DIR}/packages)
################ NuGet install end ################
'@
    
    $newText = @'
################ NuGet intall begin ################
# Skip NuGet on Windows since TTS is disabled in Dart code
# Check NUGET_EXE environment variable first, then PATH
if(DEFINED ENV{NUGET_EXE} AND EXISTS "$ENV{NUGET_EXE}")
    set(NUGET_EXE "$ENV{NUGET_EXE}")
else()
    find_program(NUGET_EXE NAMES nuget)
endif()

if(NUGET_EXE)
    exec_program(${NUGET_EXE}
        ARGS install "Microsoft.Windows.CppWinRT" -Version 	2.0.210503.1 -ExcludeVersion -OutputDirectory ${CMAKE_BINARY_DIR}/packages)
else()
    message(WARNING "NUGET.EXE not found. Skipping NuGet package installation (TTS is disabled on Windows).")
    # Create empty packages directory to avoid errors
    file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/packages/Microsoft.Windows.CppWinRT/build/native)
endif()
################ NuGet install end ################
'@
    
    $content = $content.Replace($oldText, $newText)
    
    Set-Content -Path $cmakeFile -Value $content -NoNewline
    Write-Host "✓ Patched CMakeLists.txt - NuGet is now optional" -ForegroundColor Green
} else {
    Write-Host "⚠ CMakeLists.txt not found at: $cmakeFile" -ForegroundColor Yellow
    Write-Host "  Run 'flutter pub get' first to generate it." -ForegroundColor Gray
}

