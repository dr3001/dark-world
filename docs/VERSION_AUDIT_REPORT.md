# VERSION AUDIT REPORT — Mission 7.1

## Components

| Component | Installed | Current Stable | Released | Diff | Risk | Status |
|-----------|-----------|----------------|----------|------|------|--------|
| Godot | v4.4-stable | v4.6.3-stable | 2026-05-20 | 6 versions behind | MEDIO | ATUAL |
| Nakama | 3.31.0 | 3.31.0 | Latest | 0 | BAIXO | ATUAL |
| PostgreSQL | 16-alpine | 17 | Latest | -1 major | BAIXO | ACEITAVEL |
| Redis | 7-alpine (7.4.9) | 7.4.x | Latest | 0 | BAIXO | ATUAL |
| Docker | 29.1.3 | 29.1.3 | Latest | 0 | BAIXO | ATUAL |
| Docker Compose | v5.1.4 | v5.1.4 | Latest | 0 | BAIXO | ATUAL |
| Node.js | v22.22.3 | v22.22.3 | Latest | 0 | BAIXO | ATUAL |
| Nginx | 1.28.3 | 1.28.3 | Latest | 0 | BAIXO | ATUAL |
| Ubuntu | 26.04 LTS | 26.04 LTS | Latest | 0 | BAIXO | ATUAL |
| OpenSSL | 3.5.5 | 3.5.5 | Latest | 0 | BAIXO | ATUAL |
| Tauri | N/A | N/A | N/A | N/A | N/A | N/A |
| Electron | N/A | N/A | N/A | N/A | N/A | N/A |
| TypeScript | Included w/Node 22 | 5.x | - | - | BAIXO | ATUAL |

## Godot Analysis

- Installed: v4.4.stable (March 2025)
- Current stable: v4.6.3 (May 2026)
- 6 minor versions behind
- **Action taken: Downloaded Godot 4.6.3 for export**
- The new Godot 4.6.3 is installed at /opt/godot/godot_4.6.3/
- Export templates for 4.6.3 macOS are installed
- The old Godot 4.4 binary remains at /opt/godot/godot_bin/

## Mac Export Validation

| Item | Status |
|------|--------|
| Export Templates | INSTALADO (4.6.3) |
| macOS SDK | Incluido no template |
| Apple Silicon | Universal binary |
| Intel | Universal binary |
| Gatekeeper | Ad-hoc signature (sem notarizacao) |
| Notarization | NAO (requer Apple Developer) |
| DMG | ZIP com .app bundle (sem hdiutil no Linux) |

## Verdict

- **Posso gerar um DMG moderno hoje?** NAO (Linux nao tem hdiutil)
- **Posso gerar um APP moderno hoje?** SIM (DarkWorld.app universal binary)
- **Existe risco por versoes antigas?** NAO (export feito com 4.6.3)
- **Tecnologia mais desatualizada:** Godot (estava em 4.4, atualizado para 4.6.3)
- **Atualizacao obrigatoria antes do Alpha:** Nenhuma critica detectada
