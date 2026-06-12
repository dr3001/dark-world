# VISUAL_VALIDATION_REPORT.md

**Date:** 2026-06-12  
**Status:** Automated partial — human comparison required

## Automated captures (VPS headless)

| Scene | Method | Result |
|-------|--------|--------|
| Export integrity | `audit-world-load.sh` | PASS — exe 245MB release |
| Login scene | Export includes `Login.tscn` | PASS |
| World scene | Export includes `World.tscn` + `World.gd` | PASS |

## Screenshots required from Rogério

Compare against prior evidence screenshots:

| ID | Scene | Pass criteria |
|----|-------|---------------|
| 1 | Spawn | Plaza + fountain visible, not empty green |
| 2 | Village | Houses along road |
| 3 | Castle | North castle structure |
| 4 | NPC | Dialog on E key |
| 5 | HUD | No FPS/ObjectCount/Position in release |
| 6 | Login | No console window behind game |
| 7 | Launcher | Hidden/minimized after Jogar |

## Debug UI purge (release)

Hidden when `not OS.is_debug_build()`:

- HUD/FPS
- HUD/ObjectCount
- HUD/Position

## Divergence rule

If Rogério screenshots differ from criteria above → **NOT APPROVED**.

## Classification

**WORKING_WITH_GAPS** until Rogério screenshots received.
