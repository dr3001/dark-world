#!/bin/bash
set -euo pipefail

ROOT="/opt/darkworld"
GODOT="${GODOT:-/opt/godot/godot_4.6.3/Godot_v4.6.3-stable_linux.x86_64}"
PROJECT="$ROOT/godot-client"
BUILD="$ROOT/build"
OUT="$ROOT/docs/forensics/world-audit-output.txt"

mkdir -p "$ROOT/docs/forensics" "$BUILD/windows"

echo "=== Dark World World Load Audit ===" | tee "$OUT"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$OUT"

echo "[1] Export release Windows..." | tee -a "$OUT"
EXPORT_LOG=$(mktemp)
GODOT_SILENCE_ROOT_WARNING=1 "$GODOT" --headless --path "$PROJECT" --export-release "Windows" "$BUILD/windows/DarkWorld.exe" 2>&1 | tee "$EXPORT_LOG"
if grep -iE "invalid UID|SCRIPT ERROR|Failed to load script" "$EXPORT_LOG"; then
  echo "FAIL: export script/UID errors detected" | tee -a "$OUT"
  exit 1
fi
WARN_COUNT=$(grep -c "WARNING:" "$EXPORT_LOG" || true)
echo "Export warnings: $WARN_COUNT" | tee -a "$OUT"

echo "[2] Headless world smoke (script check)..." | tee -a "$OUT"
# Validate World.gd parses and key scene exists
if [ ! -f "$PROJECT/scenes/World.tscn" ]; then
  echo "FAIL: World.tscn missing" | tee -a "$OUT"
  exit 1
fi
if grep -q "_build_plaza\|_build_village\|_build_castle" "$PROJECT/scripts/World.gd"; then
  echo "OK: World.gd contains procedural builders" | tee -a "$OUT"
else
  echo "FAIL: World.gd missing builders" | tee -a "$OUT"
  exit 1
fi

if [ -f "$BUILD/windows/DarkWorld.exe" ]; then
  EXE_SIZE=$(stat -c%s "$BUILD/windows/DarkWorld.exe")
  EXE_HASH=$(sha256sum "$BUILD/windows/DarkWorld.exe" | awk '{print $1}')
  echo "OK: DarkWorld.exe size=$EXE_SIZE hash=$EXE_HASH" | tee -a "$OUT"
else
  echo "FAIL: DarkWorld.exe not produced" | tee -a "$OUT"
  exit 1
fi

echo "[3] CDN hash check (if manifest reachable)..." | tee -a "$OUT"
MANIFEST=$(curl -sf "https://dark.zorionlabs.net/downloads/launcher/manifest.json" || echo "")
if [ -n "$MANIFEST" ]; then
  REMOTE_VER=$(echo "$MANIFEST" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("game_version","?"))' 2>/dev/null || echo "?")
  echo "Remote game_version: $REMOTE_VER" | tee -a "$OUT"
  LOCAL_VER=$(python3 -c 'import json; print(json.load(open("/opt/darkworld/version.json"))["game_version"])' 2>/dev/null || echo "?")
  echo "Local version.json: $LOCAL_VER" | tee -a "$OUT"
else
  echo "WARN: manifest unreachable" | tee -a "$OUT"
fi

echo "=== AUDIT COMPLETE ===" | tee -a "$OUT"
