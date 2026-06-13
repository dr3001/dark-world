# SHORTCUT FORENSICS REPORT

## Expected shortcuts (new Tauri installer)

| Location | Name | Target | WorkingDir |
|----------|------|--------|------------|
| Desktop | `Dark World.lnk` | `C:\Program Files\Dark World\DarkWorld-Launcher.exe` | (default) |
| Start Menu | `Dark World Launcher.lnk` | same | same |
| Start Menu | `Desinstalar.lnk` | `Uninstall.exe` | — |

## Risk: Rogério's machine

If Rogério installed from **cached old installer**:
- Same shortcut names may point to **Node CLI** `DarkWorld-Launcher.exe` (62MB console app)
- Previous **game installer** may have created shortcut to `DarkWorld.exe` instead
- Multiple installs → multiple `Dark World.lnk` with different targets

## Verification steps for Rogério

1. Right-click Desktop **Dark World** → Properties → **Target**
2. Must be: `"C:\Program Files\Dark World\DarkWorld-Launcher.exe"`
3. File size on disk: **~12.1 MB** (not ~60 MB)
4. Right-click → Run — must open **GUI window**, not console flash

## Classification

Server-side shortcut definition is correct in NSIS.  
Rogério likely executes shortcut to **old cached binary** until reinstall from cache-bust URL.
