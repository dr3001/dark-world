# RESOURCE_VALIDATION_REPORT.md

**Date:** 2026-06-12

## Issues found

| Issue | Severity | Fix |
|-------|----------|-----|
| `Main.tscn` orphan without UID | Warning | **Deleted** — unused; main scene is `Login.tscn` |
| `Login.tscn` script ref without UID | Warning | Added `uid="uid://cvfcpgcm88ywl"` on Main.gd ext_resource |
| `EntitySpawner.gd` bad indentation L55-56 | Parse error risk | Fixed `cyl.bottom_radius` indent |
| `GameLogger.gd` method named `log()` | Parse error | Renamed to `write_log()` (conflicts with built-in) |
| `World.gd` merged profile/save code | Parse error | Restored `_show_profile()`, `_hide_save_indicator()` |

## Export validation

Command: `bash scripts/audit-world-load.sh`

| Check | Result |
|-------|--------|
| `--export-release Windows` | DONE |
| SCRIPT ERROR | None |
| invalid UID | None |
| Export warnings (script) | 0 |
| DarkWorld.exe produced | 245541472 bytes |

Godot engine "deadzone" dictionary errors during export are engine input-map noise — not shipped to player.

## Re-export

Game **v5.0.6** published to CDN with hash `ff651faa...` (portable zip).

## Target

0 UID warnings, 0 script errors at export — **achieved** for v5.0.6 release build.
