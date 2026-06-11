# DARK WORLD — LEIA AQUI, CURSOR

## ÚLTIMA ATUALIZAÇÃO: 2026-06-12
## VERSÃO ATUAL: 5.0.5
## SERVIDOR: Hetzner VPS — 5.78.142.138

============================================================
ESTRUTURA DO PROJETO
============================================================

/opt/darkworld/
├── godot-client/          # Projeto Godot 4.6.3
│   ├── project.godot
│   ├── export_presets.cfg
│   ├── scenes/
│   │   ├── World.tscn      # Cena principal do mundo
│   │   ├── Login.tscn      # Tela de login
│   │   └── Main.tscn       # Controlador principal
│   └── scripts/
│       ├── Main.gd          # Lógica de login + version check
│       ├── World.gd         # Geração procedural do mundo (849 linhas)
│       ├── PlayerController.gd  # Movimento + combate
│       ├── CombatSystem.gd     # Sistema de combate
│       ├── NetworkClient.gd    # Conexão com API
│       └── ... (40 scripts)
├── world-engine/           # Backend Node.js + TypeScript
│   ├── src/
│   │   ├── api.ts          # 160+ endpoints (linha principal)
│   │   ├── index.ts        # Registro de módulos
│   │   └── modules/        # 42 módulos
│   ├── Dockerfile
│   └── package.json
├── database/
│   └── migrations/         # 14 migrations (001-014)
├── scripts/
│   ├── publish-release.sh  # Pipeline UNIFICADO (le version.json)
│   ├── publish-mac-debug.sh
│   ├── publish-windows.sh
│   ├── darkworld.nsi       # NSIS installer script
│   └── darkworld-launcher.sh/.bat  # Scripts auxiliares
├── docker-compose.yml
├── version.json            # SINGLE SOURCE OF TRUTH para versão
├── .env                    # Chaves de API (Brevo, DeepSeek)
├── dark-world-launcher/    # Launcher Node.js MVP
│   └── launcher.js
├── openapi/
│   └── public-api-v1.yaml
├── sdk/
│   └── darkworld.js
├── build/                  # Builds gerados
│   ├── windows/DarkWorld.exe
│   ├── DarkWorld.app/
│   ├── DarkWorld-Setup.exe
│   ├── DarkWorld-Windows-portable.zip
│   └── DarkWorld-Mac-debug.tar.gz
└── downloads -> /var/www/zorionlabs/dark/downloads/

/var/www/zorionlabs/dark/   # Servido via Nginx + Cloudflare
├── index.html              # Portal principal
├── register/index.html     # Página de registro
├── login/index.html        # Página de login
├── downloads/index.html    # Página de downloads
├── terms/index.html        # Termos de uso
├── privacy/index.html      # Privacidade
├── forum/index.html        # Fórum
├── tickets/index.html      # Tickets
├── downloads/              # Arquivos de download
│   ├── DarkWorld-Windows-Setup.exe
│   ├── DarkWorld-Windows-portable.zip
│   ├── DarkWorld-Mac-debug.tar.gz
│   └── launcher/manifest.json
└── evidence/               # Evidências de auditoria

============================================================
SERVIDOR — DOCKER CONTAINERS
============================================================

docker ps:
  darkworld-world-engine  (porta 9000)  — API do jogo
  darkworld-postgres      (porta 5433)  — PostgreSQL 16
  darkworld-redis         (porta 6380)  — Redis 7
  darkworld-nakama        (porta 7350)  — Nakama auth

Comandos úteis:
  docker logs darkworld-world-engine
  docker exec darkworld-postgres psql -U darkworld_admin -d darkworld
  docker restart darkworld-world-engine

============================================================
CHAVES DE API CONFIGURADAS
============================================================

Arquivo: /opt/darkworld/.env

BREVO_API_KEY=(configurada no .env do VPS)
BREVO_SENDER=noreply@zorionlabs.net
BREVO_SENDER_NAME=Dark World

AI_PROVIDER=deepseek
AI_ENDPOINT=https://api.deepseek.com/v1
AI_MODEL=deepseek-chat
AI_API_KEY=(configurada no .env do VPS)

DB_PASSWORD=(configurado no .env)
REDIS_PASSWORD=(configurado no .env)

============================================================
COMO PUBLICAR NOVA VERSÃO (ÚNICO COMANDO)
============================================================

1. Editar /opt/darkworld/version.json e mudar game_version
2. Rodar: bash /opt/darkworld/scripts/publish-release.sh

O pipeline automaticamente:
  - Atualiza Main.gd LOCAL_VERSION
  - Atualiza api.ts game_version
  - Atualiza portal HTML versão
  - Exporta Windows + macOS
  - Gera NSIS installer
  - Gera manifest com SHA256
  - Publica nos downloads
  - Valida todos os arquivos

NÃO editar versão manualmente em Main.gd, api.ts ou HTML.
SEMPRE usar o pipeline.

============================================================
ESTADO DO LAUNCHER — NOTA 82/100
============================================================

20 REQUISITOS DO SUPER LAUNCHER:

✅ COMPLETO (17/20):
1.  Launcher separado: Node.js MVP + Main.gd pre-flight check
2.  Atalho abre jogo com verificação: NSIS com ícone desktop
3.  Consulta manifest remoto: Main.gd._check_version()
4.  Lê versão local: LOCAL_VERSION + version.json no instalador
5.  Compara versões: remote != LOCAL_VERSION
6.  Backend version gate: GET /api/launcher/version
7.  Bloqueia login desatualizado: enter_btn.disabled = true
8.  Bloqueia sem consulta: Conecte-se a internet
9.  Baixa pacote automaticamente: Download automático implementado
10. Valida SHA256: FileAccess.get_sha256()
12. Logs no servidor: 8 eventos de telemetria
13. Mostra status ao usuário
14. Mostra erro claro
15. Changelog na downloads page
16. Login só após verificação
17. Sem bypass (else: create_account removido)
18. Telemetria integrada (8 eventos)
19. Device ID (_register_device)
20. Eventos no servidor (telemetria endpoints)

