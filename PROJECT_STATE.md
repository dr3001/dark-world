# Dark World — Project State

## Status: RPG FOUNDATION ALPHA

## Versao: 0.6.0
## Tag: milestone-rpg-foundation-alpha

## Infraestrutura
| Componente | Status |
|------------|--------|
| VPS (5.78.142.138) | Ativo |
| Godot 4.6.3 | Ativo |
| PostgreSQL 16 | Ativo (3 migrations) |
| Redis 7 | Ativo |
| Nakama 3.31 | Ativo |
| World Engine | Ativo (13 modulos) |
| Export macOS | Funcional |

## World Engine Modules (13)
CharacterStatsModule, ItemModule, InventoryModule, EquipmentModule,
WalletModule, QuestModule, NPCModule, CombatPrepModule,
DeathModule, AfterlifeModule, DragonModule, TerritoryModule,
FactionModule, AuditModule

## API Endpoints (26)
Auth (2), Game (4), Test (2), Events (3), RPG Stats (2),
Inventory (3), Equipment (3), Wallet (2), Items (1),
Quests (2), NPCs (1), Save (1)

## Database Tables (28)
Base: accounts_profile, worlds, entities, entity_components,
characters, territories, factions, kingdoms, wars, deaths,
afterlife_records, dragons, events, event_queue, audit_logs,
admin_actions, system_jobs

RPG Foundation: character_stats, items, inventory, equipment,
wallets, transactions, npc_profiles, npc_memory, quest_data,
quest_progress, save_states

## Godot Client Scripts (20)
World.gd, PlayerController.gd, CameraController.gd,
NetworkClient.gd, CharacterProfile.gd, InventorySystem.gd,
QuestSystem.gd, DragonAI.gd, DragonModel.gd, PlayerModel.gd,
EntitySpawner.gd, WorldState.gd, TerrainBuilder.gd,
Login.gd, Main.gd, Afterlife.gd,
test/DragonTest.gd, test/TestLoader.gd, test/WorldLoader.gd

## Comando de Download
```bash
curl -LO "https://dark.zorionlabs.net/downloads/DarkWorld-Mac-debug.tar.gz?v=0.6.0"
tar xzf DarkWorld-Mac-debug.tar.gz
xattr -cr DarkWorld.app
open DarkWorld.app
```
