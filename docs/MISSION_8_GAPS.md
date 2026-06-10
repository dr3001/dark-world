# MISSION 8 — GAPS

## Critical

| Gap | Platform | Reason | Fix |
|-----|----------|--------|-----|
| No zero-friction Mac app | Mac | codesign/hdiutil only on macOS | Build on Mac |
| DMG creation impossible | Mac | hdiutil is macOS-only | Build on Mac |
| App signing impossible | Mac | codesign is macOS-only | Build on Mac |

## Medium

| Gap | Platform | Fix |
|-----|----------|-----|
| Godot export fails on Linux | All | Fix ConfigFile parser or use Mac |
| No auto-updater | All | Future feature |
| No CDN for downloads | All | Future (Cloudflare R2, etc.) |
| SSL self-signed on origin | Server | Let's Encrypt or Cloudflare Origin cert |

## Low

| Gap | Platform | Fix |
|-----|----------|-----|
| Windows firewall prompt | Windows | Sign .exe with EV certificate |
| Windows SmartScreen warning | Windows | Build reputation over time |
