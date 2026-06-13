# SMARTSCREEN ANALYSIS REPORT

## Why browser marked download as dangerous

| Factor | Status |
|--------|--------|
| Code signing | **Unsigned** — no Authenticode signature |
| Publisher reputation | Unknown/new binary |
| SmartScreen | Flags unsigned executables from unknown publishers |
| Chrome/Safe Browsing | May flag new/rare download URLs |
| Defender | Heuristic on unsigned NSIS + embedded exe |

## File characteristics

| Version | Size | Notes |
|---------|------|-------|
| Old Node CLI setup | 23 MB | Large packed Node runtime — higher heuristic score |
| New Tauri setup | 4.4 MB | Smaller, still unsigned |

## This is expected

Unsigned indie game launchers commonly trigger:
- "This file isn't commonly downloaded"
- SmartScreen "Unknown publisher"
- Chrome "Suspicious file"

## Mitigation (future, out of scope)

- Authenticode signing certificate (~$200-400/yr)
- Extended validation + reputation building over time

## Not a distribution bug

SmartScreen warning is **orthogonal** to cache issue. Rogério can still click "Keep" / "Run anyway".

## Classification

SmartScreen warnings are **expected** for unsigned launcher; do not indicate malicious file by themselves.
