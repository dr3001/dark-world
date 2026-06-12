# ROGERIO RETEST — UX Tribunal v5.0.6

**Classification target:** READY_FOR_HUMAN_RETEST  
**Current:** WORKING_WITH_GAPS (launcher binary pending CI)

## Download verification

| Check | Expected |
|-------|----------|
| Setup size | ~4.4 MB (Tauri, not 23 MB Node CLI) |
| Game version after update | **5.0.6** |
| Launcher version (after CI) | **1.0.1** |

Home: `https://dark.zorionlabs.net/`  
Use cache-bust link if stale: `DarkWorld-Launcher-Setup.exe?v=3252c01e`

Game manifest: `https://dark.zorionlabs.net/downloads/launcher/manifest.json`

## YES/NO checklist (Rogério fills)

| Gate | Rogério |
|------|---------|
| Launcher atualiza sem reiniciar? | |
| Botão Jogar libera automaticamente? | |
| Launcher minimiza para tray? | |
| Console desapareceu? | |
| UID Warning eliminado? | |
| Login funcionando? | |
| Registro funcionando? | |
| Recuperação de senha funcionando? | |
| Mundo carregado corretamente? | |
| NPCs visíveis? | |
| Cidade visível? | |
| Castelo visível? | |
| Placeholders removidos? | |
| Root cause dos bugs encontrada? | SIM (see forensics/) |

## Screenshots required

1. Launcher after update — Jogar enabled
2. Game running — no console
3. Login screen
4. World spawn — structures visible
5. Tray icon after Jogar

## Logs if failure

- `%LOCALAPPDATA%/DarkWorld/logs/launcher/launcher.log`
- `%LOCALAPPDATA%/DarkWorld/logs/game/game.log`

## Reports

All forensics in `/opt/darkworld/docs/forensics/`:

- UPDATE_FLOW_REPORT.md
- PLAY_BUTTON_ROOT_CAUSE.md
- LAUNCHER_BEHAVIOR_REPORT.md
- TRAY_IMPLEMENTATION_REPORT.md
- LOGGING_SYSTEM_REPORT.md
- RESOURCE_VALIDATION_REPORT.md
- AUTH_FLOW_REPORT.md
- EMPTY_WORLD_ROOT_CAUSE.md
- VISUAL_VALIDATION_REPORT.md
- HUMAN_E2E_REPORT.md
- PLACEHOLDER_PURGE_REPORT.md
