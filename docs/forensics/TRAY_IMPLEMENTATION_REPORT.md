# TRAY_IMPLEMENTATION_REPORT.md

**Date:** 2026-06-12

## Implementation

Tauri 2 core tray via `TrayIconBuilder::with_id("main-tray")`.

### Menu items

| ID | Label | Action |
|----|-------|--------|
| open_launcher | Abrir launcher | Show + focus main window |
| repair | Reparar jogo | Async `run_bootstrap(force_repair=true)` |
| view_logs | Ver logs | Open `%LOCALAPPDATA%/DarkWorld/logs/launcher/` |
| open_folder | Abrir pasta do jogo | Open game install dir |
| kill_game | Fechar jogo | Kill tracked Child PID |
| quit_launcher | Sair do launcher | `app.exit(0)` |

### Status tooltip

Updates with server online/offline + local game version.

### Game process tracking

`AppState.game_child: Mutex<Option<Child>>` set in `launch_game()`, cleared in `kill_game()`.

### Permissions

`launcher/src-tauri/capabilities/default.json` — added `core:tray:default`, window hide/minimize/show/focus.

### Cargo feature

`tauri = { features = ["tray-icon"] }`

## Deployment note

Tray code is in launcher **v1.0.1** source. CDN launcher binary is still **v1.0.0** until Windows CI rebuild and `deploy-launcher-artifacts.sh`.

## Human retest

Confirm tray icon appears after Jogar; menu actions work on Windows.
