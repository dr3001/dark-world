# MONITORING — Dark World

## Stack

| Ferramenta | Função | Status |
|------------|--------|--------|
| Prometheus | Coleta métricas | Configurado |
| Grafana | Dashboards | Placeholder |
| Docker healthcheck | Health dos containers | Ativo |
| Logs em arquivo | Debug | Ativo |

## Estrutura

```
monitoring/
├── prometheus/
│   └── prometheus.yml    # Config Prometheus
├── grafana/
│   └── datasources.yml   # Datasource Prometheus
```

## Prometheus

- Porta: 9090 (host, interno)
- Coleta métricas dos containers via Docker
- Coleta métricas do PostgreSQL e Redis via exporters (futuro)

## Grafana

- Porta: 3001 (host, interno)
- Datasource: Prometheus
- Dashboards serão criados posteriormente

## Healthchecks Docker

Todos os serviços têm healthcheck:
- PostgreSQL: pg_isready
- Redis: redis-cli PING
- Nakama: HTTP GET /
- World Engine: HTTP GET /health

## Expansão Futura

- Loki para logs centralizados
- Node Exporter para métricas do host
- PostgreSQL Exporter
- Redis Exporter
- Alertmanager para alertas
- Dashboard de jogo (jogadores online, eventos/minuto)
