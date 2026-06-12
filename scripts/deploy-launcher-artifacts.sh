#!/bin/bash
# Deploy Tauri launcher binaries from build/ to CDN + NSIS installer
set -euo pipefail

ROOT="/opt/darkworld"
BUILD="$ROOT/build"
DOWNLOADS="/var/www/zorionlabs/dark/downloads"
LAUNCHER_SRC="$BUILD/launcher/DarkWorld-Launcher.exe"
LAUNCHER_MAC="$BUILD/launcher-mac/DarkWorld-Launcher-mac.tar.gz"

bash "$ROOT/scripts/sync-version.sh"

mkdir -p "$BUILD/launcher" "$DOWNLOADS"

if [ -f "$LAUNCHER_SRC" ]; then
  if strings "$LAUNCHER_SRC" 2>/dev/null | grep -qi 'node_modules'; then
    echo "ERROR: Refusing to publish — launcher exe contains Node.js strings (wrong binary)"
    exit 1
  fi
  cp "$LAUNCHER_SRC" "$DOWNLOADS/DarkWorld-Launcher.exe"
  echo "Published Tauri GUI: DarkWorld-Launcher.exe ($(stat -c%s "$DOWNLOADS/DarkWorld-Launcher.exe") bytes)"
else
  echo "WARN: $LAUNCHER_SRC not found — run GitHub Actions build-launcher first"
fi

if [ -f "$LAUNCHER_MAC" ]; then
  cp "$LAUNCHER_MAC" "$DOWNLOADS/DarkWorld-Launcher-mac.tar.gz"
  echo "Published macOS launcher: DarkWorld-Launcher-mac.tar.gz"
fi

if [ -f "$DOWNLOADS/DarkWorld-Launcher.exe" ] && command -v makensis >/dev/null 2>&1; then
  mkdir -p "$ROOT/scripts/templates"
  python3 -c "
import json, os
v = json.load(open('$ROOT/version.json'))
os.makedirs('$ROOT/scripts/templates', exist_ok=True)
with open('$ROOT/scripts/templates/installer-version.json', 'w') as f:
    json.dump({'game_version': v['game_version'], 'launcher_version': v['launcher_version']}, f)
"
  makensis "$ROOT/scripts/darkworld-launcher.nsi" 2>&1 | tail -5 || true
  if [ -f "$BUILD/DarkWorld-Launcher-Setup.exe" ]; then
    cp "$BUILD/DarkWorld-Launcher-Setup.exe" "$DOWNLOADS/"
    echo "Published NSIS installer: DarkWorld-Launcher-Setup.exe"
  fi
fi

python3 << 'PYEOF'
import json, os, hashlib
from datetime import datetime, timezone

ROOT = "/opt/darkworld"
DOWNLOADS = "/var/www/zorionlabs/dark/downloads"
version = json.load(open(os.path.join(ROOT, "version.json")))
gv = version["game_version"]
lv = version["launcher_version"]
force = version.get("force_update", False)
commit = os.popen(f"git -C {ROOT} rev-parse --short HEAD 2>/dev/null").read().strip() or "unknown"

entries = [
    ("DarkWorld-Windows-portable.zip", "/downloads/DarkWorld-Windows-portable.zip", "windows", "game", "zip", True),
    ("DarkWorld-Mac-debug.tar.gz", "/downloads/DarkWorld-Mac-debug.tar.gz", "macos", "game", "tar.gz", True),
    ("DarkWorld-Launcher-Setup.exe", "/downloads/DarkWorld-Launcher-Setup.exe", "windows", "launcher_installer", "exe", False),
    ("DarkWorld-Launcher.exe", "/downloads/DarkWorld-Launcher.exe", "windows", "launcher", "exe", False),
    ("DarkWorld-Launcher-mac.tar.gz", "/downloads/DarkWorld-Launcher-mac.tar.gz", "macos", "launcher", "tar.gz", False),
]

files = []
for fname, url, platform, role, pkg, required in entries:
    path = os.path.join(DOWNLOADS, fname)
    if not os.path.exists(path):
        continue
    sha = hashlib.sha256(open(path, "rb").read()).hexdigest()
    files.append({
        "path": fname, "url": url, "size": os.path.getsize(path), "sha256": sha,
        "platform": platform, "role": role, "package_type": pkg, "required": required
    })

manifest = {
    "game_version": gv,
    "launcher_version": lv,
    "build_commit": commit,
    "files": files,
    "published_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "force_update": force,
    "backend_min_version": version.get("backend_min_version", "2.0.0"),
    "release_notes_url": "https://dark.zorionlabs.net/downloads/CHANGELOG.md"
}
os.makedirs(os.path.join(DOWNLOADS, "launcher"), exist_ok=True)
with open(os.path.join(DOWNLOADS, "launcher", "manifest.json"), "w") as f:
    json.dump(manifest, f, indent=2)
print(f"Manifest updated: {len(files)} files (launcher-only entries, no game installer)")
PYEOF

python3 "$ROOT/scripts/validate-manifest.py" 2>/dev/null || true
python3 "$ROOT/scripts/sync-manifest-db.py" 2>/dev/null || true

# Update portal download links with cache-bust query from published hashes
if [ -f "$DOWNLOADS/DarkWorld-Launcher-Setup.exe" ]; then
  SETUP_HASH=$(sha256sum "$DOWNLOADS/DarkWorld-Launcher-Setup.exe" | awk '{print substr($1,1,8)}')
  EXE_HASH=$(sha256sum "$DOWNLOADS/DarkWorld-Launcher.exe" | awk '{print substr($1,1,8)}')
  for PORTAL in /var/www/zorionlabs/dark/index.html /var/www/zorionlabs/dark/downloads/index.html; do
    [ -f "$PORTAL" ] || continue
    sed -i "s|DarkWorld-Launcher-Setup.exe?v=[a-f0-9]*|DarkWorld-Launcher-Setup.exe?v=${SETUP_HASH}|g" "$PORTAL"
    sed -i "s|DarkWorld-Launcher-Setup.exe\"|DarkWorld-Launcher-Setup.exe?v=${SETUP_HASH}\"|g" "$PORTAL"
    sed -i "s|DarkWorld-Launcher.exe?v=[a-f0-9]*|DarkWorld-Launcher.exe?v=${EXE_HASH}|g" "$PORTAL"
    sed -i "s|DarkWorld-Launcher.exe\"|DarkWorld-Launcher.exe?v=${EXE_HASH}\"|g" "$PORTAL"
  done
fi

bash "$ROOT/scripts/purge_cloudflare_cache.sh" 2>/dev/null || echo "WARN: Cloudflare purge failed — users may get stale cache until manual purge"

echo "Launcher artifacts deployed to CDN."
