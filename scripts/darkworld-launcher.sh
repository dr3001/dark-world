#!/bin/bash
# Dark World Launcher — macOS/Linux
# Downloads manifest, checks updates, validates SHA, launches game

API="http://5.78.142.138:9000"
MANIFEST_URL="https://dark.zorionlabs.net/downloads/launcher/manifest.json"
GAME_DIR="$HOME/.darkworld/game"
CACHE_DIR="$HOME/.darkworld/cache"
LOG_DIR="$HOME/.darkworld/logs"
VERSION_FILE="$GAME_DIR/version.txt"

mkdir -p "$GAME_DIR" "$CACHE_DIR" "$LOG_DIR"

echo "============================================"
echo "  DARK WORLD LAUNCHER"
echo "============================================"

# Check server status
echo "[1/5] Checking server status..."
STATUS=$(curl -s "$API/api/launcher/status" 2>/dev/null)
SERVER=$(echo "$STATUS" | python3 -c "import sys,json; print(json.load(sys.stdin).get('server','offline'))" 2>/dev/null)
if [ "$SERVER" != "online" ]; then
    echo "  Server offline or under maintenance."
    exit 1
fi
echo "  Server: $SERVER"

# Download manifest
echo "[2/5] Checking for updates..."
MANIFEST=$(curl -s "$MANIFEST_URL" 2>/dev/null)
REMOTE_VER=$(echo "$MANIFEST" | python3 -c "import sys,json; print(json.load(sys.stdin).get('game_version','0'))" 2>/dev/null)
LOCAL_VER=$(cat "$VERSION_FILE" 2>/dev/null || echo "0")
echo "  Local: $LOCAL_VER  Remote: $REMOTE_VER"

if [ "$LOCAL_VER" = "$REMOTE_VER" ] && [ -f "$GAME_DIR/DarkWorld.app/Contents/MacOS/Dark World" -o -f "$GAME_DIR/DarkWorld.exe" ]; then
    echo "  Game is up to date."
else
    echo "[3/5] Downloading update..."
    PLATFORM="macos"
    if [ "$(uname)" = "MINGW" ] || [ "$(uname)" = "MSYS" ] || [ "$OS" = "Windows_NT" ]; then
        PLATFORM="windows"
    fi
    
    URL=$(echo "$MANIFEST" | python3 -c "import sys,json; [print(f['url']) for f in json.load(sys.stdin)['files'] if f.get('platform')=='$PLATFORM']" 2>/dev/null | head -1)
    SHA=$(echo "$MANIFEST" | python3 -c "import sys,json; [print(f['sha256']) for f in json.load(sys.stdin)['files'] if f.get('platform')=='$PLATFORM']" 2>/dev/null | head -1)
    
    if [ -z "$URL" ]; then echo "  No file for platform $PLATFORM"; exit 1; fi
    
    FULL_URL="https://dark.zorionlabs.net$URL"
    echo "  Downloading: $FULL_URL"
    curl -L -o "$CACHE_DIR/game-download.tar.gz" "$FULL_URL" 2>/dev/null
    
    echo "[4/5] Verifying SHA256..."
    DL_SHA=$(shasum -a 256 "$CACHE_DIR/game-download.tar.gz" 2>/dev/null | awk '{print $1}' || sha256sum "$CACHE_DIR/game-download.tar.gz" 2>/dev/null | awk '{print $1}')
    if [ "$DL_SHA" != "$SHA" ]; then
        echo "  SHA256 mismatch! Expected: $SHA Got: $DL_SHA"
        echo "  Try again or use 'Repair' option."
        exit 1
    fi
    echo "  SHA256 verified."
    
    echo "  Extracting..."
    rm -rf "$GAME_DIR"
    mkdir -p "$GAME_DIR"
    cd "$CACHE_DIR" && tar xzf game-download.tar.gz -C "$GAME_DIR/" 2>/dev/null
    if [ "$PLATFORM" = "windows" ]; then
        cp "$CACHE_DIR/game-download.tar.gz" "$GAME_DIR/"
    fi
    echo "$REMOTE_VER" > "$VERSION_FILE"
    echo "  Update complete."
fi

echo "[5/5] Launching Dark World..."
if [ -f "$GAME_DIR/DarkWorld.app/Contents/MacOS/Dark World" ]; then
    xattr -cr "$GAME_DIR/DarkWorld.app" 2>/dev/null
    open "$GAME_DIR/DarkWorld.app"
elif [ -f "$GAME_DIR/DarkWorld.exe" ]; then
    "$GAME_DIR/DarkWorld.exe"
else
    echo "  Game executable not found. Run repair."
    exit 1
fi
echo "  Launched!"
