# Launcher Node CLI — ARQUIVADO

**Status:** Deprecated em 2026-06-12 (Super Launcher Tribunal)

Este diretório continha o launcher empacotado via `pkg` — executável de **console sem GUI**.
Foi substituído pelo launcher **Tauri** em `/opt/darkworld/launcher/`.

## Por que foi retirado

- Usuários viam janela de console ou flash e fechamento
- Botões Jogar/Reparar existiam apenas no Tauri não publicado
- Duplicidade com manifest CDN (`DarkWorld-Launcher.exe` Node vs Tauri GUI)

## Build histórico

```bash
# NÃO USAR — apenas referência
cd /opt/darkworld/archive/launcher-node-cli
bash ../../scripts/build-launcher-node.sh  # script removido
```

## CDN

Arquivos publicados antes do tribunal usavam o binário Node. Após CI Tauri, o CDN serve
apenas o executável GUI compilado via GitHub Actions.
