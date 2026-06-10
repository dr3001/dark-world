# MISSION 8 — SECURITY TRUTH REPORT

## Firewall & Access
| Item | Status |
|------|--------|
| UFW active | OK (22, 80, 443 open) |
| Fail2ban active | OK (3 jails: sshd, nginx-http-auth, nginx-limit-req) |
| SSH key-only | OK (id_ed25519) |
| Brute force blocking | OK (fail2ban active) |

## Web Security
| Item | Status |
|------|--------|
| HTTPS enforced | OK (nginx redirect) |
| TLS 1.2/1.3 | OK |
| SSL cert | Self-signed (Cloudflare edge covers) |
| HSTS | NAO CONFIGURADO |
| WAF | NAO CONFIGURADO |
| Rate limiting | PARCIAL (nginx limit-req) |

## Secrets
| Item | Status |
|------|--------|
| .env in repo | NAO (gitignored) |
| Tokens in frontend | NAO |
| Database password | OK (strong) |
| JWT secret | OK (configured) |
| Logs with secrets | NAO ENCONTRADO |

## Issues
- HSTS nao configurado
- Cloudflare WAF ausente
- SSL mode Full (deveria ser Full Strict)
