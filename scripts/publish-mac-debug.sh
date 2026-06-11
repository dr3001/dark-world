#!/bin/bash
# ===========================================
#  publish-mac-debug.sh — Dark World
#  Recompila, empacota e publica build debug
# ===========================================
set -e

GODOT="/opt/godot/godot_4.6.3/Godot_v4.6.3-stable_linux.x86_64"
PROJECT="/opt/darkworld/godot-client"
BUILD="/opt/darkworld/build"
DOWNLOADS="/var/www/zorionlabs/dark/downloads"
TEMPLATE="/tmp/templates_463/templates/macos_463/macos_template.app"

echo "[1/6] Cleaning old compiled scenes..."
rm -rf "$PROJECT/.godot/exported"

echo "[2/6] Recompiling project (headless editor)..."
GODOT_SILENCE_ROOT_WARNING=1 timeout 20 "$GODOT" --headless --path "$PROJECT" --editor --quit 2>&1 | grep -v "Loading editor" || true

echo "[3/6] Exporting .pck..."
rm -f /tmp/DarkWorld.pck
GODOT_SILENCE_ROOT_WARNING=1 "$GODOT" --headless --path "$PROJECT" --export-pack "macOS" /tmp/DarkWorld.pck 2>&1 | grep -E "ERROR|DONE"
echo "   Pack: $(ls -lh /tmp/DarkWorld.pck | awk '{print $5}')"

echo "[4/6] Assembling DarkWorld.app..."
rm -rf "$BUILD/DarkWorld.app"
mkdir -p "$BUILD/DarkWorld.app/Contents/MacOS"
mkdir -p "$BUILD/DarkWorld.app/Contents/Resources"

cp "$TEMPLATE/Contents/MacOS/godot_macos_release.universal" "$BUILD/DarkWorld.app/Contents/MacOS/DarkWorld"
chmod 755 "$BUILD/DarkWorld.app/Contents/MacOS/DarkWorld"
# PCK embedded in binary below"
# Embed .pck into binary (required for macOS)
cp /tmp/DarkWorld.pck "$BUILD/DarkWorld.app/Contents/MacOS/DarkWorld.pck"
cat /tmp/DarkWorld.pck >> "$BUILD/DarkWorld.app/Contents/MacOS/DarkWorld"
chmod 755 "$BUILD/DarkWorld.app/Contents/MacOS/DarkWorld"
cp /tmp/DarkWorld.pck "$BUILD/DarkWorld.app/Contents/Resources/DarkWorld.pck"
cp "$TEMPLATE/Contents/Resources/icon.icns" "$BUILD/DarkWorld.app/Contents/Resources/"
echo -n "APPL????" > "$BUILD/DarkWorld.app/Contents/PkgInfo"

cat > "$BUILD/DarkWorld.app/Contents/Info.plist" << 'PLISTEOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key><string>DarkWorld</string>
	<key>CFBundleIdentifier</key><string>com.zorionlabs.darkworld</string>
	<key>CFBundleName</key><string>Dark World</string>
	<key>CFBundleIconFile</key><string>icon.icns</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>CFBundleShortVersionString</key><string>0.2.0</string>
	<key>CFBundleVersion</key><string>0.2.0</string>
	<key>NSHighResolutionCapable</key><true/>
	<key>LSMinimumSystemVersion</key><string>10.15</string>
	<key>NSAppTransportSecurity</key>
	<dict><key>NSAllowsArbitraryLoads</key><true/></dict>
</dict>
</plist>
PLISTEOF

echo "[5/6] Packaging..."
cd "$BUILD"
rm -f DarkWorld-Mac-debug.tar.gz
tar -czf DarkWorld-Mac-debug.tar.gz DarkWorld.app/

echo "[6/6] Publishing..."
cp DarkWorld-Mac-debug.tar.gz "$DOWNLOADS/"
sha256sum "$DOWNLOADS/DarkWorld-Mac-debug.tar.gz" > "$DOWNLOADS/DarkWorld-Mac-debug.tar.gz.sha256"

echo ""
echo "============================================"
echo "  BUILD GERADO"
echo "  URL: https://dark.zorionlabs.net/downloads/DarkWorld-Mac-debug.tar.gz"
echo "  SIZE: $(ls -lh $DOWNLOADS/DarkWorld-Mac-debug.tar.gz | awk '{print $5}')"
echo "  SHA256: $(cat $DOWNLOADS/DarkWorld-Mac-debug.tar.gz.sha256)"
echo "============================================"
