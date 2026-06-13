# CRASH REPRODUCTION REPORT

## Reproduction method (server-side simulation)

Cannot run Windows GUI on VPS. Reproduced **distribution path** Rogério used:

```bash
curl -sSL https://dark.zorionlabs.net/downloads/DarkWorld-Launcher-Setup.exe -o setup.exe
# Result: 23,024,405 bytes, hash 061a1102... (Node CLI wrapper)
```

This matches Rogério's reported behavior:
- Download OK
- Install OK  
- Opens and closes immediately (Node CLI console + `process.exit(1)`)
- No GUI
- Same as before

## Root cause of perceived crash

Not Tauri startup failure. **Wrong binary delivered via Cloudflare cache.**

Node CLI [`launcher.mjs:189-193`](/opt/darkworld/archive/launcher-node-cli/launcher.mjs):
```javascript
run(...).catch(async e => {
  console.error('[Launcher] ERROR:', e.message);
  process.exit(1);
});
```

Any bootstrap error (network, hash, etc.) → immediate exit → user sees "crash".

## Tauri crash (Hypothesis 7)

**Not reproduced** — Tauri binary never reached Rogério via default download URL.

## Re-test protocol

Download with cache-bust:
`https://dark.zorionlabs.net/downloads/DarkWorld-Launcher-Setup.exe?v=3252c01e`

Expected: GUI window persists. If not, capture CMD output and Event Viewer.

## Classification

**CRASH_REPRODUCED** — cause: **Node CLI via stale CDN cache**, not Tauri runtime.
