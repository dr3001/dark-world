# UNINSTALL VALIDATION REPORT

## New launcher uninstaller ([`darkworld-launcher.nsi`](/opt/darkworld/scripts/darkworld-launcher.nsi))

Removes:
- `DarkWorld-Launcher.exe`
- `DarkWorld.exe` (legacy)
- `version.json`, `Uninstall.exe`
- Desktop + Start Menu shortcuts
- Registry: `DarkWorldLauncher` **and** legacy `DarkWorld`

Does **NOT** remove:
- `%LOCALAPPDATA%\DarkWorld\game\` (intentional — preserves game data)
- `%LOCALAPPDATA%\DarkWorld\cache\`

## Why Rogério failed to uninstall

1. **Wrong registry key** — old install registered as "Dark World" (game), new as "Dark World Launcher"
2. Two entries in Settings → Apps; uninstalling one leaves the other
3. 62MB Node exe may remain if uninstaller targeted wrong key

## Manual full removal

```
Settings → Apps → Uninstall all Dark World entries
rmdir /s "C:\Program Files\Dark World"
rmdir /s "%LOCALAPPDATA%\DarkWorld"
del "%USERPROFILE%\Desktop\Dark World.lnk"
```

## Classification

Uninstaller improved but Rogério needs **manual cleanup** before clean Tauri install.
