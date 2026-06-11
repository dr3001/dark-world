# Dark World — Friends System
## Tables: friends (user_id, friend_id, status), friend_requests (from, to, status)
## API: GET /friends/:userId, POST /friends/request, /friends/accept, /friends/remove, /friends/block
## Status: active, blocked (friends), pending/accepted/declined/cancelled (requests)
## Bidirecional: aceitar amizade cria 2 rows (A→B e B→A)
## Block: remove amizade e impede novos requests
