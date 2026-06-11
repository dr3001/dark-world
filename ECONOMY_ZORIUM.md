# Dark World — Zorium Economy (Gamma)
## Moeda: ZORIUM (Z)
## Ledger: zorium_ledger (every credit/debit logged with tx_type, source, reason, created_by)
## tx_types: admin_grant, purchase_pending, purchase_confirmed, shop_purchase, quest_reward, event_reward, refund, adjustment, heal, forge, trade, loot
## Regras: nenhuma alteracao de saldo sem log. Entrada apenas por: admin grant, compra confirmada, recompensa autorizada, evento autorizado.
## Tabelas: wallets, character_stats.zorium, zorium_ledger, transactions
## API: GET /wallet/:id/ledger, POST /admin/grant-zorium, POST /characters/:id/spend
## Saldo inicial: 50Z ao criar personagem
