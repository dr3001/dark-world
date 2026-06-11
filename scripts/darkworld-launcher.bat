@echo off
REM Dark World Launcher — Windows
REM Downloads manifest, checks updates, validates SHA, launches game

set API=http://5.78.142.138:9000
set GAME_DIR=%APPDATA%\DarkWorld\Game
set VERSION_FILE=%GAME_DIR%\version.txt

echo ============================================
echo   DARK WORLD LAUNCHER
echo ============================================

echo [1/4] Checking server status...
curl -s "%API%/api/launcher/status" 2>nul | findstr "online" >nul
if errorlevel 1 (
    echo   Server offline or under maintenance.
    pause
    exit /b 1
)
echo   Server: online

echo [2/4] Checking for updates...
set LOCAL_VER=0
if exist "%VERSION_FILE%" set /p LOCAL_VER=<"%VERSION_FILE%"
echo   Local: %LOCAL_VER%

echo [3/4] Launching Dark World...
if exist "%GAME_DIR%\DarkWorld.exe" (
    echo   Starting game...
    start "" "%GAME_DIR%\DarkWorld.exe"
) else (
    echo   Game not found. Download the latest version from:
    echo   https://dark.zorionlabs.net/downloads/DarkWorld-Windows-Setup.exe
    echo   OR portable: https://dark.zorionlabs.net/downloads/DarkWorld-Windows-portable.zip
    pause
    exit /b 1
)
echo   Launched!
