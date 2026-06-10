# MAC BUILD FAILURE REPORT — Mission 7.2B

## Failure Chain

1. Godot  fails on Linux due to bundle identifier parse error
2. Manual .app assembly works but misses  step (macOS-only tool)
3. DMG created with  produces ISO9660 instead of HFS+
4. .app inside ISO9660 loses macOS bundle metadata
5. Double-click does nothing

## Permanent Fixes Needed

### For Linux-based CI/CD:
- Export .app folder (manual assembly works)
- Package as .tar.gz (preserves Unix metadata)
- Cannot sign on Linux
- Cannot create real DMG on Linux

### For Production:
- Move macOS build to a Mac runner (GitHub Actions macOS runner)
- Godot export on Mac → proper Info.plist, codesign, DMG creation
- Or: Build .app on Linux, transfer to Mac for signing + DMG

## Current Workaround
Distribute as .tar.gz with instructions:

