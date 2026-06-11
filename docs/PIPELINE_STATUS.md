# PIPELINE STATUS — Dark World

## CI/CD Pipelines (GitHub Actions)

| Pipeline | File | Trigger | Status |
|----------|------|---------|--------|
| Windows Build | build-windows.yml | push main/develop | READY |
| macOS Build | build-mac.yml | push main/develop | READY |
| Release | release.yml | tag v* | READY |

## Pipeline Flow
```
git push → GitHub Actions
  ├── build-windows → DarkWorld-Windows.zip (artifact)
  ├── build-mac → DarkWorld-Mac.tar.gz + .zip (artifact)
  └── release (on tag) → GitHub Release + SHA256SUMS
```

## Current Limitations
- macOS builds are UNSIGNED (codesign requires macOS runner)
- DMG creation not possible on Linux runner
- No auto-deploy to downloads server (manual step)

## Answers

| Question | Answer |
|----------|--------|
| Hoje e possivel buildar automaticamente? | SIM (Windows + Mac unsigned) |
| O que falta? | Apple Developer ($99/ano) + macOS runner para signed builds |
| Quanto custa? | GitHub Actions: FREE (public repo). Apple Dev: $99/ano |
| Precisa Apple Developer? | SIM — para notarizacao e assinatura |
| Quando sera obrigatorio? | Antes do lancamento publico (Alpha) |
| Pipeline suporta futuras atualizacoes? | SIM |
| Suporta launcher futuramente? | SIM |
| Suporta sistema de patches? | SIM (version.json + manifest) |
| Suporta controle de versao? | SIM (Git tags + version.json) |
