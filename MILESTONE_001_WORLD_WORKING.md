# MILESTONE 001 — WORLD WORKING

## Estado: FUNCIONAL

## Commit Base
- **Hash:** c6ce0b1
- **Branch:** main
- **Data:** 2026-06-11

## Build Publicado
- **URL:** https://dark.zorionlabs.net/downloads/DarkWorld-Mac-debug.tar.gz?v=0.3.0
- **SHA256:** bee1a1626568e83a4394a43082a5b7e3e3aa18308737a27dd67dcc46be89659a
- **Tamanho:** 90MB
- **Plataforma:** macOS (universal arm64 + x86_64)
- **Engine:** Godot 4.6.3

## Comando Oficial de Download
```bash
curl -LO "https://dark.zorionlabs.net/downloads/DarkWorld-Mac-debug.tar.gz?v=0.3.0"
tar xzf DarkWorld-Mac-debug.tar.gz
xattr -cr DarkWorld.app
open DarkWorld.app
```

## Estado Funcional Comprovado
- [x] App abre no Mac
- [x] Menu abre
- [x] Login funciona
- [x] Criacao de conta funciona
- [x] Personagem entra no mundo
- [x] Terreno visivel com colisao (WorldBoundaryShape3D)
- [x] Arvores (80+)
- [x] Casas (16) com colisao
- [x] NPCs (5) com nomes visiveis
- [x] Tochas com iluminacao (OmniLight3D)
- [x] Fonte com agua
- [x] Poco
- [x] Castelo com torres e colisao
- [x] Dragao (Vorak) posicionado
- [x] Muralhas com colisao
- [x] Pedras decorativas
- [x] Estradas
- [x] HUD (HP, Mana, FPS, Posicao, Quest, Objetos)
- [x] Camera 3a pessoa acompanha jogador
- [x] Movimento WASD funcional
- [x] Corrida com Shift
- [x] Pulo com Space
- [x] Zoom com scroll do mouse
- [x] Export macOS funcional (--export-debug nativo)

## Problemas Pendentes
- [ ] Jogador nao interage com NPCs
- [ ] Sem sistema de dialogo
- [ ] Sem sistema de quest funcional
- [ ] Dragao sem AI ativa no mundo
- [ ] Sem sistema de inventario
- [ ] Sem multiplayer ativo
- [ ] Cloudflare cache pode servir build antigo (usar ?v=0.3.0)

## Proximo Objetivo
Criar primeira experiencia jogavel:
1. Interacao com NPC via tecla E
2. Dialogo com Guardiao do Vale
3. Quest inicial no HUD
4. Dialogo com Ferreiro Thorin
5. Fluxo: Guardiao -> Ferreiro -> Derrote Vorak
