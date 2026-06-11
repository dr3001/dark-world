# Dark World — Database Model

## PostgreSQL 16 — Tabelas

### Migration 001-002 (base)
| Tabela | Descricao |
|--------|-----------|
| accounts_profile | Contas de usuario |
| worlds | Mundos/dimensoes |
| entities | Entidades genericas (position 3D, state, metadata) |
| entity_components | Componentes ECS |
| characters | Personagens (FK account, FK entity) |
| territories | Territorios com danger_level |
| factions | Faccoes |
| kingdoms | Reinos |
| wars | Guerras entre faccoes |
| deaths | Registro de mortes |
| afterlife_records | Registros de afterlife |
| dragons | Dragoes (FK entity) |
| events | Sistema de eventos |
| event_queue | Fila de processamento |
| audit_logs | Trail de auditoria |
| admin_actions | Acoes administrativas |
| system_jobs | Jobs agendados |

### Migration 003 (RPG Foundation)
| Tabela | Descricao | FK |
|--------|-----------|-----|
| character_stats | HP, MANA, LEVEL, XP, ZORIUM, 6 atributos | characters |
| items | Definicoes de itens (weapon, armor, consumable, quest_item, accessory, material) | — |
| inventory | Slots de inventario (max 20) | characters, items |
| equipment | Itens equipados (7 slots: weapon, helmet, chest, gloves, boots, ring, amulet) | characters, items |
| wallets | Saldo Zorium por personagem | characters |
| transactions | Log de transacoes | wallets |
| npc_profiles | Perfil de NPC (role, personality, knowledge, AI config) | entities |
| npc_memory | Memorias de NPC sobre interacoes | entities, characters |
| quest_data | Definicoes de quests | — |
| quest_progress | Progresso de quest por personagem | characters, quest_data |
| save_states | Save game (snapshots completos) | characters |

## Items Seed (10 itens base)
| Item | Tipo | Raridade | Slot | Valor |
|------|------|----------|------|-------|
| Espada de Madeira | weapon | common | weapon | 5 Z |
| Armadura de Couro | armor | common | chest | 8 Z |
| Pocao de Vida | consumable | common | — | 3 Z |
| Anel de Sorte | accessory | uncommon | ring | 25 Z |
| Amuleto Simples | accessory | common | amulet | 12 Z |
| Elmo de Ferro | armor | uncommon | helmet | 20 Z |
| Luvas de Combate | armor | common | gloves | 10 Z |
| Botas de Viajante | armor | common | boots | 10 Z |
| Espada de Ferro | weapon | uncommon | weapon | 30 Z |
| Cristal de Vorak | quest_item | epic | — | 0 Z |

## Raridades
common → uncommon → rare → epic → legendary → mythic
