# Dark World — Proxima Fase de Desenvolvimento

## Fase Atual Concluida
- [x] Mundo jogavel
- [x] NPCs com dialogo
- [x] Quest flow basico
- [x] Export macOS funcional

## Proxima Fase: Combate Funcional

### Prioridade 1 — Combate com Vorak
- [ ] Dragao com AI ativa (patrulha, detecta jogador, ataca)
- [ ] Combate corpo a corpo funcional (click esquerdo)
- [ ] Barra de HP do dragao visivel e funcional
- [ ] Feedback visual de dano (flash vermelho)
- [ ] Morte do dragao com efeito visual
- [ ] Quest "Derrote Vorak" completa ao matar

### Prioridade 2 — Polish do Jogador
- [ ] Animacao de caminhada (bracos/pernas)
- [ ] Animacao de ataque (espada)
- [ ] Som de passos (placeholder)
- [ ] Som de ataque (placeholder)
- [ ] Morte do jogador (tela de game over ou respawn)

### Prioridade 3 — Melhoria da Vila
- [ ] Mercador funcional (compra/venda placeholder)
- [ ] Curandeira funcional (curar HP)
- [ ] Mais NPCs com dialogos
- [ ] Placas de sinalizacao
- [ ] Interior de casas (futuro)

### Prioridade 4 — Sistemas
- [ ] Inventario basico
- [ ] Itens coletaveis
- [ ] Pocoes de cura
- [ ] Save/load local
- [ ] Minimap

## NAO fazer nesta fase
- Multiplayer
- Marketplace
- Sistema de crafting
- Dungeons
- Mounts
- PvP

## Regras de Desenvolvimento
1. Sempre criar checkpoint antes de mudancas grandes
2. Sempre testar build macOS antes de declarar pronto
3. Nunca alterar o publish script sem necessidade
4. Usar --export-debug nativo do Godot
5. Manter nomes de arquivo com espaco no app (Dark World)
6. Usar ?v=X.Y.Z para bypass de cache Cloudflare
