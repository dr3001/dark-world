# Dark World — Quest Architecture

## Tabelas

### quest_data (definicoes)
- `id` UUID
- `name` — nome da quest
- `description` — descricao
- `quest_type` — main, side, daily, event
- `min_level` — nivel minimo
- `requirements` JSONB — condicoes (kill X, collect Y)
- `rewards` JSONB — recompensas (xp, zorium, items)
- `chain_next_id` — proxima quest na cadeia

### quest_progress (estado por personagem)
- `character_id` + `quest_id` UNIQUE
- `state` — available, active, completed, failed, turned_in
- `progress` JSONB — progresso parcial
- `started_at`, `completed_at`

## Quest Inicial

| Campo | Valor |
|-------|-------|
| Nome | Derrote Vorak, o Antigo |
| Tipo | main |
| Level | 1 |
| Requisitos | `{"kill":{"entity_type":"dragon","entity_name":"Vorak"}}` |
| Recompensas | `{"xp":500,"zorium":100,"items":["Cristal de Vorak"]}` |

## Fluxo
1. Jogador fala com Curandeira Lyra
2. Quest aparece como "available"
3. Jogador aceita → state="active"
4. Jogador derrota Vorak → state="completed"
5. Jogador recebe recompensas → state="turned_in"

## API
- `GET /characters/:id/quests` — listar quests
- `POST /characters/:id/quests/accept` — aceitar quest
- `GET /items` — consultar itens de recompensa
