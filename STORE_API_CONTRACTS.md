# Dark World — Store API Contracts
## GET /store/products → {products: [{id,name,description,price_cents,price_zorium,product_type,category,is_active}], mode:"sandbox"}
## POST /store/checkout/create → body: {user_id,product_id} → {mode:"sandbox",product} — Stripe NAO ativo
## POST /store/webhook/stripe → body: Stripe event payload → {received:true,mode:"sandbox"} — loga em webhook_logs
## GET /vip/levels → {levels: [{level,name,badge,color,benefits}]}
