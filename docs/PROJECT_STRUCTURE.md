# PROJECT STRUCTURE — Dark World

```
/opt/darkworld/
├── docs/                    Documentação completa do projeto
│   ├── SERVER_AUDIT.md
│   ├── PROJECT_STRUCTURE.md
│   ├── BASE_INSTALLATION.md
│   ├── FIREWALL.md
│   ├── DOCKER_SETUP.md
│   ├── POSTGRES_SETUP.md
│   ├── REDIS_SETUP.md
│   ├── NAKAMA_SETUP.md
│   ├── WORLD_ENGINE_ARCHITECTURE.md
│   ├── ENTITY_SYSTEM.md
│   ├── EVENT_ENGINE.md
│   ├── DATABASE_SCHEMA.md
│   ├── BACKUP_STRATEGY.md
│   ├── MONITORING.md
│   ├── ARCHITECTURE.md
│   ├── ROADMAP.md
│   ├── DECISIONS.md
│   └── MVP_SCOPE.md
│
├── backups/                 Backups do PostgreSQL
├── logs/                    Logs dos serviços
│
├── database/                Schema e migrations
│   ├── migrations/          Arquivos SQL versionados
│   └── seeds/               Dados iniciais de teste
│
├── docker/                  Configurações Docker por serviço
│   ├── postgres/
│   ├── redis/
│   ├── nakama/
│   └── nginx/
│
├── world-engine/            Motor do mundo (Node.js/TypeScript)
│   ├── src/
│   │   ├── core/            Engine loop, configuração
│   │   ├── entities/        Entity System
│   │   ├── events/          Event Engine
│   │   └── modules/         Módulos expansíveis
│   ├── tests/
│   ├── Dockerfile
│   └── package.json
│
├── admin-panel/             Painel administrativo (placeholder)
├── godot-client/            Cliente Godot (placeholder)
├── assets/                  Assets do jogo
├── assets-manifest/         Catálogo de assets comprados
│
├── monitoring/              Monitoramento
│   ├── prometheus/
│   └── grafana/
│
├── scripts/                 Scripts operacionais
│   ├── install.sh
│   ├── backup.sh
│   └── seed.sh
│
├── docker-compose.yml       Orquestração principal
├── .env                     Variáveis de ambiente (não versionado)
└── .env.example             Template de variáveis
```

## Princípios
1. Cada serviço em container isolado
2. Dados persistentes em volumes Docker nomeados
3. Rede interna `darkworld-net` para comunicação entre serviços
4. Zero conflito com /opt/zorion (produção existente)
5. Todo estado do jogo no PostgreSQL
6. Toda ação como evento auditável
