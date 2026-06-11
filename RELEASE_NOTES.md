# Dark World — Release Notes

## v0.4.0 — NPC Interaction (2026-06-11)

### Novas Funcionalidades
- Sistema de interacao com NPCs via tecla E
- Caixa de dialogo com nome do NPC e texto
- 5 NPCs com dialogos unicos
- Quest flow: Guardiao → Ferreiro → Derrote Vorak
- HUD mostra missao atual atualizada dinamicamente
- Indicador "[E] Falar" ao se aproximar de NPC (raio 4m)
- Botao "[E] Fechar" no painel de dialogo

### NPCs com Dialogo
| NPC | Funcao | Dialogo |
|-----|--------|---------|
| Guardiao do Vale | Quest giver | Apresenta a ameaca de Vorak, envia ao ferreiro |
| Ferreiro Thorin | Quest giver | Entrega espada, ativa missao de matar Vorak |
| Mercador Ivan | Futuro | Placeholder (em breve) |
| Curandeira Lyra | Futuro | Placeholder (em breve) |
| Campones Finn | Flavor | Aviso sobre o dragao |

### Quest Flow
1. Inicio: "Explore o Vale Cinzento"
2. Apos falar com Guardiao: "Fale com o Ferreiro Thorin"
3. Apos falar com Ferreiro: "Derrote Vorak, o Antigo"

## v0.3.0 — World & Export Fix (2026-06-11)

### Correcoes Criticas
- Ground collision (WorldBoundaryShape3D) — jogador nao cai mais
- Player CollisionShape3D centralizado no corpo
- Export macOS corrigido (--export-debug com template 4.6.3)
- Nome do executavel corrigido (Dark World com espaco)
- HUD HP bar renderiza corretamente

### Mundo
- 16 casas com colisao
- Castelo com torres e colisao
- Muralhas circulares com colisao (raio 120)
- Poco e fonte com colisao
- 80+ arvores, 40 pedras
- Tochas com OmniLight3D
- 5 NPCs com nomes visiveis
- Dragao Vorak posicionado
- Praca central com fonte

## v0.2.0 — Base (anteriores)
- Login e criacao de conta
- Criacao de personagem
- Cena do mundo basica
- Movimento WASD + camera 3a pessoa
- HUD basico
