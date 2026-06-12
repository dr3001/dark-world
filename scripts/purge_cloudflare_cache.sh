#!/bin/bash
# Dark World — Cloudflare Cache Purge (launcher + downloads)
set -euo pipefail

ZONE_ID="${CF_ZONE_ID:-3e18d1114dd346cb645c7f804024b04b}"
BASE="https://dark.zorionlabs.net"

FILES=(
  "$BASE/downloads/DarkWorld-Launcher-Setup.exe"
  "$BASE/downloads/DarkWorld-Launcher.exe"
  "$BASE/downloads/DarkWorld-Launcher-mac.tar.gz"
  "$BASE/downloads/DarkWorld-Windows-portable.zip"
  "$BASE/downloads/DarkWorld-Mac-debug.tar.gz"
  "$BASE/downloads/launcher/manifest.json"
  "$BASE/downloads/"
  "$BASE/"
)

echo "=== Dark World — Cloudflare Cache Purge ==="

if [ -z "${CF_API_TOKEN:-}" ] && [ -z "${CF_API_KEY:-}" ]; then
  echo "ERROR: CF_API_TOKEN not set — Cloudflare still serving stale cache."
  echo "  export CF_API_TOKEN='...' && bash $0"
  echo "  Or purge manually: Cloudflare Dashboard → Caching → Purge Everything"
  exit 1
fi

if [ -n "${CF_API_TOKEN:-}" ]; then
  AUTH=(-H "Authorization: Bearer $CF_API_TOKEN")
elif [ -n "${CF_API_KEY:-}" ] && [ -n "${CF_EMAIL:-}" ]; then
  AUTH=(-H "X-Auth-Email: $CF_EMAIL" -H "X-Auth-Key: $CF_API_KEY")
else
  echo "ERROR: Set CF_API_TOKEN or CF_API_KEY+CF_EMAIL"
  exit 1
fi

FILES_JSON=$(python3 -c "import json,sys; print(json.dumps(sys.argv[1:]))" "${FILES[@]}")

echo "Purging ${#FILES[@]} URLs..."
RESPONSE=$(curl -s -X POST "${AUTH[@]}" -H "Content-Type: application/json" \
  "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
  --data "{\"files\":$FILES_JSON}")

SUCCESS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success',False))")
if [ "$SUCCESS" = "True" ]; then
  echo "Cache purgado com sucesso."
else
  echo "Purge by URL failed, trying purge_everything..."
  RESPONSE=$(curl -s -X POST "${AUTH[@]}" -H "Content-Type: application/json" \
    "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
    --data '{"purge_everything":true}')
  SUCCESS=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('success',False))")
  if [ "$SUCCESS" = "True" ]; then
    echo "purge_everything OK."
  else
    echo "ERRO: $RESPONSE"
    exit 1
  fi
fi

echo "Verificando URL pública..."
sleep 3
curl -sSIL "$BASE/downloads/DarkWorld-Launcher-Setup.exe" | grep -iE 'content-length|cf-cache-status|last-modified' || true
