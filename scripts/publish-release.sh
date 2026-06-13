#!/bin/bash
set -e
# Dark World — Unified Release Pipeline v1.0.0
# Builds, versions, hashes, publishes, validates

GODOT="/opt/godot/godot_4.6.3/Godot_v4.6.3-stable_linux.x86_64"
PROJECT="/opt/darkworld/godot-client"
BUILD="/opt/darkworld/build"
DOWNLOADS="/var/www/zorionlabs/dark/downloads"
echo "[1/8] Updating version from version.json..."
VERSION="${1:-$(python3 -c 'import json; print(json.load(open("/opt/darkworld/version.json"))["game_version"])' 2>/dev/null || echo '5.0.5')}"
echo "  Version: $VERSION"

# Sync LOCAL_VERSION in Main.gd
sed -i "s/const LOCAL_VERSION = \"[0-9.]*\"/const LOCAL_VERSION = \"$VERSION\"/" "$PROJECT/scripts/Main.gd"
echo "  Main.gd LOCAL_VERSION synced to $VERSION"

# Sync portal HTML (if exists)
if [ -f /var/www/zorionlabs/dark/index.html ]; then
  sed -i "s/v[0-9]\.[0-9]\.[0-9]/v$VERSION/g" /var/www/zorionlabs/dark/index.html
  echo "  Portal HTML synced to v$VERSION"
fi
COMMIT=$(git -C /opt/darkworld rev-parse --short HEAD)

echo "============================================"
echo "  DARK WORLD — RELEASE PIPELINE v1.0.0"
echo "  Version: $VERSION  Commit: $COMMIT"
echo "============================================"

echo "[1/7] Cleaning..."
rm -rf "$BUILD/windows" "$BUILD/DarkWorld.app"
mkdir -p "$BUILD/windows"

echo "[2/7] Export Windows..."
GODOT_SILENCE_ROOT_WARNING=1 "$GODOT" --headless --path "$PROJECT" --export-debug "Windows" "$BUILD/windows/DarkWorld.exe" 2>&1 | grep -E "DONE|ERROR"

echo "[3/7] Export macOS..."
GODOT_SILENCE_ROOT_WARNING=1 "$GODOT" --headless --path "$PROJECT" --export-debug "macOS" "$BUILD/DarkWorld.app" 2>&1 | grep -E "DONE|ERROR"

echo "[4/7] Package..."
cd "$BUILD"
zip -r "$BUILD/DarkWorld-Windows-portable.zip" windows/ -x "*.pdb"
tar -czf "$BUILD/DarkWorld-Mac-debug.tar.gz" DarkWorld.app/
makensis "/opt/darkworld/scripts/darkworld.nsi" 2>&1 | tail -2

echo "[5/7] Generate manifest..."
python3 -c "
import json, os, hashlib
files = []
for path, url, platform in [
    ('$BUILD/windows/DarkWorld.exe', '/downloads/DarkWorld-Windows-Setup.exe', 'windows'),
    ('$BUILD/DarkWorld-Windows-portable.zip', '/downloads/DarkWorld-Windows-portable.zip', 'windows'),
    ('$BUILD/DarkWorld-Mac-debug.tar.gz', '/downloads/DarkWorld-Mac-debug.tar.gz', 'macos'),
]:
    if os.path.exists(path):
        size = os.path.getsize(path)
        sha = hashlib.sha256(open(path, 'rb').read()).hexdigest()
        files.append({'path': path.split('/')[-1], 'url': url, 'size': size, 'sha256': sha, 'platform': platform, 'required': True})
manifest = {'game_version': '$VERSION', 'launcher_version': '1.0.0', 'build_commit': '$COMMIT', 'files': files, 'published_at': '$(date -u +%Y-%m-%dT%H:%M:%SZ)', 'force_update': True, 'backend_min_version': '2.0.0'}
os.makedirs('$DOWNLOADS/launcher', exist_ok=True)
with open('$DOWNLOADS/launcher/manifest.json', 'w') as f: json.dump(manifest, f)
print(f'Manifest: {len(files)} files')
for f in files: print(f'  {f[\"platform\"]}: {f[\"sha256\"][:16]}... ({f[\"size\"]//1024//1024}MB)')
"

echo "[6/7] Publish..."
cp "$BUILD/DarkWorld-Setup.exe" "$DOWNLOADS/DarkWorld-Windows-Setup.exe"
cp "$BUILD/DarkWorld-Windows-portable.zip" "$DOWNLOADS/"
cp "$BUILD/DarkWorld-Mac-debug.tar.gz" "$DOWNLOADS/"
sha256sum "$DOWNLOADS/DarkWorld-Windows-Setup.exe" > "$DOWNLOADS/DarkWorld-Windows-Setup.exe.sha256"
sha256sum "$DOWNLOADS/DarkWorld-Mac-debug.tar.gz" > "$DOWNLOADS/DarkWorld-Mac-debug.tar.gz.sha256"

echo "[7/7] Validate..."
for F in DarkWorld-Windows-Setup.exe DarkWorld-Windows-portable.zip DarkWorld-Mac-debug.tar.gz; do
  SIZE=$(stat -c%s "$DOWNLOADS/$F" 2>/dev/null || echo 0)
  if [ "$SIZE" -gt 100000 ]; then echo "  ✓ $F ($((SIZE/1024/1024))MB)"; else echo "  ✗ $F MISSING"; fi
done
echo "============================================"
echo "  RELEASE v$VERSION PUBLISHED"
echo "  Windows: https://dark.zorionlabs.net/downloads/DarkWorld-Windows-Setup.exe"
echo "  macOS:   https://dark.zorionlabs.net/downloads/DarkWorld-Mac-debug.tar.gz"
echo "============================================"
