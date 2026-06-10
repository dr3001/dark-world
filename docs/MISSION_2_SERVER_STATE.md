# MISSION 2 — Server State Audit

| Campo | Valor |
|-------|-------|
| Data | 2026-06-10 20:17 UTC |
| SO | Ubuntu 26.04 LTS |
| Kernel | 7.0.0-22-generic x86_64 |
| Uptime | 6 dias |
| CPU | 4 cores AMD EPYC-Milan |
| RAM | 15GB (3GB usado, 13GB disponível) |
| Disco | 150GB (14GB usado, 130GB livre) |
| IPv4 | 5.78.142.138 |
| IPv6 | 2a01:4ff:1f0:796a::/64 |

## Containers Docker

| Container | Imagem | Portas | Status |
|-----------|--------|--------|--------|
| darkworld-postgres | postgres:16-alpine | 5433 | Healthy |
| darkworld-redis | redis:7-alpine | 6380 | Healthy |
| darkworld-nakama | heroiclabs/nakama:3.31.0 | 7350/7351 | Healthy |

## Firewall

UFW ativo. Portas expostas: 22, 80, 443. Portas de jogo internas (Docker network).

## Serviços Confirmados

- [x] Docker + Compose
- [x] PostgreSQL (Docker, porta 5433)
- [x] Redis (Docker, porta 6380)
- [x] Nakama (Docker, portas 7350/7351)
- [x] World Engine (estrutura pronta, build pendente)
- [x] Backup crontab configurado
- [x] Documentação base (19 docs da Fase 0)

## Serviços Ausentes

- World Engine (não buildado ainda — será feito na Fase 8)
- Admin Panel (placeholder)
- Godot Client (placeholder)
- Prometheus/Grafana (config básico apenas)

## Riscos

- Nakama sem healthcheck (container não tem wget/curl — resolvido removendo healthcheck)
- Apenas 1 disco, sem RAID
- Sem IP failover
