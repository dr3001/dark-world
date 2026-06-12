# WEBVIEW2 REPORT

## Tauri configuration

[`tauri.conf.json`](/opt/darkworld/launcher/src-tauri/tauri.conf.json):
```json
"webviewInstallMode": { "type": "embedBootstrapper" }
```

Tauri Windows bundle includes WebView2 bootstrapper in NSIS/MSI builds.

## Status for Rogério

**Not applicable to observed crash** — Rogério ran Node CLI, not Tauri.

## If Tauri fails after correct install

1. Check `Settings → Apps → Microsoft Edge WebView2 Runtime`
2. Install from Microsoft if missing
3. Tauri with `embedBootstrapper` should install WebView2 during setup

## Classification

WebView2 investigation **deferred** until Rogério confirms Tauri binary installed (~12MB exe).
