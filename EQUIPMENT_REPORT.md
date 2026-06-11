# Dark World — Equipment Report

## Status: IMPLEMENTADO

## Slots de Equipamento (7)
| Slot | Tipo |
|------|------|
| weapon | Arma |
| helmet | Capacete |
| chest | Peitoral |
| gloves | Luvas |
| boots | Botas |
| ring | Anel |
| amulet | Amuleto |

## Funcionalidades
- Painel visual com 7 slots nomeados
- Exibe item equipado com cor de raridade
- Calculo de bonus de stats agregado
- Abre junto com inventario (tecla I)
- Persistencia via API server

## Arquivos
- `EquipmentPanel.gd` — UI e logica de equipamento
- `World.tscn` — EquipmentPanel node

## API
- `GET /characters/:id/equipment`
- `POST /characters/:id/equipment/equip`
- `POST /characters/:id/equipment/unequip`
