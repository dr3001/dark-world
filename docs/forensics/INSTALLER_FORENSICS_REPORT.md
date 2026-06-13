# INSTALLER FORENSICS REPORT

## Files analyzed

| File | Size | SHA256 | Type |
|------|------|--------|------|
| Origin `DarkWorld-Launcher-Setup.exe` | 4,382,791 | `3252c01e65cfa473...` | NSIS → Tauri launcher |
| Cached (Rogério path) | 23,024,405 | `061a110250d2f227...` | NSIS → Node CLI launcher |
| Embedded launcher (origin) | 12,661,248 | `2e26d7c1010e8596...` | Tauri GUI |
| Embedded launcher (cached) | 62,664,008 | `82791f8c653afbfb...` | Node CLI |

## NSIS script: [`darkworld-launcher.nsi`](/opt/darkworld/scripts/darkworld-launcher.nsi)

| Item | Value |
|------|-------|
| OutFile | `/opt/darkworld/build/DarkWorld-Launcher-Setup.exe` |
| Embedded file | `build/launcher/DarkWorld-Launcher.exe` |
| InstallDir | `$PROGRAMFILES64\Dark World` |
| Desktop shortcut | `$DESKTOP\Dark World.lnk` → `DarkWorld-Launcher.exe` |
| Start Menu | `Dark World Launcher.lnk` → `DarkWorld-Launcher.exe` |
| Uninstall registry | `HKLM\...\Uninstall\DarkWorldLauncher` |
| Uninstall cleanup | Also removes legacy `DarkWorld` registry key |

## Confirmed

- **Origin installer contains Tauri** (12.6MB payload, no `node_modules` strings in embedded exe)
- **Cached installer contains Node CLI** (62MB payload)
- Rogério downloading default URL without `?v=` receives **old NSIS**

## Uninstall issues (Rogério)

Old game/launcher installers used registry key `DarkWorld`. New launcher uses `DarkWorldLauncher`.  
Windows "Add/Remove Programs" may show **two entries** or uninstall may not remove both.

Manual cleanup for Rogério:
1. Uninstall both "Dark World" and "Dark World Launcher" if present
2. Delete `C:\Program Files\Dark World\`
3. Delete `%LOCALAPPDATA%\DarkWorld\`
4. Delete Desktop `Dark World.lnk`

## Classification

Installer on origin is **correct**. Installer **served to Rogério via CF cache** was **wrong product**.
