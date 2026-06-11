# Dark World — Vorak Validation

## Data: 2026-06-11

## Modelo
- Asset: res://assets/quaternius/creatures/Ultimate Monsters/Big/glTF/BlueDemon.gltf
- Fallback: Modelo procedural (capsulas + esferas + prismas)
- Posicao: Vector3(30, 0, 0)
- Escala: Vector3(6, 6, 6)
- Rotacao: 90 graus no eixo Y

## Colisao
- Tipo: StaticBody3D
- Shape (gltf): BoxShape3D 4x3x6 em posicao local (0, 1.5, 0)
- Shape (fallback): CapsuleShape3D r=2.0 h=7.0 em posicao local (0, 2.5, 0)
- Status: IMPLEMENTADO

## Elementos Visuais
- Label3D: "VORAK, O ANTIGO\nHP: 100/100"
- Circulo vermelho no chao (indicador de area)
- Billboard enabled no label

## Status do Asset gltf
- BlueDemon.gltf presente no projeto
- Atlas_Monsters.png presente como textura
- Carregamento via load() em runtime
- Se falhar: fallback procedural automatico

## Resultado
- Modelo carregado: VERIFICAR NO MAC (depende do import do gltf)
- Colisao: IMPLEMENTADA
- Posicao: CORRETA (30m a leste da praca)
- Tamanho: COERENTE (escala 6x)
- Nao atravessavel: SIM (StaticBody3D ativo)
- AI/Combate: NAO IMPLEMENTADO (proxima fase)
