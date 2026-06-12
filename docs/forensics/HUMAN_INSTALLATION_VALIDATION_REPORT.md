# HUMAN INSTALLATION VALIDATION REPORT

## Server-side simulated flow (2026-06-12)

| Step | Default URL (Rogério path) | Cache-bust URL (?v=3252c01e) |
|------|---------------------------|------------------------------|
| Home link | Was `/downloads/...Setup.exe` | Now `...Setup.exe?v=3252c01e` |
| Download size | **23,024,405 FAIL** | **4,382,791 OK** |
| Download hash | `061a1102...` FAIL | `3252c01e...` OK |
| Product | Node CLI | Tauri GUI |
| GUI visible | **NO** (console flash) | **Expected YES** (not verified on Windows) |

## Manifest vs download consistency

| Check | Result |
|-------|--------|
| Manifest says setup = 4.4MB | OK |
| Default URL serves setup = 23MB | **FAIL — CF cache** |
| Cache-bust URL matches manifest | OK |

## Human test status

| Tester | GUI screenshot | Status |
|--------|----------------|--------|
| Rogério (prior) | None | FAIL — got cached Node CLI |
| Rogério (re-test) | **Pending** | Must use new home link |

## Instructions for Rogério

1. Full manual uninstall (see UNINSTALL_VALIDATION_REPORT.md)
2. Open https://dark.zorionlabs.net
3. Click **Baixar Launcher** — URL must contain `?v=3252c01e`
4. **Before install:** file size ~**4.2 MB** (not 23 MB)
5. Install → open → screenshot GUI
6. Send screenshot to confirm READY_FOR_HUMAN_RETEST

## Classification

**FIXED_WAITING_HUMAN_TEST** — server fix deployed; human confirmation pending.
