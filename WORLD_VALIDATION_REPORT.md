# Dark World — World Validation Report

## Data: 2026-06-11
## Build: 0.5.0 (RPG World Ready)

## Checklist de Validacao

| Item | Status |
|------|--------|
| Player nasce corretamente | SIM — spawn em (0, 3, 0), cai no chao y=0 |
| Player nao cai | SIM — WorldBoundaryShape3D + safety teleport |
| Casas tem colisao | SIM — StaticBody3D BoxShape3D cada casa |
| Arvores tem colisao | SIM — CylinderShape3D no tronco |
| Bancos tem colisao | SIM — BoxShape3D |
| Carrocas tem colisao | SIM — BoxShape3D |
| NPCs tem colisao | SIM — StaticBody3D CapsuleShape3D |
| Dragao tem colisao | SIM — StaticBody3D BoxShape3D/CapsuleShape3D |
| Camera suave | SIM — exp() smoothing + slerp rotation |
| Movimento suave | SIM — move_toward accel/decel + lerp_angle |
| Tecla E funciona | SIM — abre/fecha dialogo NPC |
| Dialogos aparecem | SIM — painel com nome + texto + [E] Fechar |
| Missao aparece | SIM — Curandeira oferece "Derrote Vorak" |
| Build inicia normalmente | SIM — export-debug 4.6.3, 90MB |

## Colisoes Adicionadas Nesta Versao

| Objeto | Antes | Depois |
|--------|-------|--------|
| Arvores (88) | Sem colisao | CylinderShape3D tronco |
| Rochas (40) | Sem colisao | SphereShape3D |
| Bancos (4) | Sem colisao | BoxShape3D |
| Carrocas (2) | Sem colisao | BoxShape3D |
| NPCs (5) | Node3D | StaticBody3D + CapsuleShape3D |
| Dragao | Node3D/gltf | StaticBody3D + Box/Capsule |
| Muro castelo (30) | Sem colisao | BoxShape3D rotacionado |

## Melhorias de Movimento
- Aceleracao gradual: accel=25.0
- Desaceleracao gradual: decel=18.0
- Rotacao suave: lerp_angle rot_speed=10.0
- Camera frame-independent: 1.0 - exp(-speed * delta)
- Camera slerp: basis.slerp para look_at suave

## Melhorias de Iluminacao
- Sol: energy 8.0 → 5.0
- Ambient: +10% brilho
- Tonemap: Linear → ACES
- Fog: density -25%

## Dialogos Atualizados
- Guardiao: "Mantenha-se atento aos perigos da regiao."
- Ferreiro: "Posso forjar armas para aventureiros."
- Mercador: "Tenho mercadorias para viajantes."
- Curandeira: "Vorak ameaca o Vale Cinzento." (quest giver)
- Campones: "A vida era mais tranquila antes de Vorak."

## Quest
- Quest giver: Curandeira Lyra
- Missao: "Derrote Vorak, o Antigo"
- HUD mostra "MISSAO INICIADA" por 3s, depois "MISSAO: Derrote Vorak, o Antigo"
