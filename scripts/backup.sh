#!/bin/bash
# Dark World — Backup Script
# Executar via cron: 0 4 * * * /opt/darkworld/scripts/backup.sh

set -e

BACKUP_DIR="/opt/darkworld/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/darkworld_$TIMESTAMP.sql.gz"
RETENTION_DAYS=7

echo "[$(date)] Iniciando backup..."

# Dump do PostgreSQL
docker exec darkworld-postgres pg_dump -U darkworld_admin darkworld | gzip > "$BACKUP_FILE"

echo "[$(date)] Backup criado: $BACKUP_FILE ($(du -h "$BACKUP_FILE" | cut -f1))"

# Remover backups antigos
find "$BACKUP_DIR" -name "darkworld_*.sql.gz" -mtime +$RETENTION_DAYS -delete
echo "[$(date)] Backups com mais de $RETENTION_DAYS dias removidos."

echo "[$(date)] Backup concluído."
