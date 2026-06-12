# ROGERIO RETEST — Foundation P0 v5.0.6 / Launcher 1.0.1

**Classification target:** READY_FOR_HUMAN_RETEST  
**Automated foundation audit:** 12/12 PASS  
**Human validation:** REQUIRED

## Download (cache-bust obrigatório)

| Artifact | URL | Hash prefix |
|----------|-----|-------------|
| Launcher Setup | `https://dark.zorionlabs.net/downloads/DarkWorld-Launcher-Setup.exe?v=6aeae7a1` | ~4.4 MB |
| Game manifest | `https://dark.zorionlabs.net/downloads/launcher/manifest.json` | game **5.0.6** |

Setup ~23 MB = cache antigo (Node CLI). Setup ~4.4 MB = Tauri correto.

## Ciclo completo a testar

1. Instalar / abrir launcher
2. Update para **v5.0.6** — **Jogar** habilita sem fechar
3. Jogar — launcher vai para tray, sem console Godot
4. Login — entrar no mundo
5. Ver plaza/vila/castelo no spawn (não só campo verde)
6. Fechar jogo — **launcher reaparece** (novo)
7. Reabrir jogo pelo launcher
8. Esqueci senha — portal funciona

## YES/NO checklist

| Gate | Rogério |
|------|---------|
| Launcher atualiza sem reiniciar? | |
| Botão Jogar libera automaticamente? | |
| Launcher minimiza para tray? | |
| Console desapareceu? | |
| Jogo fecha → launcher volta? | |
| Login funcionando? | |
| Registro funcionando? | |
| Recuperação de senha? | |
| Mundo carregado? | |
| NPCs visíveis? | |
| Cidade visível? | |
| Castelo visível? | |

## Logs

- `%LOCALAPPDATA%/DarkWorld/logs/launcher/launcher.log`
- `%LOCALAPPDATA%/DarkWorld/logs/game/game.log`

## Relatório completo

[`docs/forensics/FOUNDATION_STABILIZATION_REPORT.md`](/opt/darkworld/docs/forensics/FOUNDATION_STABILIZATION_REPORT.md)
