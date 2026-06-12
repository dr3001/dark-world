# Rogério — CAUSA RAIZ ENCONTRADA + Re-teste Obrigatório

**Data:** 2026-06-12  
**Classificação:** ROOT_CAUSE_FOUND → FIXED_WAITING_HUMAN_TEST

## Por que você viu o mesmo comportamento

Você baixou da home, mas **Cloudflare entregou o instalador ANTIGO em cache**:

| | Instalador correto (servidor) | O que você recebeu (cache CF) |
|--|-------------------------------|-------------------------------|
| Tamanho | **~4,2 MB** | **~23 MB** |
| Hash | `3252c01e...` | `061a1102...` |
| Produto | Tauri GUI | Node CLI (console) |
| Comportamento | Janela gráfica | Abre e fecha = "crash" |

O manifest no servidor já estava certo. O link da home **não tinha cache-bust**, então o navegador/CDN serviu arquivo de **11 Jun 23:21**.

## O que fazer AGORA

### 1. Limpar instalação antiga (manual)

```
Configurações → Aplicativos → Desinstalar TODAS entradas "Dark World"
Apagar pasta: C:\Program Files\Dark World
Apagar pasta: %LOCALAPPDATA%\DarkWorld
Apagar atalho Desktop: Dark World.lnk
```

### 2. Baixar pelo link NOVO (com ?v=)

Abra: https://dark.zorionlabs.net

Clique **Baixar Launcher (Windows)** — a URL deve conter:
```
/downloads/DarkWorld-Launcher-Setup.exe?v=3252c01e
```

### 3. ANTES de instalar — verificar tamanho

| Tamanho do arquivo | Significado |
|--------------------|-------------|
| **~4,2 MB** | Correto (Tauri GUI) |
| **~23 MB** | ERRADO — cache antigo, não instale |

PowerShell:
```powershell
(Get-Item "$env:USERPROFILE\Downloads\DarkWorld-Launcher-Setup.exe").Length
# Deve ser ~4382791
Get-FileHash "$env:USERPROFILE\Downloads\DarkWorld-Launcher-Setup.exe" -Algorithm SHA256
# Deve começar com 3252C01E...
```

### 4. Instalar e abrir

- Deve abrir **janela gráfica** "Dark World Launcher" (não console)
- Botões: Jogar, Reparar, ⚙
- **Enviar screenshot**

## SmartScreen / Chrome "arquivo perigoso"

Normal para executável **não assinado**. Pode clicar "Manter" / "Executar mesmo assim".

## Relatórios forenses completos

Ver [`docs/forensics/`](/opt/darkworld/docs/forensics/) no servidor.

## Ainda NOT_DELIVERED

Até você confirmar GUI diferente com screenshot.
