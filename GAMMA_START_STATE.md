# Dark World — Gamma Start State

## Commit: b4d7a0d
## Branch: main
## Build: DarkWorld-Mac-debug.tar.gz (90MB)
## Tag: milestone-rpg-foundation-gamma-start

## Sistemas Existentes
- 29 tabelas PostgreSQL (accounts, characters, entities, items, inventory, equipment, wallets, transactions, quests, NPCs, loot, save_states, etc.)
- 15 world-engine modules ativos
- 30+ API endpoints respondendo
- Godot client: movimento, camera, colisoes, NPCs, dialogo, inventario, equipamento, quest journal, save system
- Export macOS funcional (Godot 4.6.3 --export-debug)
- Docker: PostgreSQL 16, Redis 7, Nakama 3.31, World Engine 0.7.1

## Riscos Conhecidos
- NPC memory usa npc_name como entity_id (falha FK silenciosamente)
- Forge e heal sao client+server hibridos
- Chat nao existe
- VIP nao existe
- Loja nao existe
- Stripe nao existe
- Admin panel nao existe
- Ranking nao existe
- Eventos nao existem
- Clans nao existem
