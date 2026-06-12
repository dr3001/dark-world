# LAUNCHER_BEHAVIOR_REPORT.md

**Date:** 2026-06-12

## Problem

Launcher remained visible when Godot opened — polluted screen, memory, and UX.

## New behavior

On **Jogar** click, after successful game spawn:

| Setting `on_play` | Behavior |
|-------------------|----------|
| `minimize_to_tray` (default) | Window minimize + hide |
| `hide` | Window hide only |
| `close` | Window close |

Settings file: `%LOCALAPPDATA%/DarkWorld/launcher/settings.json`

## Close button behavior

Window close (X) → minimize to tray (does not exit launcher). Implemented via `CloseRequested` + `prevent_close` + hide.

## Implementation

- `launcher/src-tauri/src/tray.rs` — `hide_launcher_on_play()`, `setup_window_close_to_tray()`
- `launcher/src-tauri/src/settings.rs` — `OnPlayBehavior` enum
- `launcher/src-tauri/src/lib.rs` — `launch_game()` calls hide after spawn
- `launcher/src-tauri/tauri.conf.json` — window label `main`

## Pending human validation

Rogério: click Jogar → launcher must not remain on screen.
