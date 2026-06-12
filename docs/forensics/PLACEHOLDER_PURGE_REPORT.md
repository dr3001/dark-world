# PLACEHOLDER_PURGE_REPORT.md

**Date:** 2026-06-12

## Removed / hidden from player view

| Item | Action |
|------|--------|
| Godot console window | Release export + `console_wrapper=false` |
| HUD FPS counter | Hidden in release |
| HUD ObjectCount | Hidden in release |
| HUD Position coords | Hidden in release |
| `[Main]` stdout prints | → GameLogger file |
| `[WORLD]` stdout prints | → GameLogger.write_log |
| API reset_token leak | Removed from JSON response |
| Orphan Main.tscn | Deleted |

## Retained (functional placeholders — not removed per scope)

Procedural geometry in `World.gd` uses primitive meshes (boxes, cylinders) — this is existing art, not missing assets. No new art pipeline added.

`EntitySpawner.gd` server-side entity placeholders (colored boxes) — used for multiplayer entities; not removed.

`CombatAudioSystem.gd` audio placeholders — print-only debug; not in player UI.

## Debug keys (dev only)

World.gd `_debug_vfx` keys 0-9 — only active when key pressed; no visible debug UI in release.

## Status

Player-visible debug pollution: **purged for release build v5.0.6**.

Art quality (box houses): **unchanged** — acabamento visual is separate from debug purge.
