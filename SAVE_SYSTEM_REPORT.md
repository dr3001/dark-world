# Dark World — Save System Report

## Status: IMPLEMENTADO

## Mecanismos de Save
| Tipo | Trigger | Intervalo |
|------|---------|-----------|
| Manual | F5 | Sob demanda |
| Auto-save | Timer | 60 segundos |

## Dados Salvos
- Posicao do jogador (x, y, z)
- Stats completos (HP, Mana, Level, XP, Zorium, atributos)
- Inventario (todos os slots)
- Equipamentos (todos os slots)
- Quests (estado e progresso)

## Indicador Visual
- "Salvando..." ou "Auto-save..." no canto inferior direito
- Visivel por 2s apos save manual, 1.5s apos auto-save

## Arquivos
- `World.gd` — _manual_save(), _auto_save(), auto_save_timer
- `World.tscn` — SaveIndicator label

## API
- `POST /characters/:id/save`

## Tabela
- `save_states` — snapshots completos com timestamps
