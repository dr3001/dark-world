# REDIS SETUP — Dark World

**Serviço:** darkworld-redis (Docker)
**Porta Host:** 6380
**Porta Container:** 6379
**Rede:** darkworld-net (interna)

---

## Configuração

| Parâmetro | Valor |
|-----------|-------|
| Imagem | redis:7-alpine |
| Persistência | AOF (appendonly yes) |
| Snapshot | RDB (save 900 1, 300 10, 60 10000) |
| Memória Máxima | 256MB |
| Política | allkeys-lru |
| Volume | darkworld_redisdata |

## Conexão

```bash
# Via host
redis-cli -p 6380 ping

# Via container
docker exec -it darkworld-redis redis-cli ping

# Via outro container na rede darkworld-net
redis-cli -h redis -p 6379 ping
```

## Uso no Jogo

- Cache de sessões
- Filas de eventos
- Locks distribuídos
- Dados voláteis (posições, estado temporário)

## Isolamento

Redis do Dark World roda na porta 6380, sem conflito com Redis nativo do Zorion (6379).
