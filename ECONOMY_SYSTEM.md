# Dark World — Economy System

## Moeda: ZORIUM (Z)

## Fontes de Zorium
| Fonte | Tipo | Exemplo |
|-------|------|---------|
| Loot | Automatico | Monstros dropam Z ao morrer |
| Quest reward | Automatico | Completar "Derrote Vorak" = 100 Z |
| Venda | Jogador | Vender item ao mercador |
| Trade | Jogador | Troca entre jogadores |
| Admin grant | Admin | Bonus/compensacao |
| Stripe purchase | Monetizacao | Compra real (futuro) |

## Gastos de Zorium
| Gasto | Tipo |
|-------|------|
| Compra de itens | Mercador NPC |
| Reparos | Ferreiro NPC |
| Cura | Curandeira NPC |
| Trade | Entre jogadores |

## Tabelas
- `wallets` — saldo por personagem (UNIQUE character_id)
- `transactions` — log de todas as transacoes (from, to, amount, type)
- `character_stats.zorium` — espelho do saldo para acesso rapido

## API
- `GET /characters/:id/wallet` — consultar saldo
- `POST /wallets/transfer` — transferir entre personagens

## Monetizacao (Preparacao)
- Stripe webhook endpoint (futuro)
- Transaction type: `stripe_purchase`
- Credita zorium na wallet do personagem
- Log em transactions + audit_logs
- NAO ativo ate implementacao do Stripe
