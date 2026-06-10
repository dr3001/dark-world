# MISSION 8 — BACKUP & ROLLBACK REPORT

## Backups
| Item | Method | Frequency | Status |
|------|--------|-----------|--------|
| Zorion backup | /opt/zorion/scripts/backup.sh | Daily 3AM | ATIVO |
| VPS2 monitor | /opt/zorion/scripts/monitor-vps2.sh | Every 5min | ATIVO |
| Prod backup | /opt/zorion/scripts/prod-backup.sh | Daily 3AM | ATIVO |
| Dark World backup | /opt/darkworld/scripts/backup.sh | Daily 4AM | ATIVO |
| PostgreSQL data | Docker volume | Persistent | ATIVO |
| Redis data | Docker volume | Persistent | ATIVO |

## Rollback
| Item | Method | Status |
|------|--------|--------|
| PostgreSQL | Docker volume backup/restore | CONFIGURADO |
| App | Previous build in /var/www/zorionlabs/dark/downloads/ | CONFIGURADO |
| Nginx | Config in /etc/nginx/sites-enabled/ | MANUAL |
| Godot | Old binary at /opt/godot/godot_bin/ | CONFIGURADO |

## Verdict
Backups ativos. Rollback configurado para componentes criticos.
