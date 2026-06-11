# Dark World — World Audit

## Data: 2026-06-11
## Versao: 0.5.0 (RPG World Ready)

## Objetos COM colisao

| Objeto | Qtd | Tipo Colisao | Shape |
|--------|-----|-------------|-------|
| Chao | 1 | WorldBoundaryShape3D | Plano infinito y=0 |
| Casas | 16 | StaticBody3D | BoxShape3D 7x5x6 |
| Fonte | 1 | StaticBody3D | CylinderShape3D r=3.5 h=0.8 |
| Poco | 1 | StaticBody3D | CylinderShape3D r=1.5 h=3.0 |
| Castelo keep | 1 | StaticBody3D | BoxShape3D 14x18x14 |
| Castelo torres | 4 | StaticBody3D | BoxShape3D 5x22x5 |
| Castelo portao | 1 | StaticBody3D | BoxShape3D 7x10x4 |
| Castelo muro exterior | 30 | StaticBody3D | BoxShape3D 1x7x3 rotacionado |
| Muralhas da vila | 40 | StaticBody3D | BoxShape3D 2x6x20 |
| Arvores | 88 | StaticBody3D | CylinderShape3D r=0.5 (tronco) |
| Rochas | ~40 | StaticBody3D | SphereShape3D r=sz*0.5 |
| Bancos | 4 | StaticBody3D | BoxShape3D 3x1x0.8 |
| Carrocas | 2 | StaticBody3D | BoxShape3D 2.5x1.5x3 |
| NPCs | 5 | StaticBody3D | CapsuleShape3D r=0.5 h=2.0 |
| Dragao Vorak | 1 | StaticBody3D | BoxShape3D 4x3x6 (gltf) ou CapsuleShape3D (fallback) |
| Player | 1 | CharacterBody3D | CapsuleShape3D r=0.5 h=2.2 |

## Objetos SEM colisao (aceitavel)

| Objeto | Motivo |
|--------|--------|
| Tochas (~32) | Postes finos, decorativo |
| Fumaca | Efeito visual |
| Banner do castelo | Decorativo |
| Estradas (planes) | Niveladas com o chao |
| Praca (planes) | Nivelada com o chao |
| Agua da fonte | Efeito visual transparente |
| Circulos de luz | Efeito visual |

## Resultado
Todos os objetos fisicos significativos possuem colisao.
Jogador nao deve atravessar nenhum objeto solido visivel.
