# MAC BUILD FAILURE — Root Cause

## Failure: "App is damaged" on macOS

### Chain of events:
1. Build happens on Linux (Hetzner VPS)
2. Godot macOS export fails (bundle identifier parse error)
3. Manual .app assembly works structurally
4. .app has ZERO code signature
5. macOS blocks unsigned apps with "damaged" message
6. `codesign` tool does not exist on Linux
7. Dead end — cannot produce signed .app from Linux

### Why Godot export fails:
Godot 4.x ConfigFile parser cannot read `application/identifier`
from export_presets.cfg correctly. The value `com.darkworld.game`
is either parsed as empty (identifier missing error) or as section
separators (parse error). Multiple format variations were tried.

### Impact:
- Cannot run `--export-release macOS` (Godot limitation)
- Cannot run `codesign` (Linux limitation)
- Cannot run `hdiutil` (Linux limitation)
- Manual assembly produces valid but unsigned .app

### Resolution path:
1. SHORT TERM: User runs codesign manually on Mac
2. LONG TERM: Move macOS build to a Mac/GitHub Actions macOS runner
