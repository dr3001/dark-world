# HUMAN_E2E_REPORT.md

**Date:** 2026-06-12  
**Simulated by:** VPS automated + code path review  
**Human proof:** NOT YET

## Simulated flow

| Step | Automated | Expected human |
|------|-----------|----------------|
| 1. Install launcher setup (~4MB Tauri) | CDN hash verified | Rogério download |
| 2. Open launcher GUI | N/A (Windows) | Window not console |
| 3. Bootstrap / update to v5.0.6 | Manifest published | Progress bar → complete |
| 4. Jogar enables without restart | **Code fix applied** | Button clickable |
| 5. Click Jogar | Code: hide + tray | Launcher off screen |
| 6. Game opens | Release exe exported | No Godot console |
| 7. Login | Main.gd flow | Email/password |
| 8. Enter world | World.gd builders | Structures visible |
| 9. Walk + menus I/J | Code present | Functional |
| 10. Close game from tray | kill_game command | Process ends |
| 11. Reopen from tray | show_launcher_window | Window returns |

## Blockers for full E2E sign-off

1. **Launcher v1.0.1** Windows binary not yet on CDN (source ready; needs CI)
2. **Rogério** must execute on physical Windows PC
3. **Cloudflare purge** — `CF_API_TOKEN` not set; use cache-bust URLs

## Cache-bust reference (2026-06-12)

| Artifact | Hash prefix |
|----------|-------------|
| Game zip v5.0.6 | `ff651faa` |
| Launcher setup (old 1.0.0) | `3252c01e` |

After launcher CI: update portal `?v=` on home page.

## Verdict

**READY_FOR_HUMAN_RETEST** (code + game published) — not **READY_FOR_MULTIPLAYER_TEST**.
