# Dark World — Stripe Foundation
## Status: SANDBOX — sem cobranca real
## Tabelas: stripe_customers, payment_intents, webhook_logs
## Endpoints: POST /store/checkout/create (retorna sandbox), POST /store/webhook/stripe (loga evento)
## Fluxo futuro: Checkout → Stripe Intent → Webhook → Confirm → Deliver → Credit Wallet
## Env vars: STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET (nao configurados)
