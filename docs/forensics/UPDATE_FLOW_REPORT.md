# UPDATE_FLOW_REPORT.md

**Date:** 2026-06-12  
**Classification:** Fix applied — pending human retest

## Summary

Rogério reported that after a successful update, the Play button stayed disabled until closing and reopening the launcher.

## Root cause

`update_required` was set before download in `run_bootstrap()` but never recalculated after `write_local_version()`. Final `can_play` required `!update_required`, so it remained false.

## Fix

File: `launcher/src-tauri/src/lib.rs`

After update completes, recalculate:

```rust
let updated_local = read_local_version();
state.update_required = manifest.force_update || version_lt(&updated_local, min_version);
state.can_play = find_game_executable().is_some() && server_online && !state.update_required && updated_local == manifest.game_version;
```

## Expected flow (post-fix)

1. Launcher starts → bootstrap runs
2. Version mismatch detected → download → verify → apply
3. `local_version` written → `update_required` cleared → `can_play: true` emitted
4. UI enables **Jogar** without restart

## Verification

| Step | Automated | Human |
|------|-----------|-------|
| Update without restart | Code review PASS | Rogério required |
| Play enables after update | Logic PASS | Rogério required |

## Version

- Game: **5.0.6** (release export, published CDN)
- Launcher: **1.0.1** (code; Windows binary pending CI rebuild)
