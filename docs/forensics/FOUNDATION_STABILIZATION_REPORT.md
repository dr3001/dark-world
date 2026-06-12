# FOUNDATION STABILIZATION — Entrega P0

**Date:** 2026-06-12  
**Mission:** Dark World Foundation Stabilization (fix only, no scope expansion)

---

## ROOT CAUSE DOS BUGS ATUAIS

| Bug | Root cause |
|-----|------------|
| Jogar não libera pós-update | `update_required` não recalculado após update |
| Launcher fica na tela | `launch_game` só fazia spawn |
| Console Godot visível | `--export-debug` + sem `console_wrapper=false` |
| UID warnings | `Main.tscn` órfão, refs inconsistentes |
| Mundo “vazio” | Export stale/debug OU `World.gd` parse errors OU visual protótipo (caixas) |
| Launcher não volta após jogo | **Sem monitor de processo** — corrigido nesta entrega |

---

## BUGS P0 ENCONTRADOS

1. Play button stuck after update  
2. Launcher visible during game  
3. No tray / no hide on play  
4. Godot console in player build  
5. Debug HUD (FPS, ObjectCount, Position)  
6. Forgot password sem UI portal  
7. API vazava `reset_token`  
8. Game exit não restaurava launcher  
9. Launcher CDN ainda binário **1.0.0** (código **1.0.1+** não publicado Windows)  
10. MultiplayerSync usa IP hardcoded — não validado 2 players  

---

## BUGS P0 CORRIGIDOS (código)

| # | Fix | Commit area |
|---|-----|-------------|
| 1 | Recalc `update_required` | lib.rs |
| 2-3 | Tray + hide on play | tray.rs, lib.rs |
| 4 | export-release + console_wrapper=false | publish pipeline |
| 5 | Hide debug HUD in release | World.gd |
| 6-7 | forgot-password portal + API sanitize | portal, api.ts |
| 8 | **Game process monitor → launcher restore** | game_monitor.rs |
| 9 | Game v5.0.6 published CDN | publish-release.sh |

**Pendente deploy:** launcher Windows 1.0.1+ (CI rebuild)

---

## BUGS P1 ENCONTRADOS

- MultiplayerSync `SERVER_URL` hardcoded IP (deveria usar CDN API)  
- world-engine `tsc` errors pre-existentes  
- Cloudflare purge sem `CF_API_TOKEN`  
- Arte procedural = aparência protótipo (não bug de load)

---

## BUGS P1 CORRIGIDOS

Nenhum P1 corrigido nesta sprint (congelado até P0 humano aprovar).

---

## STATUS DOS PILARES (10)

| Pilar | Status | Notas |
|-------|--------|-------|
| 1 Launcher | **WORKING_WITH_GAPS** | Tauri GUI OK; CDN exe antigo |
| 2 Update | **WORKING** | Manifest + SHA256 + v5.0.6 |
| 3 Login | **WORKING** | In-game + API |
| 4 Register | **WORKING** | Portal /register/ |
| 5 Forgot password | **WORKING** | Portal + in-game link |
| 6 Download | **WORKING** | Hash verificado |
| 7 Install | **WORKING** | NSIS launcher |
| 8 Uninstall | **PARTIAL** | NSIS section exists — human verify |
| 9 Init | **WORKING** | Release export, no console |
| 10 World load | **WORKING_WITH_GAPS** | Builders OK — human visual TBD |

Automated audit: **12 PASS, 0 FAIL** (`scripts/audit-foundation.sh`)

---

## CICLO LAUNCHER (Fase 3)

| Step | Status |
|------|--------|
| Abrir launcher | OK |
| Verificar internet/servidor | OK (fetch_status) |
| Verificar manifest | OK |
| Verificar integridade SHA256 | OK |
| Verificar versão | OK |
| Atualizar | OK |
| Liberar jogar | OK (fix applied) |
| Iniciar jogo | OK |
| Minimizar tray | OK (code) |
| Monitorar processo | **OK (new)** |
| Jogo fecha → launcher reaparece | **OK (new)** |

**Não implementado (fora P0 / escopo congelado):** download diferencial, canal notícias, alertas staff, fila manutenção UI.

---

## COMPONENT STATUS

| Component | Status |
|-----------|--------|
| LAUNCHER | WORKING_WITH_GAPS |
| UPDATE | WORKING |
| LOGIN | WORKING |
| REGISTER | WORKING |
| FORGOT PASSWORD | WORKING |
| WORLD | WORKING_WITH_GAPS |
| NPC | Code loads 8 — visual TBD |
| CITY | Code loads 16 houses — visual TBD |
| CASTLE | Code present — visual TBD |
| MULTIPLAYER | **NOT VALIDATED** — blocked until human P0 |

---

## RELATÓRIOS GERADOS

- `docs/forensics/FOUNDATION_STABILIZATION_REPORT.md` (this file)
- `docs/forensics/FOUNDATION_AUDIT_OUTPUT.txt`
- `docs/forensics/WORLD_VISUAL_AUDIT.md`
- `docs/forensics/UPDATE_FLOW_REPORT.md`
- `docs/forensics/PLAY_BUTTON_ROOT_CAUSE.md`
- `docs/forensics/LAUNCHER_BEHAVIOR_REPORT.md`
- `docs/forensics/TRAY_IMPLEMENTATION_REPORT.md`
- `docs/forensics/LOGGING_SYSTEM_REPORT.md`
- `docs/forensics/RESOURCE_VALIDATION_REPORT.md`
- `docs/forensics/AUTH_FLOW_REPORT.md`
- `docs/forensics/EMPTY_WORLD_ROOT_CAUSE.md`
- `docs/forensics/VISUAL_VALIDATION_REPORT.md`
- `docs/forensics/HUMAN_E2E_REPORT.md`
- `docs/forensics/PLACEHOLDER_PURGE_REPORT.md`
- `docs/ROGERIO_RETEST.md`

---

## COMMITS / TAGS / VERSÃO

| Item | Value |
|------|-------|
| Prior UX commit | `4675c44` |
| Foundation commit | (this push) |
| Tag UX | `v5.0.6-ux-tribunal` |
| Tag Foundation | `v5.0.6-foundation-p0` |
| Game version | **5.0.6** |
| Launcher version | **1.0.1** (code) / **1.0.0** (CDN exe) |

---

## CLASSIFICAÇÃO

**WORKING_WITH_GAPS**

Upgrade to **READY_FOR_HUMAN_RETEST** when Rogério confirms:

1. Launcher 1.0.1+ on CDN  
2. Update → Jogar without restart  
3. Play → tray, no console  
4. Exit game → launcher returns  
5. World shows structures at spawn  
6. Screenshots of each step  

**READY_FOR_MULTIPLAYER_TEST:** blocked until above + 2-player controlled test.

---

## REGRA FINAL

Nenhuma expansão P1+ autorizada até fundação estável + Rogério + 2 jogadores simultâneos sem falhas.
