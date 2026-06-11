# Dark World — XP System Report

## Status: IMPLEMENTADO

## Curva de XP
| Nivel | XP Necessario |
|-------|--------------|
| 1 | 0 |
| 2 | 100 |
| 3 | 250 |
| 4 | 500 |
| 5 | 800 |
| 6 | 1200 |
| 7 | 1700 |
| 8 | 2300 |
| 9 | 3000 |
| 10 | 4000 |
| 11-20 | 5200-34000 |
| 21+ | +5000 por nivel |

## Level Up
- HP: +10 por nivel
- Mana: +5 por nivel
- HP e Mana restaurados ao subir
- Signal `level_up` emitido
- HUD atualiza automaticamente

## Display
- `LevelLabel`: "Nv. X" (amarelo)
- `ZoriumLabel`: "X Z" (azul)
- Atualizado em tempo real via CharacterProfile

## Arquivos
- `CharacterProfile.gd` — XP tracking, level up, signals
- `World.gd` — display dinamico no HUD

## API
- `GET /characters/:id/stats`
- `PUT /characters/:id/stats` (add_xp)
