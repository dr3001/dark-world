# Dark World — NPC AI Architecture

## Estrutura de Dados

### npc_profiles
- `entity_id` — referencia para entities
- `role` — villager, blacksmith, healer, merchant, guard
- `personality` JSONB — traits, tone, style
- `knowledge` JSONB — world facts, rumors, recipes
- `ai_provider` — "openai", "deepseek", null (sem AI)
- `ai_config` JSONB — endpoint, model, temperature, max_tokens

### npc_memory
- `npc_entity_id` — NPC que lembra
- `character_id` — personagem envolvido
- `memory_type` — interaction, observation, rumor, quest, trade, combat
- `content` JSONB — dados da memoria
- `importance` — 1..10, define retencao

## NPCs Existentes

| NPC | Role | Posicao |
|-----|------|---------|
| Guardiao do Vale | guard | (5, 0, 5) |
| Ferreiro Thorin | blacksmith | (-6, 0, 8) |
| Mercador Ivan | merchant | (8, 0, -5) |
| Curandeira Lyra | healer | (-7, 0, -6) |
| Campones Finn | villager | (3, 0, -10) |

## Integracao com IA (Futuro)

Configuracao centralizada:
```json
{
  "ai_provider": "openai",
  "ai_config": {
    "endpoint": "https://api.openai.com/v1",
    "model": "gpt-4o-mini",
    "temperature": 0.7,
    "max_tokens": 150
  }
}
```

Provider DeepSeek:
```json
{
  "ai_provider": "deepseek",
  "ai_config": {
    "endpoint": "https://api.deepseek.com/v1",
    "model": "deepseek-chat",
    "temperature": 0.7,
    "max_tokens": 150
  }
}
```

## Fluxo de Dialogo (com IA)
1. Cliente envia `character_id` + `npc_id` + mensagem
2. Servidor carrega profile + memories do NPC
3. Monta system prompt com personality + knowledge
4. Adiciona memories relevantes como contexto
5. Envia para provider IA
6. Retorna resposta + salva nova memoria

## Diálogos Atuais (sem IA)
Textos estaticos definidos em `World.gd` → `npc_dialogs` dictionary.
NPCs sao StaticBody3D com CapsuleShape3D para colisao.
Interacao via tecla E (proximidade 4m).

## API
- `GET /npcs/:id/profile` — carregar perfil
- `GET /npcs/:id/memory?character_id=X` — carregar memorias
