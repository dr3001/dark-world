# LEGACY INSTALLATION REPORT

## Expected legacy artifacts on Rogério Windows PC

| Path | Old (Node CLI) | New (Tauri) |
|------|----------------|-------------|
| `C:\Program Files\Dark World\DarkWorld-Launcher.exe` | 62,664,008 bytes | 12,661,248 bytes |
| `C:\Program Files\Dark World\DarkWorld.exe` | Possible from game installer | Should not exist |
| `%LOCALAPPDATA%\DarkWorld\` | Cache, game, version.json | Same structure |
| Registry uninstall | `DarkWorld` and/or `DarkWorldLauncher` | `DarkWorldLauncher` only |

## Node CLI archived on server

[`/opt/darkworld/archive/launcher-node-cli/launcher.mjs`](/opt/darkworld/archive/launcher-node-cli/launcher.mjs) — console app, exits on error.

## Why Rogério cannot uninstall cleanly

1. Two different uninstall registry keys from different installer generations
2. Old uninstall may not remove files installed by newer package (or vice versa)
3. Partial upgrade leaves 62MB Node exe in Program Files

## Recommended clean install procedure

```
1. Settings → Apps → uninstall ALL "Dark World" entries
2. Delete C:\Program Files\Dark World\
3. Delete %LOCALAPPDATA%\DarkWorld\
4. Delete Desktop Dark World.lnk
5. Download from home (link with ?v=3252c01e)
6. Verify download size ~4.2 MB BEFORE installing
7. Install and open
```

## Classification

**Multiple legacy installations likely** on Rogério machine (Hypotheses 12, 13, 14).
