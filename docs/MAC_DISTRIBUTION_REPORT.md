# MAC DISTRIBUTION REPORT — Mission 7.3

## Published Formats

| Format | URL | Size |
|--------|-----|------|
| DarkWorld.app (ZIP) | /dark/downloads/DarkWorld-Mac.zip | 59MB |
| DarkWorld.dmg | /dark/downloads/DarkWorld.dmg | 177MB |
| DarkWorld-Mac.tar.gz | /dark/downloads/DarkWorld-Mac.tar.gz | 59MB |

## Architecture Support
| Platform | Status |
|----------|--------|
| Intel (x86_64) | YES |
| Apple Silicon (arm64) | YES |
| M1/M2/M3/M4 | YES |

## Validation
| Test | Result |
|------|--------|
| file DarkWorld.app | FAT universal binary |
| CFBundleIdentifier | com.darkworld.game |
| CFBundleExecutable | DarkWorld |
| Info.plist valid | YES |
| PkgInfo valid | YES |
| Permissions | 0755 (executable) |
| Gatekeeper | BLOCKED (unsigned) |

## Answers
| Question | Answer |
|----------|--------|
| Existe DarkWorld.app publico? | SIM |
| Existe DarkWorld.dmg publico? | SIM |
| Existe ZIP publico? | SIM |
| Mac consegue baixar apenas o APP? | SIM (.app no zip) |
| Mac precisa de Godot? | NAO |
| Mac precisa de terminal? | SIM (xattr -cr na primeira vez) |
| Mac consegue abrir diretamente? | PARCIAL — requer xattr/right-click |
