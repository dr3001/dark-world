# ROLLBACK PLAN — Mission 7.1

## Godot Rollback

If Godot 4.6.3 export fails:
1. Switch to /opt/godot/godot_bin/Godot_v4.4-stable_linux.x86_64
2. Use templates at /root/.local/share/godot/export_templates/4.4.stable/
3. Re-export project

## Database Rollback

PostgreSQL upgrade rollback:
1. Stop docker compose
2. Restore volume backup: docker volume restore
3. Restart services

## App Rollback

If DarkWorld.app has issues:
1. Revert to previous zip (project.godot + source)
2. Available at: /var/www/zorionlabs/dark/downloads/DarkWorld-Mac.zip (old)
