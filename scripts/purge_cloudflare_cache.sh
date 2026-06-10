#!/bin/bash
# Dark World — Cloudflare Cache Purge
# Limpa o cache do Cloudflare para os arquivos de download

set -e

ZONE_ID="3e18d1114dd346cb645c7f804024b04b"
FILES=(
    "https://zorionlabs.net/dark/downloads/DarkWorld-Mac.zip"
    "https://zorionlabs.net/dark/downloads/DarkWorld-Mac-v0.2.0.zip"
    "https://zorionlabs.net/dark/downloads/"
    "https://zorionlabs.net/dark/"
)

echo "=== Dark World — Cloudflare Cache Purge ==="

if [ -z "$CF_API_KEY" ] && [ -z "$CF_API_TOKEN" ]; then
    echo "Configure CF_API_TOKEN ou CF_API_KEY+CF_EMAIL"
    echo "Veja: /opt/darkworld/scripts/setup_cloudflare_dns.sh"
    exit 0
fi

if [ -n "$CF_API_TOKEN" ]; then
    AUTH_HEADER="Authorization: Bearer $CF_API_TOKEN"
elif [ -n "$CF_API_KEY" ] && [ -n "$CF_EMAIL" ]; then
    AUTH_HEADER="X-Auth-Email: $CF_EMAIL"$'\n'"X-Auth-Key: $CF_API_KEY"
fi

# Construir JSON array de arquivos
FILES_JSON="["
for i in "${!FILES[@]}"; do
    if [ $i -gt 0 ]; then FILES_JSON+=","; fi
    FILES_JSON+="\"${FILES[$i]}\""
done
FILES_JSON+="]"

echo "Purging ${#FILES[@]} files..."
RESPONSE=$(curl -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json"     "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache"     --data "{\"files\":$FILES_JSON}")

SUCCESS=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',False))")
if [ "$SUCCESS" = "True" ]; then
    echo "Cache purgado com sucesso!"
else
    echo "ERRO: $RESPONSE"
fi
