#!/bin/bash
# Dark World — Cloudflare DNS Setup
# Este script adiciona o registro dark.zorionlabs.net no Cloudflare
# Requer: Cloudflare Global API Key ou API Token

set -e

ZONE_ID="3e18d1114dd346cb645c7f804024b04b"
RECORD_NAME="dark.zorionlabs.net"
RECORD_TYPE="A"
RECORD_CONTENT="5.78.142.138"
RECORD_TTL=1
RECORD_PROXIED=true

echo "=== Dark World — Cloudflare DNS Setup ==="
echo "Zone: $ZONE_ID"
echo "Record: $RECORD_NAME → $RECORD_CONTENT"
echo ""

# Solicitar credenciais
if [ -z "$CF_API_KEY" ] && [ -z "$CF_API_TOKEN" ]; then
    echo "Metodo 1: API Token (recomendado)"
    echo "  export CF_API_TOKEN='seu-token-aqui'"
    echo ""
    echo "Metodo 2: Global API Key + Email"
    echo "  export CF_API_KEY='sua-global-key'"
    echo "  export CF_EMAIL='Rogeriobeckup@gmail.com'"
    echo ""
    echo "Como obter:"
    echo "  1. Acesse https://dash.cloudflare.com/"
    echo "  2. Va em 'My Profile' → 'API Tokens'"
    echo "  3. Crie um token com permissao 'Zone:DNS:Edit'"
    echo "  4. OU use a Global API Key em 'API Keys'"
    echo ""
    echo "Defina as variaveis de ambiente e execute novamente."
    exit 0
fi

# Construir headers
if [ -n "$CF_API_TOKEN" ]; then
    AUTH_HEADER="Authorization: Bearer $CF_API_TOKEN"
elif [ -n "$CF_API_KEY" ] && [ -n "$CF_EMAIL" ]; then
    AUTH_HEADER="X-Auth-Email: $CF_EMAIL"$'\n'"X-Auth-Key: $CF_API_KEY"
else
    echo "ERRO: Configure CF_API_TOKEN ou CF_API_KEY+CF_EMAIL"
    exit 1
fi

# Verificar se o registro ja existe
echo "Verificando registros existentes..."
EXISTING=$(curl -s -H "$AUTH_HEADER"     "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$RECORD_NAME")

if echo "$EXISTING" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('result',[]))" 2>/dev/null | grep -q .; then
    echo "Registro $RECORD_NAME ja existe. Atualizando..."
    RECORD_ID=$(echo "$EXISTING" | python3 -c "import sys,json; d=json.load(sys.stdin); r=d['result']; print(r[0]['id'] if r else '')")
    RESPONSE=$(curl -s -X PUT -H "$AUTH_HEADER" -H "Content-Type: application/json"         "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID"         --data "{\"type\":\"$RECORD_TYPE\",\"name\":\"$RECORD_NAME\",\"content\":\"$RECORD_CONTENT\",\"ttl\":$RECORD_TTL,\"proxied\":$RECORD_PROXIED}")
else
    echo "Criando novo registro $RECORD_NAME..."
    RESPONSE=$(curl -s -X POST -H "$AUTH_HEADER" -H "Content-Type: application/json"         "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records"         --data "{\"type\":\"$RECORD_TYPE\",\"name\":\"$RECORD_NAME\",\"content\":\"$RECORD_CONTENT\",\"ttl\":$RECORD_TTL,\"proxied\":$RECORD_PROXIED}")
fi

# Verificar resultado
SUCCESS=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',False))")
echo ""
if [ "$SUCCESS" = "True" ]; then
    echo "DNS configurado com sucesso!"
    echo "$RECORD_NAME → $RECORD_CONTENT (proxied=$RECORD_PROXIED)"
    echo "Propagacao DNS pode levar ate 5 minutos."
else
    echo "ERRO ao configurar DNS:"
    echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    exit 1
fi
