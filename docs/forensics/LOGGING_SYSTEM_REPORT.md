# LOGGING_SYSTEM_REPORT.md

**Date:** 2026-06-12

## Goal

No stdout/stderr/console visible to players. Logs go to files with rotation.

## Launcher logs

**Path:** `%LOCALAPPDATA%/DarkWorld/logs/launcher/launcher.log`

**Module:** `launcher/src-tauri/src/logger.rs`

- Append-only logging with mutex
- Rotation at 5 MB → `launcher.<timestamp>.log.gz` (gzip via flate2)
- Tray menu "Ver logs" opens folder
- Command: `open_logs_folder`

## Game logs

**Path:** `%LOCALAPPDATA%/DarkWorld/logs/game/game.log`

**Autoload:** `godot-client/scripts/GameLogger.gd`

- `write_log(msg)` — file only in release; print only in debug builds
- Rotation at 5 MB → `game.<timestamp>.log`

## Console elimination

| Source | Fix |
|--------|-----|
| Godot Windows console | `--export-release` + `application/console_wrapper=false` |
| Game stdout | GameLogger + no debug prints in release HUD |
| Launcher spawn | `Stdio::null()` on game process |

## Pipeline

- `scripts/publish-release.sh` — export-release
- `.github/workflows/release-pipeline.yml` — export-release

## Client logs directory layout

```
DarkWorld/logs/
  launcher/launcher.log
  game/game.log
```

(`logs/client/` reserved for future unified client wrapper)
