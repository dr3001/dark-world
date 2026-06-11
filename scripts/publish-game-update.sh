#!/bin/bash
set -e
BUILD="/opt/darkworld/build"
DOWNLOADS="/var/www/zorionlabs/dark/downloads"
VERSION="3.2.0-lore"
MANIFEST="$DOWNLOADS/launcher/manifest.json"

echo "[1/3] Computing file hashes..."
mkdir -p "$DOWNLOADS/launcher"

WIN_EXE="$BUILD/windows/DarkWorld.exe"
MAC_TGZ="$BUILD/DarkWorld-Mac-debug.tar.gz"
MAC_APP="$BUILD/DarkWorld.app"

FILES="[]"
if [ -f "$WIN_EXE" ]; then
    SIZE=$(stat -c%s "$WIN_EXE")
    SHA=$(sha256sum "$WIN_EXE" | awk '{print $1}')
    FILES=$(echo "$FILES" | python3 -c "import sys,json; f=json.loads(sys.argv[1]); f.append({'path':'DarkWorld.exe','url':'/downloads/DarkWorld-Windows-Setup.exe','size':$SIZE,'sha256':'$SHA','platform':'windows','required':True,'version':'$VERSION'}); print(json.dumps(f))")
fi
if [ -f "$MAC_TGZ" ]; then
    SIZE=$(stat -c%s "$MAC_TGZ")
    SHA=$(sha256sum "$MAC_TGZ" | awk '{print $1}')
    FILES=$(echo "$FILES" | python3 -c "import sys,json; f=json.loads(sys.argv[1]); f.append({'path':'DarkWorld.app','url':'/downloads/DarkWorld-Mac-debug.tar.gz','size':$SIZE,'sha256':'$SHA','platform':'macos','required':True,'version':'$VERSION'}); print(json.dumps(f))")
fi

echo "[2/3] Generating manifest..."
mkdir -p "$DOWNLOADS/launcher"
cat > "$MANIFEST" << MANIEOF
{
  "game_version": "$VERSION",
  "launcher_version": "0.1.0",
  "published_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "release_notes_url": "https://dark.zorionlabs.net/downloads/Version.txt",
  "server_status_url": "https://dark.zorionlabs.net/api/launcher/status",
  "files": $FILES
}
MANIEOF

echo "[3/3] Manifest published: $MANIFEST"
cat "$MANIFEST" | head -10
echo "============================================"
echo "  LAUNCHER MANIFEST GERADO"
echo "  URL: https://dark.zorionlabs.net/downloads/launcher/manifest.json"
echo "  Version: $VERSION"
echo "============================================"
