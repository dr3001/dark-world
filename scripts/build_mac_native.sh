#!/bin/bash
# =============================================
#  DARK WORLD — NATIVE MAC BUILD SCRIPT
#  Execute no Mac do Rogerio
#  Uso: bash build_mac_native.sh
# =============================================
set -e

RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; NC="\033[0m"
VERSION="0.2.0"
GODOT_VERSION="4.6.3"
GODOT_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_macos.universal.zip"
TEMPLATES_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"
REPO_URL="https://github.com/dr3001/dark-world.git"
SERVER="5.78.142.138"

echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}  DARK WORLD — NATIVE MAC BUILD v${VERSION}${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""

# === STEP 1: Check/Install Godot ===
GODOT_APP="/Applications/Godot.app"
if [ -d "$GODOT_APP" ]; then
    echo -e "${GREEN}[1/8] Godot found: $GODOT_APP${NC}"
else
    echo -e "${YELLOW}[1/8] Downloading Godot ${GODOT_VERSION}...${NC}"
    cd /tmp
    curl -L -o godot-mac.zip "$GODOT_URL"
    unzip -q godot-mac.zip
    mv Godot.app /Applications/
    echo -e "${GREEN}[1/8] Godot installed to /Applications/${NC}"
fi

# === STEP 2: Check/Install Export Templates ===
TEMPLATE_DIR="$HOME/Library/Application Support/Godot/export_templates/${GODOT_VERSION}.stable"
if [ -f "$TEMPLATE_DIR/macos.zip" ]; then
    echo -e "${GREEN}[2/8] Export templates found${NC}"
else
    echo -e "${YELLOW}[2/8] Downloading export templates...${NC}"
    mkdir -p "$TEMPLATE_DIR"
    cd /tmp
    curl -L -o godot-templates.tpz "$TEMPLATES_URL"
    unzip -q godot-templates.tpz -d /tmp/godot-templates
    cp /tmp/godot-templates/templates/* "$TEMPLATE_DIR/"
    echo -e "${GREEN}[2/8] Templates installed${NC}"
fi

# === STEP 3: Clone/Pull Repo ===
PROJECT_DIR="$HOME/Projects/dark-world"
if [ -d "$PROJECT_DIR/.git" ]; then
    echo -e "${GREEN}[3/8] Repo exists, pulling latest...${NC}"
    cd "$PROJECT_DIR"
    git pull origin main
else
    echo -e "${YELLOW}[3/8] Cloning repo...${NC}"
    mkdir -p "$HOME/Projects"
    git clone "$REPO_URL" "$PROJECT_DIR"
fi

# === STEP 4: Validate project ===
echo -e "${GREEN}[4/8] Validating project...${NC}"
cd "$PROJECT_DIR"
if [ ! -f "godot-client/project.godot" ]; then
    echo -e "${RED}ERROR: project.godot not found!${NC}"
    exit 1
fi
echo -e "${GREEN}       project.godot OK${NC}"

# === STEP 5: Godot Export (headless) ===
echo -e "${GREEN}[5/8] Exporting macOS build...${NC}"
BUILD_DIR="$PROJECT_DIR/godot-client/build/mac"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
$GODOT_BIN --headless --path "$PROJECT_DIR/godot-client" --export-release "macOS" "$BUILD_DIR/DarkWorld.app" 2>&1

if [ -d "$BUILD_DIR/DarkWorld.app" ]; then
    echo -e "${GREEN}       DarkWorld.app created!${NC}"
else
    echo -e "${RED}       Export may have failed. Check above for errors.${NC}"
    echo -e "${YELLOW}       Trying manual assembly...${NC}"
    
    # Manual assembly fallback
    $GODOT_BIN --headless --path "$PROJECT_DIR/godot-client" --export-pack "macOS" "$BUILD_DIR/DarkWorld.pck"
    
    mkdir -p "$BUILD_DIR/DarkWorld.app/Contents/MacOS"
    mkdir -p "$BUILD_DIR/DarkWorld.app/Contents/Resources"
    
    cp "$TEMPLATE_DIR/../macos_template.app/Contents/MacOS/godot_macos_release.universal" "$BUILD_DIR/DarkWorld.app/Contents/MacOS/DarkWorld"
    chmod 755 "$BUILD_DIR/DarkWorld.app/Contents/MacOS/DarkWorld"
    cp "$BUILD_DIR/DarkWorld.pck" "$BUILD_DIR/DarkWorld.app/Contents/MacOS/DarkWorld.pck"
    cp "$BUILD_DIR/DarkWorld.pck" "$BUILD_DIR/DarkWorld.app/Contents/Resources/DarkWorld.pck"
    
    cat > "$BUILD_DIR/DarkWorld.app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key><string>DarkWorld</string>
	<key>CFBundleIdentifier</key><string>com.darkworld.game</string>
	<key>CFBundleName</key><string>Dark World</string>
	<key>CFBundleIconFile</key><string>icon.icns</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>CFBundleShortVersionString</key><string>$VERSION</string>
	<key>CFBundleVersion</key><string>$VERSION</string>
	<key>NSHighResolutionCapable</key><true/>
	<key>LSMinimumSystemVersion</key><string>10.15</string>
</dict>
</plist>
EOF
    echo -n "APPL????" > "$BUILD_DIR/DarkWorld.app/Contents/PkgInfo"
fi

# === STEP 6: Code Sign (ad-hoc) ===
echo -e "${GREEN}[6/8] Code signing (ad-hoc)...${NC}"
codesign --force --deep --sign - "$BUILD_DIR/DarkWorld.app" 2>&1
echo -e "${GREEN}       Signed!${NC}"

# Verify signature
echo -e "${GREEN}       Verifying...${NC}"
codesign -dv --verbose=2 "$BUILD_DIR/DarkWorld.app" 2>&1 | head -3

# === STEP 7: Create DMG ===
echo -e "${GREEN}[7/8] Creating DMG...${NC}"
DMG_PATH="$PROJECT_DIR/release/DarkWorld.dmg"
rm -f "$DMG_PATH"
mkdir -p "$PROJECT_DIR/release"

hdiutil create -volname "Dark World" -srcfolder "$BUILD_DIR/DarkWorld.app" -ov -format UDZO "$DMG_PATH" 2>&1

if [ -f "$DMG_PATH" ]; then
    DMG_SIZE=$(ls -lh "$DMG_PATH" | awk '{print $5}')
    echo -e "${GREEN}       DMG created: $DMG_PATH ($DMG_SIZE)${NC}"
else
    echo -e "${RED}       DMG creation failed${NC}"
fi

# Also create .tar.gz and .zip
cd "$BUILD_DIR"
tar -czf "$PROJECT_DIR/release/DarkWorld-Mac.tar.gz" DarkWorld.app/
zip -rq "$PROJECT_DIR/release/DarkWorld-Mac.zip" DarkWorld.app/

# === STEP 8: Validate ===
echo -e "${GREEN}[8/8] Validation${NC}"

echo ""
echo -e "${GREEN}=== VALIDATION RESULTS ===${NC}"

# Check bundle
echo -n "Bundle structure: "
if [ -f "$BUILD_DIR/DarkWorld.app/Contents/Info.plist" ] && [ -f "$BUILD_DIR/DarkWorld.app/Contents/MacOS/DarkWorld" ]; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}BROKEN${NC}"
fi

# Check binary
echo -n "Binary type: "
file "$BUILD_DIR/DarkWorld.app/Contents/MacOS/DarkWorld" | cut -d: -f2

# Check signature
echo -n "Code sign: "
codesign -dv "$BUILD_DIR/DarkWorld.app" 2>&1 | grep "Signature=" || echo "ad-hoc"

# Check Gatekeeper
echo -n "Gatekeeper: "
spctl -a -vv "$BUILD_DIR/DarkWorld.app" 2>&1 | tail -1

# Test open
echo ""
echo -e "${YELLOW}Attempting to open app...${NC}"
open "$BUILD_DIR/DarkWorld.app" 2>/dev/null && echo -e "${GREEN}App launched!${NC}" || echo -e "${RED}Launch failed${NC}"

# === SUMMARY ===
echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}  BUILD COMPLETE${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo "Files generated:"
ls -lh "$PROJECT_DIR/release/"
echo ""
echo "To upload to server:"
echo "  scp $PROJECT_DIR/release/DarkWorld* root@5.78.142.138:/var/www/zorionlabs/dark/downloads/"
echo ""
echo "Or open directly:"
echo "  open $BUILD_DIR/DarkWorld.app"
