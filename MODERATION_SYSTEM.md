# Dark World — Moderation System
## Tipos: CHAT_MUTE, TEMP_BAN, PERM_BAN, ACCOUNT_SUSPENSION
## Tabelas: ban_records (user, staff, type, reason, expires_at, is_active), mute_records, moderation_logs
## Toda acao registra: staff_id, target_user_id, reason, created_at, expires_at
## API: POST /admin/ban, POST /admin/unban
## Chat moderation: moderation_status em chat_messages (ok, flagged, deleted)
