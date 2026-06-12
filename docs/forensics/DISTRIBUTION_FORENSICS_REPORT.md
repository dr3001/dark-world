# DISTRIBUTION FORENSICS REPORT

**Date:** 2026-06-12  
**Investigator:** VPS forensic audit  
**Subject:** Rogério baixou novamente e viu o mesmo comportamento

## Executive summary

**ROOT CAUSE:** Cloudflare CDN cache (`cf-cache-status: HIT`) serving **stale Node CLI binaries** while origin disk and manifest already contain **Tauri GUI**.

Rogério's experience matches downloading the **cached old installer** (23MB), not the published new one (4.4MB).

## Hypothesis matrix

| # | Hypothesis | Verdict | Evidence |
|---|------------|---------|----------|
| 1 | CDN serving old file on disk | **REJECTED** | Origin disk has Tauri (12.6MB / 4.4MB) |
| 2 | Cloudflare cache stale | **CONFIRMED** | `cf-cache-status: HIT`, `age: 3204`, old `last-modified` |
| 3 | Browser cache | **POSSIBLE** | Secondary; CF cache is primary blocker |
| 4 | Installer embeds old launcher | **CONFIRMED for cached URL** | Cached setup = 23MB old NSIS payload |
| 5 | Shortcut points to old exe | **POSSIBLE on Rogério PC** | After old install; not server-side |
| 6 | Windows runs old launcher | **LIKELY** | Old install path + cached download |
| 7 | Tauri crash | **NOT TESTED by Rogério** | He never received Tauri binary via main URL |
| 8–11 | Runtime/bootstrap errors | **N/A** | Node CLI `process.exit(1)` explains flash |
| 12 | Uninstaller incomplete | **CONFIRMED risk** | Two registry keys: `DarkWorld` + `DarkWorldLauncher` |
| 13 | Multiple installations | **LIKELY on Rogério PC** | Old + new registry entries |
| 14 | Multiple shortcuts | **POSSIBLE** | Same desktop name "Dark World.lnk" |
| 15 | Manifest new, installer old via CF | **CONFIRMED** | Manifest MISS/new; Setup.exe HIT/old |

## Hash / size comparison

| Layer | Setup.exe size | Setup SHA256 prefix | Launcher size | Launcher SHA256 prefix |
|-------|----------------|---------------------|---------------|------------------------|
| **Origin disk** | 4,382,791 | `3252c01e` | 12,661,248 | `2e26d7c1` |
| **Manifest (public)** | 4,382,791 | `3252c01e` | 12,661,248 | `2e26d7c1` |
| **Public URL (no ?v=)** | **23,024,405** | **`061a1102`** | **62,664,008** | **`82791f8c`** |
| **Public URL (?v=3252c01e)** | 4,382,791 | `3252c01e` | — | — |
| **direct-download (bypass CF)** | 4,382,791 | `3252c01e` | — | — |

## Cloudflare headers (default URL)

```
content-length: 23024405
last-modified: Thu, 11 Jun 2026 23:21:11 GMT
cf-cache-status: HIT
cache-control: max-age=14400
age: 3204
```

## Why purge never ran

[`purge_cloudflare_cache.sh`](/opt/darkworld/scripts/purge_cloudflare_cache.sh) previously:
- Had **wrong URLs** (`zorionlabs.net/dark/...` not `dark.zorionlabs.net/downloads/...`)
- **Exited 0 without purging** when `CF_API_TOKEN` unset

Deploy reported success while users still received cached Node CLI.

## Fixes applied (2026-06-12)

1. Portal links now include `?v=<hash-prefix>` cache-bust
2. nginx `Cache-Control: no-cache, must-revalidate` on `/downloads/`
3. Purge script rewritten with correct URLs; fails loudly without token
4. User hint on home: "~4MB correct, ~23MB = old cache"

## Classification

**ROOT_CAUSE_FOUND** — Cloudflare stale cache + failed purge + manifest/URL mismatch for end users.
