# UPGRADE PLAN — Mission 7.1

## Completed Upgrades

1. **Godot 4.4 → 4.6.3**: DONE
   - Binary installed at /opt/godot/godot_4.6.3/
   - macOS export templates installed
   - Old version preserved at /opt/godot/godot_bin/

## Pending Upgrades

None critical for Alpha release.

## Future Upgrades

1. **PostgreSQL 16 → 17** (post-Alpha)
   - Backup: docker volume backup
   - Time: ~60 minutes
   - Rollback: restore volume
