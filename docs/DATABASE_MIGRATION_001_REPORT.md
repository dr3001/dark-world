# DATABASE MIGRATION 001 REPORT — Mission 2

**Data:** 2026-06-10
**Migration:** 002_mission2_schema.sql
**Banco:** darkworld (PostgreSQL 16)

---

## Tabelas Criadas (17)

| # | Tabela | Colunas | Chave |
|---|--------|---------|-------|
| 1 | accounts_profile | id, nakama_user_id, display_name, email, is_admin, metadata, created_at, updated_at | PK: id |
| 2 | worlds | id, slug (UNIQUE), name, world_type, description, state (JSONB), created_at, updated_at | PK: id |
| 3 | entities | id, world_id (FK), entity_type, name, owner_account_id, position_x/y/z, status, state (JSONB), metadata (JSONB), created_at, updated_at, deleted_at | PK: id |
| 4 | entity_components | id, entity_id (FK CASCADE), component_type, data (JSONB), created_at, updated_at | PK: id |
| 5 | events | id, event_type, source_entity_id (FK), target_entity_id (FK), world_id (FK), payload (JSONB), status, created_by, created_at, processed_at, error | PK: id |
| 6 | event_queue | id, event_id (FK CASCADE), priority, available_at, attempts, locked_at, locked_by, created_at | PK: id |
| 7 | audit_logs | id, actor_type, actor_id, action, target_type, target_id, payload (JSONB), created_at | PK: id |
| 8 | characters | id, account_id (FK), entity_id (FK), character_name, character_role, life_state, mirror_character_id, created_at, updated_at | PK: id |
| 9 | territories | id, entity_id (FK), world_id (FK), name, controlled_by_faction_id, danger_level, state (JSONB), created_at, updated_at | PK: id |
| 10 | factions | id, entity_id (FK), name, faction_type, leader_account_id, member_count, state (JSONB), created_at, updated_at | PK: id |
| 11 | kingdoms | id, entity_id (FK), name, ruler_character_id, faction_id, state (JSONB), created_at, updated_at | PK: id |
| 12 | wars | id, attacker_faction_id, defender_faction_id, status, reason, state (JSONB), started_at, ended_at | PK: id |
| 13 | afterlife_records | id, character_id (FK), death_event_id (FK), from_world_id (FK), afterlife_world_id (FK), entered_at, eligible_return_at, returned_at, state (JSONB) | PK: id |
| 14 | dragons | id, entity_id (FK CASCADE), dragon_name, dragon_type, threat_level, territory_id, spawn_world_id, is_alive, state (JSONB), created_at, updated_at | PK: id |
| 15 | system_jobs | id, job_type, status, payload (JSONB), scheduled_at, started_at, finished_at, error | PK: id |
| 16 | admin_actions | id, admin_id, action, payload (JSONB), created_at | PK: id |
| 17 | deaths | id, character_id (FK), killed_by_entity_id (FK), world_id (FK), death_location (JSONB), died_at | PK: id |

## Índices Criados (10)

| Índice | Tabela | Coluna |
|--------|--------|--------|
| idx_events_type | events | event_type |
| idx_events_status | events | status |
| idx_entities_type | entities | entity_type |
| idx_entities_world | entities | world_id |
| idx_entity_components_entity | entity_components | entity_id |
| idx_entity_components_type | entity_components | component_type |
| idx_characters_account | characters | account_id |
| idx_territories_world | territories | world_id |
| idx_audit_logs_action | audit_logs | action |
| idx_event_queue_available | event_queue | available_at |

## Comando de Aplicação

```bash
cat /opt/darkworld/database/migrations/002_mission2_schema.sql | \
  docker exec -i darkworld-postgres psql -U darkworld_admin -d darkworld
```

## Validação

```sql
SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';
-- Resultado: 17
```

## Conclusão

Migração aplicada com sucesso. 17 tabelas, 10 índices. Schema alinhado com a especificação da Missão 2. Sem erros.
