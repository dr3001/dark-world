# DOCKER SETUP — Dark World

**Servidor:** Hetzner CCX23
**Data:** 2026-06-10

---

## Versões

| Componente | Versão |
|------------|--------|
| Docker Engine | 29.1.3 |
| Docker Compose | v5.1.4 |
| Storage Driver | overlay2 |

## Configuração

**daemon.json** (`/etc/docker/daemon.json`):
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
```

## Rede Docker

- **darkworld-net**: Rede bridge interna para todos os serviços do jogo
- Isolada da rede host e de outros containers

## Comandos Úteis

```bash
# Subir stack
cd /opt/darkworld && docker compose up -d

# Status
docker compose ps

# Logs
docker compose logs -f [serviço]

# Parar
docker compose down

# Reiniciar um serviço
docker compose restart [serviço]
```

## Teste Realizado

```bash
docker run --rm hello-world
# Resultado: Hello from Docker! — OK
```
