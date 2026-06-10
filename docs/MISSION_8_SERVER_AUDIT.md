# MISSION 8 — SERVER AUDIT (Hetzner 5.78.142.138)

**Data:** 2026-06-10 21:52 UTC
**Auditor:** OpenCode DeepSeek V4 Pro

## OS & Kernel
| Item | Valor | Status |
|------|-------|--------|
| OS | Ubuntu 26.04 LTS (Resolute Raccoon) | FUNCIONAL |
| Kernel | 7.0.0-22-generic | FUNCIONAL |
| Arch | x86_64 | FUNCIONAL |
| CPU | 4-core AMD EPYC-Milan | FUNCIONAL |
| RAM | 15GB (6.0GB used, 9.2GB available) | FUNCIONAL |
| Disk | 150GB (19GB used, 13%) | FUNCIONAL |
| Swap | 2GB (100% used) | RISCO |

## Network & Security
| Item | Status |
|------|--------|
| Port 22 (SSH) | FUNCIONAL |
| Port 80 (HTTP) | FUNCIONAL |
| Port 443 (HTTPS) | FUNCIONAL |
| Port 9000 (World Engine) | FUNCIONAL |
| Port 7350/7351 (Nakama) | FUNCIONAL |
| Port 5433 (PostgreSQL) | FUNCIONAL |
| Port 6380 (Redis) | FUNCIONAL |
| UFW Firewall | FUNCIONAL (active) |
| Fail2ban | FUNCIONAL (3 jails) |
| SSL Cert | Self-signed, expires 2027-06-03 |
| Cloudflare | Proxied, SSL Full |

## Docker Containers
| Container | Image | Status |
|-----------|-------|--------|
| darkworld-postgres | postgres:16-alpine | FUNCIONAL (healthy) |
| darkworld-redis | redis:7-alpine | FUNCIONAL (healthy) |
| darkworld-nakama | heroiclabs/nakama:3.31.0 | FUNCIONAL (healthy) |
| darkworld-world-engine | darkworld-world-engine:0.4.0 | FUNCIONAL (healthy) |

## Services
| Service | Status |
|---------|--------|
| nginx | FUNCIONAL |
| docker | FUNCIONAL |
| fail2ban | FUNCIONAL |
| cron (backups) | FUNCIONAL |
| zorion-api | FUNCIONAL |

## Alerts
- Swap 100% usado — reiniciar para liberar
- Ataques SSH brute-force ativos (fail2ban bloqueando)
- SSL self-signed (Cloudflare cobre externamente)
- IPs bloqueados por fail2ban nas ultimas horas
