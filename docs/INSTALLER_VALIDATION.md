# INSTALLER VALIDATION — Mission 6.1

## Perguntas Obrigatórias

| Pergunta | Resposta |
|----------|----------|
| Existe instalador? | **NÃO** |
| Existe aplicativo executável? | **NÃO** |
| Existe processo de instalação? | **NÃO** |
| Existe DMG? | **NÃO** |
| Existe .app? | **NÃO** |
| Existe .pkg? | **NÃO** |

## O que existe
- DarkWorld-Mac.zip: **PROJETO GODOT** (source code)
- build_mac_dmg.sh: Script que GERA um DMG **no Mac** com Godot instalado
- export_presets.cfg: Config de export do Godot

## Por que não temos instalador
- Servidor é Linux (Hetzner) — não roda Godot editor para export
- Export Godot para Mac requer macOS + Godot editor
- DMG só pode ser criado no Mac (hdiutil)

## Solução
Executar build_mac_dmg.sh **no Mac** com Godot 4.x instalado:
```bash
cd ~/Projects/darkworld
./scripts/build_mac_dmg.sh
# Output: godot-client/build/mac/DarkWorld-Mac.dmg
```
