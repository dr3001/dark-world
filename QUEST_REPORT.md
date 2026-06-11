# Dark World — Quest Report

## Status: IMPLEMENTADO

## Quest Ativa
| Campo | Valor |
|-------|-------|
| Nome | Derrote Vorak, o Antigo |
| Tipo | main |
| Quest Giver | Curandeira Lyra |
| Recompensas | 500 XP, 100 Zorium, Cristal de Vorak |

## Jornal de Missoes
- Tecla J para abrir/fechar
- Lista quests por estado (ativa, completa, falhada)
- Icones: > ativa, + completa, X falhada
- Descricao resumida

## Flow
1. Falar com Curandeira Lyra
2. Pressionar [Q] para aceitar missao
3. HUD atualiza: "MISSAO: Derrote Vorak, o Antigo"
4. Jornal registra quest ativa

## Arquivos
- `QuestJournal.gd` — UI do jornal
- `World.gd` — quest flow integration
- `World.tscn` — JournalPanel node

## API
- `GET /characters/:id/quests`
- `POST /characters/:id/quests/accept`
