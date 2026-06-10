# MISSION 8 — GODOT CLIENT TRUTH REPORT

## Project Structure
| Item | Status |
|------|--------|
| project.godot | OK — v0.2.0, main scene Login.tscn |
| scenes/Login.tscn | OK — tela de login com botoes |
| scenes/World.tscn | OK — mundo 3D com HUD |
| scenes/Afterlife.tscn | OK — tela pos-morte |
| scenes/Main.tscn | OK — cena 3D base |
| scripts/Main.gd | OK — controlador principal (CORRIGIDO) |
| scripts/NetworkClient.gd | OK — cliente HTTP para World Engine |
| scripts/World.gd | OK — logica do mundo |
| scripts/PlayerController.gd | OK — controle WASD |
| scripts/EntitySpawner.gd | OK — spawn de entidades |
| scripts/Afterlife.gd | OK — tela afterlife |
| scripts/WorldState.gd | OK — estado do mundo |
| scripts/Login.gd | OK — tela de login |

## Corrections Applied (Mission 7)
- Main.gd: fixed missing @onready var declarations
- Afterlife.tscn: removed invalid light_color property
- Login.tscn: removed invalid theme_override_colors
- World.tscn: removed invalid theme_override_colors
- Main.tscn: removed invalid SubResource reference

## Export Config
- export_presets.cfg: macOS preset configured
- Bundle ID: com.darkworld.game
- Godot: 4.6.3 stable
- Templates: 4.6.3 macOS universal

## Client-Server Connection
- World Engine URL: http://5.78.142.138:9000 (hardcoded in NetworkClient.gd)
- Endpoints used: /worlds, /test/account, /test/character, /characters, /entities, /events, /dragons
- Auth: None (test endpoints, Nakama planned)

## Issues
| Issue | Severity | Status |
|-------|----------|--------|
| Hardcoded IP 5.78.142.138 | MEDIA | PENDENTE (should use domain) |
| No HTTPS for game client | BAIXA | PENDENTE |
| Test endpoints (no real auth) | ALTA | PENDENTE (Nakama integration pending) |
