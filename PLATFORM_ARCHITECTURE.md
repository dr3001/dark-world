# Dark World — Platform Architecture

## Camadas
```
[Godot Client] → HTTP → [World Engine API] → [PostgreSQL + Redis]
[Landing Page] → HTTP → [World Engine API] → [Stripe Webhook]
[Admin Panel]  → HTTP → [World Engine API] → [Moderation + Audit]
```

## Modules (24 total)
Core: Death, Afterlife, Dragon, Territory, Faction, Audit
RPG: CharacterStats, Item, Inventory, Equipment, Wallet, Quest, NPC, CombatPrep, Loot
Platform: VIP, Store, Chat, Clan, Ranking, Admin, Event, AIProvider

## Database: 62 tabelas (29 base + 33 gamma)
## API: 60+ endpoints
## Moeda: ZORIUM (Z)
## Auth: Nakama 3.31
## AI: OpenAI/DeepSeek compatible (env-based)
