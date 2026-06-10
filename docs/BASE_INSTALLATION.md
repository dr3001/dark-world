# BASE INSTALLATION — Dark World

**Servidor:** Hetzner CCX23 | ubuntu-16gb-hil-1
**Data:** 2026-06-10

---

## Ferramentas Instaladas

| Ferramenta | Versão | Método | Status |
|------------|--------|--------|--------|
| Git | 2.53.0 | apt | Pré-existente |
| Curl | 8.18.0 | apt | Pré-existente |
| Wget | 1.25.0 | apt | Pré-existente |
| Unzip | - | apt | Instalado |
| Build-essential | - | apt | Instalado |
| Htop | 3.4.1 | apt | Pré-existente |
| Nano | 8.7.1 | apt | Pré-existente |
| Vim | 9.1 | apt | Pré-existente |
| Net-tools | 2.10 | apt | Pré-existente |
| Fail2ban | 1.1.0 | apt | Pré-existente |
| UFW | 0.36.2 | apt | Pré-existente |
| Nginx | 1.28.3 | apt | Pré-existente |
| Certbot | - | apt | Instalado |
| Docker | 29.1.3 | apt | Pré-existente |
| Docker Compose | v5.1.4 | apt | Pré-existente |
| Node.js | v22.22.3 | apt | Pré-existente |
| npm | 10.9.8 | apt | Pré-existente |
| PostgreSQL Client | 18.4 | apt | Pré-existente |
| Redis Client | 8.0.5 | apt | Pré-existente |

## Comandos de Instalação (referência)

```bash
# Pacotes que faltavam (executado em 2026-06-10)
apt-get update
apt-get install -y build-essential unzip certbot python3-certbot-nginx

# Os demais já estavam presentes da instalação base do Ubuntu 26.04
# e da stack Zorion existente.
```

## Verificação Rápida

```bash
for pkg in git curl wget unzip build-essential htop nano vim net-tools; do
  dpkg -l "$pkg" 2>/dev/null | grep ^ii && echo "  OK: $pkg" || echo "  FALTA: $pkg"
done
```
