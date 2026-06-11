# Dark World — Landing Page API Contracts

## Auth
POST /auth/register → {token, user_id, username}
POST /auth/restore → {account}
GET /auth/login-history/:userId → {history[]}

## Profile
GET /characters/:id/profile → {profile}
GET /characters/:id/stats → {stats}
GET /characters/:id/titles → {titles[]}
GET /characters/:id/vip → {vip}

## Wallet
GET /characters/:id/wallet → {wallet}
GET /wallet/:id/ledger → {ledger[]}

## Inventory
GET /characters/:id/inventory → {inventory[]}
GET /characters/:id/equipment → {equipment[]}

## Store
GET /store/products → {products[], mode:"sandbox"}
POST /store/checkout/create → {mode:"sandbox", product}

## Social
GET /clans → {clans[]}
GET /chat/recent → {messages[]}
GET /rankings/global → {rankings[]}
GET /events/calendar → {events[], maintenance[], announcements[]}
