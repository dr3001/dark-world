# POSTGRESQL SETUP — Dark World

**Serviço:** darkworld-postgres (Docker)
**Porta Host:** 5433
**Porta Container:** 5432
**Rede:** darkworld-net (interna)

---

## Configuração

| Parâmetro | Valor |
|-----------|-------|
| Imagem | postgres:16-alpine |
| Banco Principal | darkworld |
| Banco Nakama | darkworld_nakama |
| Usuário | darkworld_admin |
| Volume | darkworld_pgdata |
| Migrations | /opt/darkworld/database/migrations/ |

## Conexão

```bash
# Via Docker (interno)
docker exec -it darkworld-postgres psql -U darkworld_admin -d darkworld

# Via host
psql -h localhost -p 5433 -U darkworld_admin -d darkworld

# Via outro container na rede darkworld-net
psql -h postgres -p 5432 -U darkworld_admin -d darkworld
```

## Volumes

- `darkworld_pgdata`: Dados persistentes do PostgreSQL
- `./database/migrations`: Scripts SQL executados na inicialização

## Healthcheck

```bash
docker exec darkworld-postgres pg_isready -U darkworld_admin
```

## Isolamento

PostgreSQL do Dark World roda na porta 5433, sem conflito com PostgreSQL nativo do Zorion (5432).
