# Dark World — RPG Architecture

## Camadas

```
[Godot Client] → HTTP → [World Engine API] → [PostgreSQL + Redis]
     ↕                        ↕
  GDScript               TypeScript
  Scenes/UI            Modules + Events
```

## World Engine Modules

| Modulo | Arquivo | Responsabilidade |
|--------|---------|-----------------|
| CharacterStatsModule | modules/character/ | Stats, XP, level up |
| ItemModule | modules/item/ | Definicoes de itens |
| InventoryModule | modules/inventory/ | CRUD inventario (20 slots) |
| EquipmentModule | modules/equipment/ | Equipar/desequipar, bonus stats |
| WalletModule | modules/economy/ | Zorium, transacoes |
| QuestModule | modules/quest/ | Accept/complete quests |
| NPCModule | modules/npc/ | Perfis, memoria, AI prep |
| CombatPrepModule | modules/combat/ | Interfaces de combate (stub) |
| DeathModule | modules/death/ | Morte e afterlife |
| DragonModule | modules/dragon/ | Dragoes |
| TerritoryModule | modules/territory/ | Territorios |
| FactionModule | modules/faction/ | Faccoes |
| AuditModule | modules/audit/ | Audit trail |

## Padroes

- Cada modulo extends `WorldEngineModule`
- Lifecycle: `initialize()` → `onTick()` → `shutdown()`
- Dados persistidos em PostgreSQL via `query()`
- Eventos via tabela `events` + `event_queue`
- Tipos centralizados em `core/types.ts` e `core/rpg-types.ts`

## API

- Router customizado (sem Express/Fastify)
- Regex matching em `api.ts`
- JSON responses com CORS
- ~26 endpoints ativos
