#!/bin/bash
set -e
# Dark World — Unified Release Pipeline v2.0.0
# Builds, versions, hashes, publishes, validates, syncs DB

ROOT="/opt/darkworld"
GODOT="/opt/godot/godot_4.6.3/Godot_v4.6.3-stable_linux.x86_64"
PROJECT="$ROOT/godot-client"
BUILD="$ROOT/build"
DOWNLOADS="/var/www/zorionlabs/dark/downloads"

bash "$ROOT/scripts/sync-version.sh"

VERSION="${1:-$(python3 -c 'import json; print(json.load(open("/opt/darkworld/version.json"))["game_version"])')}"
LAUNCHER_VERSION="$(python3 -c 'import json; print(json.load(open("/opt/darkworld/version.json"))["launcher_version"])')"
FORCE_UPDATE="$(python3 -c 'import json; print(str(json.load(open("/opt/darkworld/version.json")).get("force_update",False)).lower())')"
COMMIT=$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown")

echo "============================================"
echo "  DARK WORLD — RELEASE PIPELINE v2.0.0"
echo "  Game: $VERSION  Launcher: $LAUNCHER_VERSION  Commit: $COMMIT"
echo "============================================"

echo "[1/9] Cleaning build dir..."
rm -rf "$BUILD/windows" "$BUILD/DarkWorld.app"
mkdir -p "$BUILD/windows"

echo "[2/9] Export Windows..."
GODOT_SILENCE_ROOT_WARNING=1 "$GODOT" --headless --path "$PROJECT" --export-release "Windows" "$BUILD/windows/DarkWorld.exe" 2>&1 | grep -E "DONE|ERROR|export|WARNING|invalid" || true

echo "[3/9] Export macOS..."
GODOT_SILENCE_ROOT_WARNING=1 "$GODOT" --headless --path "$PROJECT" --export-release "macOS" "$BUILD/DarkWorld.app" 2>&1 | grep -E "DONE|ERROR|export|WARNING|invalid" || true

echo "[4/9] Package game..."
cd "$BUILD"
zip -r "$BUILD/DarkWorld-Windows-portable.zip" windows/ -x "*.pdb" -q
tar -czf "$BUILD/DarkWorld-Mac-debug.tar.gz" DarkWorld.app/

if [ -f "$BUILD/launcher/DarkWorld-Launcher.exe" ]; then
  makensis "$ROOT/scripts/darkworld.nsi" 2>&1 | tail -3 || true
fi

echo "[5/9] Publish game files..."
cp "$BUILD/DarkWorld-Windows-portable.zip" "$DOWNLOADS/"
cp "$BUILD/DarkWorld-Mac-debug.tar.gz" "$DOWNLOADS/"
if [ -f "$BUILD/DarkWorld-Launcher-Setup.exe" ]; then
  cp "$BUILD/DarkWorld-Launcher-Setup.exe" "$DOWNLOADS/"
fi

echo "[6/9] Generate manifest (hash = published file)..."
python3 << PYEOF
import json, os, hashlib
from datetime import datetime, timezone

downloads = "$DOWNLOADS"
version = "$VERSION"
launcher_version = "$LAUNCHER_VERSION"
commit = "$COMMIT"
force_update = "$FORCE_UPDATE" == "true"

entries = [
    ("DarkWorld-Windows-portable.zip", "/downloads/DarkWorld-Windows-portable.zip", "windows", "game", "zip"),
    ("DarkWorld-Mac-debug.tar.gz", "/downloads/DarkWorld-Mac-debug.tar.gz", "macos", "game", "tar.gz"),
]
if os.path.exists(os.path.join(downloads, "DarkWorld-Launcher-Setup.exe")):
    entries.append(("DarkWorld-Launcher-Setup.exe", "/downloads/DarkWorld-Launcher-Setup.exe", "windows", "launcher_installer", "exe"))
if os.path.exists(os.path.join(downloads, "DarkWorld-Launcher.exe")):
    entries.append(("DarkWorld-Launcher.exe", "/downloads/DarkWorld-Launcher.exe", "windows", "launcher", "exe"))
if os.path.exists(os.path.join(downloads, "DarkWorld-Launcher-mac.tar.gz")):
    entries.append(("DarkWorld-Launcher-mac.tar.gz", "/downloads/DarkWorld-Launcher-mac.tar.gz", "macos", "launcher", "tar.gz"))

files = []
for fname, url, platform, role, pkg in entries:
    path = os.path.join(downloads, fname)
    if not os.path.exists(path):
        continue
    sha = hashlib.sha256(open(path, "rb").read()).hexdigest()
    files.append({
        "path": fname, "url": url, "size": os.path.getsize(path), "sha256": sha,
        "platform": platform, "role": role, "package_type": pkg, "required": role == "game"
    })

manifest = {
    "game_version": version,
    "launcher_version": launcher_version,
    "build_commit": commit,
    "files": files,
    "published_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "force_update": force_update,
    "backend_min_version": "2.0.0",
    "release_notes_url": "https://dark.zorionlabs.net/downloads/CHANGELOG.md"
}
os.makedirs(os.path.join(downloads, "launcher"), exist_ok=True)
with open(os.path.join(downloads, "launcher", "manifest.json"), "w") as f:
    json.dump(manifest, f, indent=2)
print(f"Manifest: {len(files)} files")
PYEOF

echo "[7/9] Validate manifest hashes..."
python3 "$ROOT/scripts/validate-manifest.py"

echo "[8/9] Sync manifest to PostgreSQL..."
python3 "$ROOT/scripts/sync-manifest-db.py" 2>/dev/null || echo "  (DB sync skipped)"

echo "[9/9] Rebuild world-engine + purge cache..."
cd "$ROOT/world-engine" && npm run build 2>/dev/null || true
docker compose -f "$ROOT/docker-compose.yml" up -d world-engine 2>/dev/null || docker restart darkworld-world-engine 2>/dev/null || true
bash "$ROOT/scripts/purge_cloudflare_cache.sh" 2>/dev/null || true

echo "============================================"
echo "  RELEASE v$VERSION PUBLISHED"
echo "  Manifest: https://dark.zorionlabs.net/downloads/launcher/manifest.json"
echo "============================================"
