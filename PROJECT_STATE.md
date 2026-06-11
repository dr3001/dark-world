# Dark World — Project State

## Status Geral: FUNCIONAL — RPG WORLD READY

## Infraestrutura
| Componente | Status | Detalhes |
|------------|--------|----------|
| VPS | Ativo | 5.78.142.138 |
| Godot Editor | 4.6.3.stable | /opt/godot/godot_4.6.3/ |
| Export Templates | 4.6.3.stable | macOS + Windows instalados |
| Build Script | Funcional | publish-mac-debug.sh (--export-debug nativo) |
| Download | Funcional | https://dark.zorionlabs.net/downloads/ |
| GitHub | Funcional | dr3001/dark-world (main) |

## Client Godot
| Funcionalidade | Status |
|----------------|--------|
| Login | Funcional |
| Criacao de conta | Funcional |
| Criacao de personagem | Funcional |
| Entrada no mundo | Funcional |
| Movimento suave WASD | Funcional (accel/decel/lerp_angle) |
| Camera suave 3a pessoa | Funcional (exp smoothing + slerp) |
| Terreno com colisao | Funcional |
| Casas com colisao (16) | Funcional |
| Castelo com colisao | Funcional (keep + torres + portao + muro 30 seg) |
| Muralhas com colisao (40) | Funcional |
| Arvores com colisao (88) | Funcional (tronco CylinderShape3D) |
| Rochas com colisao (40) | Funcional (SphereShape3D) |
| Bancos com colisao (4) | Funcional |
| Carrocas com colisao (2) | Funcional |
| NPCs com colisao (5) | Funcional (StaticBody3D CapsuleShape3D) |
| Dragao com colisao | Funcional (BoxShape3D/CapsuleShape3D) |
| Interacao NPC (E) | Funcional |
| Dialogo NPC | Funcional (5 NPCs com textos) |
| Quest system | Funcional (Curandeira quest giver) |
| HUD completo | Funcional |
| Iluminacao | Funcional (ACES tonemap, ambient melhorado) |
| Export macOS | Funcional |
| Dragao AI | NAO implementado |
| Combate | NAO implementado |
| Inventario | NAO implementado |
| Multiplayer | NAO implementado |

## Build Atual
- Plataforma: macOS (universal arm64 + x86_64)
- Engine: Godot 4.6.3
- Tamanho: ~90MB comprimido
- SHA256: c3e451b815ed8869c9517250c77bdb12a8a568b9941a999debe4873c0f02c776

## Comando de Download
```bash
curl -LO "https://dark.zorionlabs.net/downloads/DarkWorld-Mac-debug.tar.gz?v=0.5.0"
tar xzf DarkWorld-Mac-debug.tar.gz
xattr -cr DarkWorld.app
open DarkWorld.app
```

## Tags
| Tag | Commit | Descricao |
|-----|--------|-----------|
| milestone-world-working | dd936e8 | NPC dialog + export fix |
| milestone-world-playable | dd936e8 | Pre-consolidacao |
| milestone-rpg-world-ready | (pendente) | Colisoes + movimento suave + camera suave |
