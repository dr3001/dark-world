# Dark World — Project State

## Status Geral: FUNCIONAL

## Infraestrutura
| Componente | Status | Detalhes |
|------------|--------|----------|
| VPS | Ativo | 5.78.142.138 |
| Godot Editor | 4.6.3.stable | /opt/godot/godot_4.6.3/ |
| Export Templates | 4.6.3.stable | macOS + Windows instalados |
| Build Script | Funcional | publish-mac-debug.sh (--export-debug nativo) |
| Download | Funcional | https://dark.zorionlabs.net/downloads/ |
| GitHub | Funcional | dr3001/dark-world (main) |
| World Engine | Node.js | http://5.78.142.138:9000 |

## Client Godot
| Funcionalidade | Status |
|----------------|--------|
| Login | Funcional |
| Criacao de conta | Funcional |
| Criacao de personagem | Funcional |
| Entrada no mundo | Funcional |
| Movimento WASD | Funcional |
| Camera 3a pessoa | Funcional |
| Terreno com colisao | Funcional |
| Casas com colisao | Funcional |
| Castelo com colisao | Funcional |
| Muralhas com colisao | Funcional |
| NPCs visiveis | Funcional |
| Interacao NPC (E) | Funcional |
| Dialogo NPC | Funcional |
| Quest flow | Funcional |
| HUD completo | Funcional |
| Dragao visivel | Funcional |
| Arvores | Funcional |
| Tochas com luz | Funcional |
| Export macOS | Funcional |
| Dragao AI | NAO implementado |
| Combate funcional | NAO implementado |
| Inventario | NAO implementado |
| Multiplayer | NAO implementado |

## Arquivos Principais
| Arquivo | Linhas | Funcao |
|---------|--------|--------|
| scenes/World.tscn | 125 | Cena principal do mundo |
| scripts/World.gd | 450 | Controlador do mundo, NPCs, dialogo, quest |
| scripts/PlayerController.gd | 96 | Movimento, gravidade, combate basico |
| scripts/CameraController.gd | 39 | Camera 3a pessoa com zoom |
| scripts/NetworkClient.gd | 52 | Conexao com servidor |
| scripts/QuestSystem.gd | 31 | Sistema de quest (dragon kill) |
| scripts/publish-mac-debug.sh | 30 | Build e publicacao macOS |

## Build Atual
- Plataforma: macOS (universal arm64 + x86_64)
- Engine: Godot 4.6.3
- Tamanho: ~90MB comprimido
- SHA256: a9182ce1e1dd2d1a842a8333850c0ff56c0890013a799e5828d2978654343712

## Comando de Download
```bash
curl -LO "https://dark.zorionlabs.net/downloads/DarkWorld-Mac-debug.tar.gz?v=0.4.0"
tar xzf DarkWorld-Mac-debug.tar.gz
xattr -cr DarkWorld.app
open DarkWorld.app
```
