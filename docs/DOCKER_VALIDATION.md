# DOCKER VALIDATION — Mission 2

**Data:** 2026-06-10

## Versões
| Componente | Versão | Status |
|------------|--------|--------|
| Docker Engine | 29.1.3 | OK |
| Docker Compose | v5.1.4 | OK |

## Containers Ativos
| Container | Imagem | Portas | Status |
|-----------|--------|--------|--------|
| darkworld-postgres | postgres:16-alpine | 5433 | Healthy |
| darkworld-redis | redis:7-alpine | 6380 | Healthy |
| darkworld-nakama | heroiclabs/nakama:3.31.0 | 7350/7351 | Up |

## Volumes
| Volume | Driver |
|--------|--------|
| darkworld_darkworld_pgdata | local |
| darkworld_darkworld_redisdata | local |

## Networks
| Network | Driver |
|---------|--------|
| darkworld_darkworld-net | bridge (isolada) |

## Conclusão
Docker e Compose operacionais. Todos os containers do jogo rodando com healthcheck. Rede isolada sem conflito com produção.
