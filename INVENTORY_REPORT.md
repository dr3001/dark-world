# Dark World — Inventory Report

## Status: IMPLEMENTADO

## Funcionalidades
- 20 slots de inventario
- Grid 5x4 com botoes interativos
- Tooltip on hover (nome, tipo, stats, valor em Zorium)
- Quantidade visivel para itens stackaveis
- Cores por raridade (common → mythic)
- Contador de slots utilizados
- Tecla I para abrir/fechar
- Persistencia via API server

## Teclas
| Tecla | Acao |
|-------|------|
| I | Abrir/fechar inventario |
| Click esquerdo | Selecionar item |
| Hover | Mostrar tooltip |

## Arquivos
- `InventorySystem.gd` — logica e UI do inventario
- `ItemTooltip.gd` — tooltip de item
- `World.tscn` — InventoryPanel, InventoryGrid, InventoryHint

## API
- `GET /characters/:id/inventory`
- `POST /characters/:id/inventory`
- `DELETE /characters/:id/inventory/:slot`
