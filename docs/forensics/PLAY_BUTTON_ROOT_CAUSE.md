# PLAY_BUTTON_ROOT_CAUSE.md

**Date:** 2026-06-12  
**Status:** FIXED (code)

## Symptom

Botão **Jogar** não habilitava após atualização concluída. Usuário precisava fechar e reabrir o launcher.

## Root cause (confirmed)

### Primary bug — stale `update_required`

Location: `launcher/src-tauri/src/lib.rs` lines ~114 and ~202-207 (pre-fix)

```rust
state.update_required = manifest.force_update || below_minimum;
// ... download and apply ...
let play_ok = ... && !state.update_required && ...;  // still true after successful update
```

When `local != manifest.game_version`, `below_minimum` or version mismatch set `update_required = true`. After update, local equals remote but flag was never cleared.

### Secondary UX — UI disable on click

`launcher/ui/main.js` disables Play on click. Fixed message on success: "Jogo em execução. Launcher na bandeja."

Progress callbacks during download emit intermediate states with `can_play: false` — acceptable; final emit must set `can_play: true` (now fixed).

## Race conditions assessed

| Area | Finding |
|------|---------|
| `bootstrapping` AtomicBool | Prevents double bootstrap — OK |
| Progress callback clones `base_state` | Does not affect final emit |
| `repair_game` re-enables repair btn | Play state depends on final emit — fixed |

## Fix commit scope

- `launcher/src-tauri/src/lib.rs` — recalculate `update_required` + explicit ready message
- `launcher/ui/main.js` — post-launch message

## Human retest

Rogério must: open launcher → let update to v5.0.6 complete → confirm **Jogar** enables without closing app.