⚠️ PARCIAL (2/20):
11. Aplica update no disco: Download + SHA256 ok, mas NÃO extrai/sobrescreve 
    arquivos no disco. Godot não tem API nativa para extrair .tar.gz no Windows.

❌ NÃO IMPLEMENTADO (1/20):
-   Launcher standalone .exe: O Node.js launcher (launcher.js) não foi 
    empacotado como .exe com pkg/nexe. O entry point ainda é o Godot client.

============================================================
O QUE FOI PEDIDO vs O QUE FOI FEITO (ÚLTIMOS 10 PLANOS)
============================================================

1. COMBAT VFX FOUNDATION → FEITO: 13 scripts de VFX, Mestre de Armas, teclas 1-0
2. DAMAGE + SHIELD + SKILLS + PVP → FEITO: dano real, escudo, Q/R/T skills
3. WINDOWS BUILD → FEITO: installer NSIS 58MB, portable ZIP 59MB
4. LANDING + REGISTER + LOGIN → FEITO: 8 páginas web HTTP 200, HTTPS proxy
5. WORLD SIMULATION → FEITO: dia/noite, clima, estações, WorldSimulationModule
6. ZERO TRUST SECURITY → FEITO: device fingerprint, trust engine, fraud engine, anti-cheat
7. LORE ENGINE → FEITO: 20 tabelas, biographies, timelines, clan/kingdom lore
8. GOVERNANCE → FEITO: termos, privacidade, KYC, fórum, tickets, violações
9. SUPER LAUNCHER → 82% (17/20 requisitos)
10. SINGLE SOURCE VERSION → FEITO: version.json pipeline auto-sync

============================================================
O QUE NÃO FOI FEITO (HONESTIDADE)
============================================================

1. Launcher standalone .exe: launcher.js existe mas não foi empacotado
2. Extração de .tar.gz no Windows: Godot não tem API nativa
3. GUI do launcher: não tem interface gráfica separada
4. Auto-aplicação de update no disco: download ok, extração pendente
5. Combate PvE real: sistema existe mas dragão não usa DragonAI
6. OpenAPI spec completa: esqueleto criado, não completo
7. Rate limit global na API: existe por endpoint mas não global

============================================================
BANCO DE DADOS — PostgreSQL
============================================================

152 tabelas, 42 módulos, 160+ endpoints
Zorium desyncs: 0 (verificado regularmente)

Tabelas principais:
- accounts_profile (46 usuários)
- characters (40 personagens)
- character_stats, wallets, inventory, equipment
- clans, clan_members
- chat_messages, chat_translations
- vip_levels (20 níveis)
- hero_classes (10 classes)
- skill_definitions (6 skills)
- territory_map (5 territórios)
- game_events (7 eventos)
- forum_categories (8), forum_threads, forum_posts
- tickets, ticket_messages
- terms_acceptance, violation_catalog
- trust_profiles, fraud_events, anti_cheat_events
- device_profiles, launcher_logs
- E muitos outros...

Usuário OWNER: rogeriobeckup@gmail.com (role=owner, vip=20)

============================================================
URLS IMPORTANTES
============================================================

Portal:         https://dark.zorionlabs.net/
Registro:       https://dark.zorionlabs.net/register/
Login:          https://dark.zorionlabs.net/login/
Downloads:      https://dark.zorionlabs.net/downloads/
Termos:         https://dark.zorionlabs.net/terms/
Privacidade:    https://dark.zorionlabs.net/privacy/
Fórum:          https://dark.zorionlabs.net/forum/
Tickets:        https://dark.zorionlabs.net/tickets/

Windows Installer:  https://dark.zorionlabs.net/downloads/DarkWorld-Windows-Setup.exe
Windows Portable:   https://dark.zorionlabs.net/downloads/DarkWorld-Windows-portable.zip
macOS:              https://dark.zorionlabs.net/downloads/DarkWorld-Mac-debug.tar.gz
Manifest JSON:      https://dark.zorionlabs.net/downloads/launcher/manifest.json

API Health:     http://5.78.142.138:9000/health
API Manifest:   http://5.78.142.138:9000/api/launcher/manifest
API Version:    http://5.78.142.138:9000/api/launcher/version

============================================================
REPOSITÓRIO GIT
============================================================

GitHub: https://github.com/dr3001/dark-world
Branch: main
Último commit: 752cd71
Última tag: milestone-single-source-version

============================================================
PARA CONTINUAR O DESENVOLVIMENTO
============================================================

1. Clone o repositório: git clone https://github.com/dr3001/dark-world.git
2. O VPS está em 5.78.142.138
3. Chaves SSH estão configuradas para root
4. Godot 4.6.3 está em /opt/godot/godot_4.6.3/
5. Node.js + TypeScript no world-engine
6. Docker + docker-compose para os serviços

PRÓXIMOS PASSOS RECOMENDADOS:
- Empacotar launcher Node.js como .exe standalone (pkg ou nexe)
- Implementar extração de .tar.gz no Windows (usar Node.js launcher)
- Ativar DragonAI no dragão Vorak
- Completar OpenAPI spec
- Adicionar rate limit global
- Testar multiplayer visual real (não apenas REST polling)
