# Dark World — Proxima Fase: Combate

## Pre-requisito
Tag: milestone-rpg-world-ready
Status: Mundo estavel, navegavel, colisoes funcionais

## Fase: Combate com Vorak

### Prioridade 1 — Dragon AI
- [ ] DragonAI.gd ativo no mundo (estados: IDLE, PATROL, CHASE, ATTACK)
- [ ] Deteccao de jogador (raio 20m)
- [ ] Perseguicao com navegacao
- [ ] Ataque com dano ao jogador

### Prioridade 2 — Combate do Jogador
- [ ] Click esquerdo: ataque corpo a corpo
- [ ] Feedback visual de dano (flash)
- [ ] HP do dragao visivel e funcional
- [ ] HP do jogador diminui ao receber dano

### Prioridade 3 — Morte e Vitoria
- [ ] Dragao morre ao chegar a 0 HP
- [ ] Efeito visual de morte
- [ ] Quest "Derrote Vorak" concluida
- [ ] Mensagem de vitoria no HUD
- [ ] Jogador morre ao chegar a 0 HP
- [ ] Tela de game over ou respawn

### Prioridade 4 — Polish
- [ ] Sons placeholder (ataque, dano, morte)
- [ ] Particulas de impacto
- [ ] Cooldown visual no HUD

## NAO implementar nesta fase
- Inventario
- Loot
- XP
- Skills
- Multiplayer
- Crafting
- Mais monstros

## Regras
1. Sempre criar tag antes de iniciar
2. Testar build macOS antes de declarar pronto
3. Nao quebrar o que ja funciona
4. Manter colisoes e movimento existentes
