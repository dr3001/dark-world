# Dark World Launcher — Teste Humano E2E (obrigatório)

**Versão alvo:** 5.0.5 / Launcher 1.0.0  
**Data checklist:** _______________  
**Tester:** _______________

> Não marcar release como entregue sem evidência (screenshot ou vídeo) dos passos abaixo.

---

## Pré-requisitos

- [ ] Home `https://dark.zorionlabs.net` mostra CTA **Dark World Launcher** (não game installer)
- [ ] `DarkWorld-Launcher-Setup.exe` no CDN é build **Tauri GUI** (janela gráfica, não console)
- [ ] Manifest `https://dark.zorionlabs.net/downloads/launcher/manifest.json` sem `DarkWorld-Windows-Setup.exe`

---

## Windows

| # | Passo | OK | Evidência |
|---|-------|----|-----------|
| W1 | Baixar `DarkWorld-Launcher-Setup.exe` da home | ☐ | |
| W2 | Instalar → atalho Desktop "Dark World" | ☐ | |
| W3 | Abrir launcher → **janela GUI** (título "Dark World Launcher") | ☐ | screenshot |
| W4 | Ver status servidor ONLINE e jogadores online | ☐ | |
| W5 | Ver changelog carregado | ☐ | |
| W6 | Primeira execução: barra de progresso download ~117MB | ☐ | screenshot |
| W7 | Botão **Jogar** habilitado após download | ☐ | |
| W8 | Clicar Jogar → `DarkWorld.exe` abre | ☐ | |
| W9 | Login com conta válida → entrar no mundo | ☐ | |
| W10 | Botão **Reparar** re-baixa e valida hash | ☐ | |
| W11 | Botão **⚙ Configurações** abre pasta do jogo | ☐ | |

**Arquivo evidência Windows:** `evidence/windows-launcher-YYYYMMDD.png` ou `.mp4`

---

## macOS

| # | Passo | OK | Evidência |
|---|-------|----|-----------|
| M1 | Baixar `DarkWorld-Launcher-mac.tar.gz` | ☐ | |
| M2 | Extrair → `Dark World Launcher.app` | ☐ | |
| M3 | Se Gatekeeper bloquear: `xattr -cr` documentado | ☐ | |
| M4 | Abrir app → GUI (não terminal) | ☐ | screenshot |
| M5 | Download/atualização com progress bar | ☐ | |
| M6 | Jogar abre cliente Godot | ☐ | |
| M7 | Login funcional | ☐ | |

**Arquivo evidência macOS:** `evidence/macos-launcher-YYYYMMDD.png`

---

## Validação automatizada (VPS — não substitui humano)

```bash
bash /opt/darkworld/scripts/validate-all.sh
python3 /opt/darkworld/scripts/validate-manifest.py
curl -s https://dark.zorionlabs.net/dw-api/api/launcher/status | jq .
```

---

## Veredicto

| Resultado | Assinatura | Data |
|-----------|------------|------|
| ☐ APROVADO — produto launcher entregue | | |
| ☐ REPROVADO — listar falhas: | | |

### Falhas encontradas

1. 
2. 

---

## Evidência coletada nesta sessão (servidor)

| Check | Status | Evidência |
|-------|--------|-----------|
| Portal home CTA launcher | OK | `/var/www/zorionlabs/dark/index.html` → `DarkWorld-Launcher-Setup.exe` |
| Game installer removido da home | OK | `DarkWorld-Windows-Setup.exe` → `/downloads/archive/` |
| Godot re-export v5.0.5 | OK | portable.zip `2026-06-11 23:31 UTC`, hash `0cbc8c38...` |
| Manifest 5 arquivos válidos | OK | `validate-manifest.py` passou |
| API launcher status | OK | `game_version: 5.0.5`, `server: online` |
| Node CLI arquivado | OK | `/opt/darkworld/archive/launcher-node-cli/` |
| Tauri GUI no CDN | **PENDENTE** | CI run #16+ — executar `bash /opt/darkworld/scripts/fetch-github-launcher.sh` |
| Teste humano Win/Mac | **PENDENTE** | Requer screenshot do tester |

**Comando pós-CI:** `bash /opt/darkworld/scripts/fetch-github-launcher.sh`

**Status automatizado:** Infra + portal + jogo OK. Binário Tauri aguardando CI (~10 min).
