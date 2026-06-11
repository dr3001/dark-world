# Dark World — Admin System
## Roles: OWNER, ADMIN, MODERATOR, STAFF
## Permissoes: grant zorium, ban/unban, login history, extrato, chat log, criar/encerrar evento, mensagem global
## API: POST /admin/grant-zorium, POST /admin/ban, POST /admin/unban, POST /admin/announce, GET /auth/login-history/:id
## Tabelas: moderation_logs, server_announcements, ban_records
## Audit: toda acao admin registrada em moderation_logs com staff_id, target, reason, metadata
