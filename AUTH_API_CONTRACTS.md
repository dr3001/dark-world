# Dark World — Auth API Contracts
## POST /auth/register → body: {device_id} → {token,user_id,username,created}
## POST /auth/restore → body: {token} → {account}
## POST /test/account → body: {display_name} → {account} — auto-creates stats(Z=50) + wallet(50)
## POST /test/character → body: {account_id,character_name} → {character,entity}
## GET /auth/login-history/:userId → {history: [{ip,device,platform,success,created_at}]}
## Roles: player, premium, vip, staff, moderator, admin, owner
## Status: active, suspended, banned, deleted
