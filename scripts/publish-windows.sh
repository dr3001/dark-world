#!/bin/bash
set -e
GODOT="/opt/godot/godot_4.6.3/Godot_v4.6.3-stable_linux.x86_64"
PROJECT="/opt/darkworld/godot-client"
BUILD="/opt/darkworld/build"
DOWNLOADS="/var/www/zorionlabs/dark/downloads"

echo "[1/6] Cleaning..."
rm -rf "$BUILD/windows"
mkdir -p "$BUILD/windows"

echo "[2/6] Exporting Windows debug build..."
GODOT_SILENCE_ROOT_WARNING=1 "$GODOT" --headless --path "$PROJECT" --export-release "Windows" "$BUILD/windows/DarkWorld.exe" 2>&1 | tail -5

echo "[3/6] Validating..."
ls -lh "$BUILD/windows/"
EXE_SIZE=$(stat -c%s "$BUILD/windows/DarkWorld.exe" 2>/dev/null || echo 0)
echo "   EXE size: $EXE_SIZE bytes"
if [ "$EXE_SIZE" -lt 1000000 ]; then echo "ERROR: EXE too small"; exit 1; fi

echo "[4/6] Creating portable ZIP..."
cd "$BUILD/windows"
zip -r "$BUILD/DarkWorld-Windows-portable.zip" . -x "*.pdb"
ls -lh "$BUILD/DarkWorld-Windows-portable.zip"

echo "[5/6] Building NSIS installer..."
if [ -f "/opt/darkworld/scripts/darkworld.nsi" ]; then
    makensis "/opt/darkworld/scripts/darkworld.nsi" 2>&1 | tail -5
else
    echo "NSIS script not found, skipping installer"
fi

echo "[6/6] Publishing..."
cp "$BUILD/DarkWorld-Windows-portable.zip" "$DOWNLOADS/"
sha256sum "$DOWNLOADS/DarkWorld-Windows-portable.zip" > "$DOWNLOADS/DarkWorld-Windows-portable.zip.sha256"
if [ -f "$BUILD/DarkWorld-Setup.exe" ]; then
    cp "$BUILD/DarkWorld-Setup.exe" "$DOWNLOADS/DarkWorld-Windows-Setup.exe"
    sha256sum "$DOWNLOADS/DarkWorld-Windows-Setup.exe" > "$DOWNLOADS/DarkWorld-Windows-Setup.exe.sha256"
fi

echo ""
echo "============================================"
echo "  WINDOWS BUILD GERADO"
echo "  Portable: $DOWNLOADS/DarkWorld-Windows-portable.zip ($(ls -lh $DOWNLOADS/DarkWorld-Windows-portable.zip | awk '{print $5}'))"
if [ -f "$DOWNLOADS/DarkWorld-Windows-Setup.exe" ]; then
echo "  Installer: $DOWNLOADS/DarkWorld-Windows-Setup.exe ($(ls -lh $DOWNLOADS/DarkWorld-Windows-Setup.exe | awk '{print $5}'))"
fi
echo "============================================"
