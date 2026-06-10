# BACKUP STRATEGY — Dark World

## Política

| Parâmetro | Valor |
|-----------|-------|
| Frequência | Diário (04:00 UTC) |
| Retenção | 7 dias |
| Tipo | pg_dump completo (gzip) |
| Local | /opt/darkworld/backups/ |

## Script

`/opt/darkworld/scripts/backup.sh`

```bash
docker exec darkworld-postgres pg_dump -U darkworld_admin darkworld | gzip > backup.sql.gz
```

## Crontab

```
0 4 * * * /opt/darkworld/scripts/backup.sh
```

(Executa às 04:00, 1h depois do backup do Zorion às 03:00 — sem conflito de I/O)

## Restauração

```bash
# Descompactar
gunzip darkworld_YYYYMMDD_HHMMSS.sql.gz

# Restaurar
cat darkworld_YYYYMMDD_HHMMSS.sql | docker exec -i darkworld-postgres psql -U darkworld_admin -d darkworld
```

## Expansão Futura

- Backup off-site (S3, Hetzner Storage Box)
- Backup incremental com WAL archiving
- Backup do volume Nakama
- Snapshot do filesystem
