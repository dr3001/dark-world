# Rogério Re-Test Protocol — Pós-publicação Tauri GUI

**Data publicação CDN:** 2026-06-12T00:12:16Z  
**CI run:** 27385188556 (commit f853e00)  
**Classificação crash anterior:** CRASH_REPRODUCED — Node CLI no CDN (não Tauri)

## Causa do crash anterior

Rogério baixou da home → `DarkWorld-Launcher-Setup.exe` instalou **Node CLI** (62MB, hash `82791f8c...`).  
App de console com `process.exit(1)` em erro → janela abre e fecha = crash imediato percebido.

## Binário novo no CDN (evidência servidor)

| Campo | Antigo (Node CLI) | Novo (Tauri GUI) |
|-------|-------------------|------------------|
| Arquivo | DarkWorld-Launcher.exe | DarkWorld-Launcher.exe |
| Tamanho | 62.664.008 bytes | **12.661.248 bytes** |
| SHA256 | `82791f8c653afbfb...` | **`2e26d7c1010e85965d92750b1524a942b7993879d88c70c97d36c43049f614fe`** |
| Installer SHA256 | `061a110250d2f227...` | **`3252c01e65cfa47309aa24c424252e75460cad088e72196226d56be2b43d02dd`** |
| Strings node | presentes | **ausentes** |
| URL | https://dark.zorionlabs.net/downloads/DarkWorld-Launcher-Setup.exe | mesma URL, **conteúdo novo** |

## Passos obrigatórios (Windows)

1. **Desinstalar** "Dark World Launcher" em Adicionar/Remover Programas
2. Apagar `%LOCALAPPDATA%\DarkWorld\` se existir (opcional, limpa cache)
3. Baixar **novo** installer da home: https://dark.zorionlabs.net
4. **Verificar hash** antes de instalar:
   ```powershell
   Get-FileHash "$env:USERPROFILE\Downloads\DarkWorld-Launcher-Setup.exe" -Algorithm SHA256
   ```
   Deve começar com `3252c01e65cfa473...` (não `061a1102...`)
5. Instalar → abrir atalho Desktop
6. **Esperado:** janela GUI 560×640, título "Dark World Launcher", botões Jogar/Reparar/⚙
7. **Screenshot obrigatório** → salvar em `evidence/rogério-windows-YYYYMMDD.png`

## Se ainda crashar (Tauri confirmado)

Executar no CMD:
```cmd
"C:\Program Files\Dark World\DarkWorld-Launcher.exe"
```
Capturar saída. Verificar Event Viewer → Windows Logs → Application.

Verificar WebView2 Runtime instalado (Settings → Apps → "Microsoft Edge WebView2").

## macOS (best-effort)

Novo tarball hash: `a97bdeb44663e996...` (7.5MB, CI run f853e00)  
URL: https://dark.zorionlabs.net/downloads/DarkWorld-Launcher-mac.tar.gz

## Screenshot

**PENDENTE** — aguardando Rogério.

## Classificação atual

**READY_FOR_HUMAN_RETEST** — binário Tauri publicado no CDN; teste humano com screenshot pendente.
