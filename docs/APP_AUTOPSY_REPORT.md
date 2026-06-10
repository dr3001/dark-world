# APP AUTOPSY REPORT — Mission 7.2B

## Symptom
DarkWorld.dmg downloaded. Double-clicked. Nothing happens. App does not open.

## Root Cause: DMG is ISO9660, NOT HFS+

The DMG was created with  on Linux, which produces an **ISO9660** filesystem. macOS can mount ISO9660 volumes, but:

1. **No bundle bit**: macOS uses  extended attribute to identify .app bundles. ISO9660 has no support for macOS extended attributes.
2. **Result**: Finder treats DarkWorld.app as a **regular folder**, not an application. Double-click does nothing.
3. **No koly trailer**: A proper Apple DMG has a UDIF checksum trailer that macOS uses to verify the image. ISO9660 images lack this.

## Secondary Issue: No Code Signature

The .app was manually assembled on Linux without . On macOS 10.15+:
- All apps must be signed (at minimum ad-hoc)
- Without signature, macOS blocks execution even after quarantine removal
-  is macOS-only, cannot be run on Linux

## Binary Validation
| Check | Result |
|-------|--------|
| FAT universal binary | VALID (x86_64 + arm64) |
| Mach-O slices | VALID |
| .pck file present | YES (MacOS/ + Resources/) |
| Godot runtime | 4.6.3 |
| Info.plist | VALID (all required keys) |
| PkgInfo | VALID (APPL????) |
| Permissions | 0755 |

## Answers
| Question | Answer |
|----------|--------|
| O executavel existe? | SIM |
| O executavel esta sendo chamado? | NAO (DMG ISO9660 impede) |
| O bundle esta correto? | SIM |
| O Godot exportou corretamente? | PARCIAL (manual assembly) |
| Existe biblioteca ausente? | NAO |
| Existe problema de assinatura? | SIM (nao assinado) |
| Existe problema de arquitetura? | NAO |
| Existe problema de export template? | NAO |

## Fix
1. **Nao usar DMG criado no Linux** — usar .tar.gz ou .zip
2. **No Mac, apos extrair:** 
3. **Depois:** Botao direito → Abrir
