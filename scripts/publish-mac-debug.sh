#!/bin/bash
# ===========================================
#  publish-mac-debug.sh — Dark World
#  Exporta, empacota e publica build debug
#  Usa --export-debug nativo do Godot 4.6.3
# ===========================================
set -e

GODOT="/opt/godot/godot_4.6.3/Godot_v4.6.3-stable_linux.x86_64"
PROJECT="/opt/darkworld/godot-client"
BUILD="/opt/darkworld/build"
DOWNLOADS="/var/www/zorionlabs/dark/downloads"

echo "[1/4] Cleaning old builds..."
rm -rf "$PROJECT/.godot/exported"
rm -rf "$BUILD/DarkWorld.app"

echo "[2/4] Exporting macOS debug build (Godot 4.6.3 native)..."
GODOT_SILENCE_ROOT_WARNING=1 "$GODOT" --headless --path "$PROJECT" --export-debug "macOS" "$BUILD/DarkWorld.app" 2>&1 | tail -5

echo "   App structure:"
find "$BUILD/DarkWorld.app" -type f -exec ls -lh {} \; 2>/dev/null | awk '{print "   ", $5, $NF}'

echo "[3/4] Packaging..."
cd "$BUILD"
rm -f DarkWorld-Mac-debug.tar.gz
tar -czf DarkWorld-Mac-debug.tar.gz DarkWorld.app/

echo "[4/4] Publishing..."
cp DarkWorld-Mac-debug.tar.gz "$DOWNLOADS/"
sha256sum "$DOWNLOADS/DarkWorld-Mac-debug.tar.gz" > "$DOWNLOADS/DarkWorld-Mac-debug.tar.gz.sha256"

echo ""
echo "============================================"
echo "  BUILD GERADO"
echo "  URL: https://dark.zorionlabs.net/downloads/DarkWorld-Mac-debug.tar.gz"
echo "  SIZE: $(ls -lh $DOWNLOADS/DarkWorld-Mac-debug.tar.gz | awk '{print $5}')"
echo "  SHA256: $(cat $DOWNLOADS/DarkWorld-Mac-debug.tar.gz.sha256)"
echo "============================================"
