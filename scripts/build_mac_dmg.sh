#!/bin/bash
# Dark World — Mac DMG Builder
# Execute ESTE SCRIPT NO MAC (requer Godot 4.x instalado)
# Uso: ./build_mac_dmg.sh

set -e

GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
PROJECT_DIR="$(cd "$(dirname "$0")/../godot-client" && pwd)"
BUILD_DIR="$PROJECT_DIR/build/mac"
APP_NAME="Dark World.app"
DMG_NAME="DarkWorld-Mac.dmg"
VERSION="0.2.0"

echo "=== Dark World — Mac DMG Builder v$VERSION ==="

# 1. Check Godot
if [ ! -f "$GODOT_BIN" ]; then
    echo "Godot nao encontrado em $GODOT_BIN"
    echo "Instale Godot 4.x de https://godotengine.org/download/macos/"
    exit 1
fi

# 2. Export project
echo "Exportando projeto..."
mkdir -p "$BUILD_DIR"
$GODOT_BIN --headless --path "$PROJECT_DIR" --export-release "macOS" "$BUILD_DIR/$APP_NAME" 2>&1

# 3. Create DMG
echo "Criando DMG..."
hdiutil create -volname "Dark World" -srcfolder "$BUILD_DIR/$APP_NAME" -ov -format UDZO "$BUILD_DIR/$DMG_NAME"

# 4. Generate SHA256
shasum -a 256 "$BUILD_DIR/$DMG_NAME" > "$BUILD_DIR/SHA256SUMS.txt"

# 5. Copy version info
echo "DARK_WORLD_VERSION=$VERSION" > "$BUILD_DIR/Version.txt"
echo "BUILD_DATE=$(date -u +%Y-%m-%d)" >> "$BUILD_DIR/Version.txt"

echo ""
echo "=== Build Complete ==="
echo "DMG: $BUILD_DIR/$DMG_NAME"
echo "SHA256: $(cat $BUILD_DIR/SHA256SUMS.txt)"
ls -lh "$BUILD_DIR/$DMG_NAME"
