# SERVER AUDIT — Dark World

**Data:** 2026-06-10
**Servidor:** Hetzner CCX23 | ubuntu-16gb-hil-1
**IP:** 5.78.142.138

---

## Sistema Operacional
- **SO:** Ubuntu 26.04 LTS (Resolute Raccoon)
- **Kernel:** Linux x86_64
- **Hostname:** ubuntu-16gb-hil-1

## Hardware
- **CPU:** 4 cores AMD EPYC-Milan Processor
- **RAM:** 15GB total (13GB disponível)
- **Swap:** 2GB
- **Disco:** 150GB SSD (/dev/sda1) — 13GB usado, 131GB livre (90% livre)

## Rede
- **IP Público:** 5.78.142.138
- **IP Docker:** 172.17.0.1/16
- **Portas abertas (UFW):** 22/tcp, 80/tcp, 443/tcp
- **Portas bloqueadas (UFW):** 631 (IPP)

## Serviços Ativos (systemd)
| Serviço | Porta | Status | Uso |
|---------|-------|--------|-----|
| PostgreSQL 18.4 | 5432 (localhost) | active | Zorion produção |
| Redis 8.0.5 | 6379 (localhost) | active | Zorion produção |
| MariaDB | 3306 (localhost) | active | WordPress |
| Nginx 1.28.3 | 80, 443 (público) | active | zorionlabs.net |
| Docker 29.1.3 | - | active | Engine |
| SSH | 22 (público) | active | Acesso remoto |
| Node.js API | 3000 (localhost) | active | Zorion API |
| Python | 8765 (localhost) | active | Serviço interno |

## Ferramentas Instaladas
| Ferramenta | Versão | Status |
|------------|--------|--------|
| Git | 2.53.0 | Instalado |
| Curl | 8.18.0 | Instalado |
| Wget | 1.25.0 | Instalado |
| Htop | 3.4.1 | Instalado |
| Nano | 8.7.1 | Instalado |
| Vim | 9.1 | Instalado |
| Net-tools | 2.10 | Instalado |
| Build-essential | - | Instalado |
| Unzip | - | Instalado |
| Certbot | - | Instalado |
| Node.js | v22.22.3 | Instalado |
| npm | 10.9.8 | Instalado |
| OpenCode | 1.17.3 | Instalado |

## Segurança
- **Fail2ban:** Ativo (3 jails: nginx-http-auth, nginx-limit-req, sshd)
- **UFW:** Ativo (permitido: 22, 80, 443)
- **SSL:** Certificado manual em /etc/nginx/ssl/ (zorionlabs.net)

## Bancos de Dados Existentes (PostgreSQL Nativo)
- `evolution` — Zorion
- `postgres` — Sistema
- `template0`, `template1` — Templates

## Cron Jobs
```
0 3 * * * /opt/zorion/scripts/backup.sh
*/5 * * * * /opt/zorion/scripts/monitor-vps2.sh
0 3 * * * /opt/zorion/scripts/prod-backup.sh
```

## Conflitos Identificados
| Recurso | Conflito | Solução |
|---------|----------|---------|
| PostgreSQL:5432 | Zorion usa nativo | Dark World usará Docker na 5433 |
| Redis:6379 | Zorion usa nativo | Dark World usará Docker na 6380 |
| Nginx:80/443 | Zorion usa nativo | Dark World usará server blocks |
| API:3000 | Zorion API | Admin Panel usará 9001 interno |

## Capacidade Estimada
- **Discos:** 131GB livres — suficiente para anos de desenvolvimento
- **RAM:** 13GB livres — folga para Docker (postgres+redis+nakama+engine)
- **CPU:** 4 cores AMD EPYC — suficiente para servidor multiplayer com dezenas de jogadores simultâneos
- **Rede:** Hetzner backbone — baixa latência para América do Sul/América do Norte

## Riscos
- Apenas 1 disco (sem RAID) — backup externo recomendado futuramente
- Sem IP failover configurado
- Swap de 2GB pode ser pouco se houver memory leak
