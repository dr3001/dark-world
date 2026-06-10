# FIRST WORLD REPORT — Mission 4

## Vale Cinzento

O primeiro mundo jogável contém:

### Entidades Presentes

| Nome | Tipo | Posição | Estado |
|------|------|---------|--------|
| Vale Cinzento | territory | (0, 0) | Território inicial |
| Reino Central | faction | (0, 0) | Facção humana |
| Vorak, o Antigo | dragon | (200, 200) | Dragão ancião vivo |
| Heroi Godot | player_character | (100, 100) | Personagem do jogador |

### Áreas Implementadas (conceito)
- **Zona Viva:** Centro do mapa, território Reino Central
- **Zona Congelada:** Mundo Congelado (frozen_afterlife) — cena separada
- **Zona Sombria:** Reino das Sombras (shadow_realm) — placeholder

### Visual (Placeholder)
- Solo escuro (plane com material escuro)
- Dragão: cubo grande vermelho com label
- Jogador: cilindro azul
- Território: plano verde transparente
- Iluminação: directional light + ambiente escuro

### Atmosfera
- Clear color: (0.02, 0.02, 0.04) — azul muito escuro
- Luz principal fria
- Mundo Congelado: luz azulada

## Próximos Passos Visuais
- Substituir placeholders por assets dark fantasy (Fab/CGTrader)
- Adicionar partículas de chuva/neve
- Adicionar névoa volumétrica
- Terreno com altura (HeightMap)
