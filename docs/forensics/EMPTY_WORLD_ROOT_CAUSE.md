# EMPTY_WORLD_ROOT_CAUSE.md

**Date:** 2026-06-12

## Symptom

Rogério sees HUD + quest + map but world looks empty — prototype/debug field.

## Architecture (confirmed)

`World.tscn` contains only:

- Ground plane (1000×1000 green)
- Camera, sun, fog, HUD

**All gameplay geometry is procedural** in `World.gd` `_ready()`:

- `_build_plaza()`, `_build_village()`, `_build_walls()`, `_build_rocks()`
- `_spawn_npcs()`, `_build_castle()`, `_spawn_dragon()`, `_build_trees()`

If `_ready()` fails or old binary is cached, player sees **empty green field + HUD**.

## Root causes (ranked)

| # | Cause | Evidence | Fix |
|---|-------|----------|-----|
| 1 | **Stale CDN game binary** | Rogério on v5.0.5 debug export | Published **v5.0.6 release** (`ff651faa...`) |
| 2 | **World.gd parse errors** blocked script | Export showed SCRIPT ERROR pre-fix | Fixed `_show_profile`, `_hide_save_indicator`, GameLogger |
| 3 | **Debug export** | `--export-debug` showed console + different behavior | Switched to `--export-release` |
| 4 | Visual "prototype" | Procedural box meshes (houses, castle) | Not empty — low art fidelity (out of scope for features) |

## Audit results

Script: `scripts/audit-world-load.sh`

```
OK: World.gd contains procedural builders
OK: DarkWorld.exe size=245541472 hash=eefdaab3...
Remote game_version: 5.0.6 (after publish)
```

Expected object counts when World.gd runs (from code):

- Trees: ~100+
- Houses: 16+
- NPCs: 8+
- Dragons: 1
- Castle + walls at north

Spawn: player at `(0, 3, 0)` — plaza fountain at origin should be visible immediately.

## Rogério action

1. Update to **v5.0.6** via launcher (or Reparar)
2. Confirm portable zip hash matches manifest
3. Screenshot spawn — must show plaza structures, not bare field

## If still empty after v5.0.6

Check `%LOCALAPPDATA%/DarkWorld/logs/game/game.log` for `[WORLD] DONE - Trees:...` line.
