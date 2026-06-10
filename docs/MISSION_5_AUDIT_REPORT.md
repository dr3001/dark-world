# MISSION 5 — AUDIT REPORT

**Data:** 2026-06-10 21:10 UTC

## Classificação

| Componente | Status | Classificação |
|------------|--------|---------------|
| Docker Engine | Running | FUNCIONAL |
| Docker Compose | v5.1.4 | FUNCIONAL |
| PostgreSQL 16 | :5433 Healthy | FUNCIONAL |
| Redis 7 | :6380 PONG | FUNCIONAL |
| Nakama 3.31 | :7350 HTTP 200 | FUNCIONAL |
| World Engine | :9000 10 endpoints | FUNCIONAL |
| Event Engine | 6 handlers | FUNCIONAL |
| Entity System | 5 entities + 5 components | FUNCIONAL |
| Audit Logs | 10+ registros | FUNCIONAL |
| Backup | Cron 04:00 | FUNCIONAL |
| Nginx | 80/443 + /dark/ | FUNCIONAL |
| SSL | zorionlabs.net | FUNCIONAL |
| UFW | 22,80,443 | FUNCIONAL |
| Fail2ban | 3 jails | FUNCIONAL |
| Web Portal | /dark/ 200 | FUNCIONAL |
| Mac Build | zip 14KB | FUNCIONAL |
| Godot Client | 4 scenes, 8 scripts | PARCIAL (não testado no Mac) |
| Admin Panel | empty dir | PLACEHOLDER |
| Prometheus | config only | PLACEHOLDER |

## Conclusão
15/17 FUNCIONAL, 1 PARCIAL (Godot untested on Mac), 1 PLACEHOLDER (Admin Panel)
