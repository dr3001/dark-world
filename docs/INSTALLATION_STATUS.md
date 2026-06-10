# INSTALLATION STATUS — Dark World

**Data:** 2026-06-10
**Servidor:** Hetzner CCX23 (5.78.142.138)
**Status:** FUNDAÇÃO CONCLUÍDA

---

## Serviços em Execução

| Serviço | Container | Porta Host | Status |
|---------|-----------|------------|--------|
| PostgreSQL 16 | darkworld-postgres | 5433 | Healthy |
| Redis 7 | darkworld-redis | 6380 | Healthy |
| Nakama 3.31 | darkworld-nakama | 7350/7351 | Healthy |
| World Engine | (placeholder) | 9000 | Build pronto |

## Bancos de Dados

| Database | Tabelas | Seeds |
|----------|---------|-------|
| darkworld | 18 tabelas | 3 mundos, 5 territórios, 3 facções, 1 dragão |
| darkworld_nakama | Automático (Nakama) | Nakama auto-migrate |

## Documentação Gerada (15 arquivos)

| # | Documento | Status |
|---|-----------|--------|
| 1 | SERVER_AUDIT.md | Pronto |
| 2 | PROJECT_STRUCTURE.md | Pronto |
| 3 | BASE_INSTALLATION.md | Pronto |
| 4 | FIREWALL.md | Pronto |
| 5 | DOCKER_SETUP.md | Pronto |
| 6 | POSTGRES_SETUP.md | Pronto |
| 7 | REDIS_SETUP.md | Pronto |
| 8 | NAKAMA_SETUP.md | Pronto |
| 9 | WORLD_ENGINE_ARCHITECTURE.md | Pronto |
| 10 | ENTITY_SYSTEM.md | Pronto |
| 11 | EVENT_ENGINE.md | Pronto |
| 12 | DATABASE_SCHEMA.md | Pronto |
| 13 | BACKUP_STRATEGY.md | Pronto |
| 14 | MONITORING.md | Pronto |
| 15 | ARCHITECTURE.md | Pronto |
| 16 | ROADMAP.md | Pronto |
| 17 | DECISIONS.md | Pronto |
| 18 | MVP_SCOPE.md | Pronto |
| 19 | INSTALLATION_STATUS.md | Pronto |

## Scripts

| Script | Função |
|--------|--------|
| /opt/darkworld/scripts/backup.sh | Backup diário PostgreSQL |
| /opt/darkworld/scripts/seed.sh | Aplicar dados de seed |

## Crontab

```
0 4 * * * /opt/darkworld/scripts/backup.sh
```

## O que foi validado

- [x] Docker operacional
- [x] PostgreSQL aceita conexões (porta 5433)
- [x] Redis responde PING (porta 6380)
- [x] Nakama iniciou e migrou banco
- [x] Schema SQL aplicado (18 tabelas)
- [x] Seeds aplicados (mundos, territórios, facções)
- [x] Backup script criado e agendado
- [x] Documentação completa gerada
- [x] Sem conflito com Zorion (produção)

## O que ainda é placeholder

- World Engine: estrutura pronta, lógica pendente
- Admin Panel: estrutura de pastas apenas
- Godot Client: estrutura de pastas apenas
- Prometheus/Grafana: config básico, dashboards pendentes

## Próximos Passos (Fase 1)

1. Implementar World Engine (loop + eventos)
2. Conectar Entity System ao PostgreSQL
3. Implementar Event Engine com fila Redis
4. Criar DeathModule e AfterlifeModule
5. Testar fluxo de morte/retorno

## Capacidade Estimada

- **Discos:** 131GB livres
- **RAM:** ~10GB livres (após serviços)
- **CPU:** 4 cores, baixa utilização
- **Banco:** PostgreSQL 16 otimizado para JSONB
- **Cache:** Redis 7 com 256MB
- **Rede:** Nakama pronto para WebSocket multiplayer
