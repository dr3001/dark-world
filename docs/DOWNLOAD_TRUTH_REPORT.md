# MISSION 8 — DOWNLOAD TRUTH REPORT

## Current Downloads
| File | Size | Type | Status |
|------|------|------|--------|
| DarkWorld-Mac.zip (canonical) | 59MB | App bundle em zip | FUNCIONAL (?v=2 cache bust) |
| DarkWorld-Mac-v0.2.0.zip | 59MB | App bundle em zip | FUNCIONAL |
| SHA256SUMS.txt | 89B | Checksum | FUNCIONAL |
| Version.txt | 186B | Version info | FUNCIONAL |
| BuildInfo.txt | 269B | Build details | FUNCIONAL |
| CHANGELOG.md | 369B | Changelog | FUNCIONAL |
| README.md | 507B | Install guide | FUNCIONAL |

## App Bundle Contents
- DarkWorld.app (universal binary: x86_64 + arm64)
- Godot 4.6.3 runtime included
- DarkWorld.pck (game data, 22KB, clean build)
- Info.plist (bundle ID: com.darkworld.game)
- icon.icns (app icon)

## Truth Assessment
| Pergunta | Resposta |
|----------|----------|
| Existe instalador? | SIM — DarkWorld.app (zip) |
| E projeto Godot? | NAO — app nativo |
| Requer Godot Editor? | NAO |
| Requer terminal? | NAO |
| Tamanho coerente? | SIM — 59MB (184MB engine + 22KB game) |
| SHA256 existe? | SIM |
| Universal binary? | SIM (Intel + Apple Silicon) |
