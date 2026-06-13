#!/bin/bash
# P0 Foundation audit — 10 pillars automated checks (VPS)
set -euo pipefail

ROOT="/opt/darkworld"
OUT="$ROOT/docs/forensics/FOUNDATION_AUDIT_OUTPUT.txt"
API="https://dark.zorionlabs.net/dw-api"
CDN="https://dark.zorionlabs.net"
mkdir -p "$ROOT/docs/forensics"

pass=0
fail=0
warn=0

log() { echo "$1" | tee -a "$OUT"; }
ok() { log "PASS: $1"; pass=$((pass+1)); }
bad() { log "FAIL: $1"; fail=$((fail+1)); }
maybe() { log "WARN: $1"; warn=$((warn+1)); }

: > "$OUT"
log "=== DARK WORLD FOUNDATION AUDIT ==="
log "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
log ""

# PILAR 1 — Launcher
if [ -f "$ROOT/build/launcher/DarkWorld-Launcher.exe" ]; then
  SZ=$(stat -c%s "$ROOT/build/launcher/DarkWorld-Launcher.exe")
  if [ "$SZ" -gt 1000000 ] && ! strings "$ROOT/build/launcher/DarkWorld-Launcher.exe" 2>/dev/null | grep -qi node_modules; then
    ok "P1 Launcher: local Tauri exe ($SZ bytes)"
  else
    bad "P1 Launcher: invalid local exe"
  fi
else
  maybe "P1 Launcher: no local exe — CDN may still serve 1.0.0"
fi
if curl -sfI "$CDN/downloads/DarkWorld-Launcher-Setup.exe" | grep -qi '200\|301'; then
  ok "P1 Launcher: setup URL reachable"
else
  bad "P1 Launcher: setup URL unreachable"
fi

# PILAR 2 — Update manifest
if curl -sf "$CDN/downloads/launcher/manifest.json" | python3 -c "import sys,json; m=json.load(sys.stdin); assert m.get('game_version'); assert len(m.get('files',[]))>=1"; then
  GV=$(curl -sf "$CDN/downloads/launcher/manifest.json" | python3 -c "import sys,json; print(json.load(sys.stdin)['game_version'])")
  ok "P2 Update: manifest valid (game $GV)"
else
  bad "P2 Update: manifest invalid"
fi

# PILAR 3 — Login API
CODE=$(curl -so /dev/null -w '%{http_code}' -X POST "$API/auth/login" -H 'Content-Type: application/json' -d '{"email":"audit@test.local","password":"wrong"}')
[ "$CODE" = "401" ] || [ "$CODE" = "400" ] && ok "P3 Login: API responds ($CODE)" || bad "P3 Login: unexpected $CODE"

# PILAR 4 — Register API
CODE=$(curl -so /dev/null -w '%{http_code}' -X POST "$API/auth/register-email" -H 'Content-Type: application/json' -d '{}')
[ "$CODE" = "400" ] && ok "P4 Register: API validates input" || maybe "P4 Register: HTTP $CODE"

# PILAR 5 — Forgot password
[ -f /var/www/zorionlabs/dark/forgot-password/index.html ] && ok "P5 Forgot: portal page exists" || bad "P5 Forgot: portal page missing"
CODE=$(curl -so /dev/null -w '%{http_code}' -X POST "$API/auth/reset-password" -H 'Content-Type: application/json' -d '{"email":"audit@test.local"}')
[ "$CODE" = "200" ] && ok "P5 Forgot: API responds" || bad "P5 Forgot: API $CODE"

# PILAR 6 — Download
ZIP_HASH=$(curl -sf "$CDN/downloads/launcher/manifest.json" | python3 -c "import sys,json; f=[x for x in json.load(sys.stdin)['files'] if 'Windows-portable' in x['path']][0]; print(f['sha256'][:16])")
curl -sf "$CDN/downloads/DarkWorld-Windows-portable.zip" -o /tmp/dw-audit.zip
LOCAL=$(sha256sum /tmp/dw-audit.zip | awk '{print $1}')
REMOTE=$(curl -sf "$CDN/downloads/launcher/manifest.json" | python3 -c "import sys,json; f=[x for x in json.load(sys.stdin)['files'] if 'Windows-portable' in x['path']][0]; print(f['sha256'])")
[ "$LOCAL" = "$REMOTE" ] && ok "P6 Download: zip hash matches manifest ($ZIP_HASH...)" || bad "P6 Download: hash mismatch"

# PILAR 7 — Install (NSIS script exists)
[ -f "$ROOT/scripts/darkworld-launcher.nsi" ] && ok "P7 Install: NSIS script present" || bad "P7 Install: NSIS missing"

# PILAR 8 — Uninstall (NSIS uninstall section)
grep -q "Uninstall" "$ROOT/scripts/darkworld-launcher.nsi" 2>/dev/null && ok "P8 Uninstall: NSIS uninstall section" || maybe "P8 Uninstall: verify manually"

# PILAR 9 — Game init (release export)
bash "$ROOT/scripts/audit-world-load.sh" >> "$OUT" 2>&1 && ok "P9 Init: Godot release export OK" || bad "P9 Init: export failed"

# PILAR 10 — World load (code audit)
grep -q "_build_castle\|_spawn_npcs\|_build_village" "$ROOT/godot-client/scripts/World.gd" && ok "P10 World: procedural builders present" || bad "P10 World: builders missing"

log ""
log "=== SUMMARY ==="
log "PASS: $pass  FAIL: $fail  WARN: $warn"
[ "$fail" -eq 0 ] && exit 0 || exit 1
