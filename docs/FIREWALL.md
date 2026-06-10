# FIREWALL — Dark World

**Servidor:** Hetzner CCX23
**Data:** 2026-06-10

---

## UFW Status

```
Status: active
```

## Regras Ativas

| # | Porta | Ação | Origem | Motivo |
|---|-------|------|--------|--------|
| 1 | 22/tcp | ALLOW | Anywhere | SSH |
| 2 | 80/tcp | ALLOW | Anywhere | HTTP (zorionlabs.net) |
| 3 | 443/tcp | ALLOW | Anywhere | HTTPS (zorionlabs.net) |
| 4 | 631/tcp | DENY | Anywhere | IPP bloqueado |
| 5 | 631/udp | DENY | Anywhere | IPP bloqueado |

## Regras IPv6

Idênticas às IPv4 (regras 6-10).

## Decisão

O firewall atual está correto para a fase atual do projeto:
- Portas 80/443 servem o Zorion (produção) e futuramente o Admin Panel do jogo via subdomínio
- Porta 22 para SSH é essencial
- Nakama (7350/7351) não precisa ser exposto externamente — será acessado via proxy reverso do Nginx
- World Engine (9000) é interno, apenas na rede Docker
- Monitoramento (9090, 3001) é interno

## Expansão Futura

Quando o jogo tiver clientes externos (Godot), será necessário expor:
- Porta 7350 (Nakama HTTP) ou proxy via Nginx em subdomínio
- Porta 7351 (Nakama gRPC) para clientes Godot

```bash
# Futuro (não executar agora):
# ufw allow 7350/tcp
# ufw allow 7351/tcp
```

## Fail2ban

Jails ativos:
- `sshd` — Proteção contra brute force SSH
- `nginx-http-auth` — Proteção contra brute force HTTP auth
- `nginx-limit-req` — Rate limiting no Nginx
