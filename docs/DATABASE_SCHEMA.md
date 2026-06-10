# DATABASE SCHEMA — Dark World

## Diagrama de Tabelas

```
worlds ──────────────┐
accounts ────────────┤
players ──┬──────────┤
characters ─┤        │
entities ───┼────────┤
  │          │        │
  ├─ entity_components
  ├─ territories ────┤
  ├─ factions ───────┤
  ├─ kingdoms ───────┤
  ├─ dragons ────────┤
  └─ wars ───────────┤
                      │
events ───────────────┤
event_queue ──────────┤
audit_logs ───────────┤
admin_actions ────────┤
afterlife_records ────┤
deaths ───────────────┤
system_jobs ──────────┘
```

## Tabelas (18)

| # | Tabela | Função |
|---|--------|--------|
| 1 | worlds | Mundos paralelos (vivos, mortos, congelado) |
| 2 | accounts | Contas vinculadas ao Nakama |
| 3 | players | Perfil de jogador |
| 4 | characters | Personagens jogáveis |
| 5 | entities | **Tabela genérica central** (tudo é entidade) |
| 6 | entity_components | Comportamento modular por entidade |
| 7 | territories | Territórios/regiões |
| 8 | factions | Facções |
| 9 | kingdoms | Reinos |
| 10 | wars | Guerras entre facções |
| 11 | deaths | Registro de mortes |
| 12 | afterlife_records | Jornada pós-morte |
| 13 | dragons | Dragões raros |
| 14 | events | Eventos do mundo (append-only) |
| 15 | event_queue | Fila de processamento |
| 16 | audit_logs | Auditoria completa |
| 17 | admin_actions | Ações do painel admin |
| 18 | system_jobs | Jobs agendados |

## Princípios

1. **Entities é genérica** — novos tipos não exigem nova tabela
2. **Components é modular** — comportamento adicionado sem alterar schema
3. **Events é append-only** — histórico completo de tudo que acontece
4. **Audit logs é imutável** — rastreabilidade total
5. **JSONB para flexibilidade** — metadata expansível sem migrations

## Migrations

- `/opt/darkworld/database/migrations/001_initial_schema.sql`
- Executado automaticamente na criação do container PostgreSQL

## Seeds

- `/opt/darkworld/database/seeds/001_seed_worlds.sql`
- 3 mundos, 5 territórios, 3 facções, 1 dragão, 1 admin
