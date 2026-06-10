# GODOT 4 IMPORT COMPATIBILITY — Dark World

## Formatos Suportados Nativamente

| Formato | Godot 4 | Recomendação |
|---------|---------|--------------|
| **glTF 2.0** (.gltf/.glb) | ✅ Nativo | **PREFERIDO** — Melhor suporte, PBR materials, animações |
| **OBJ** (.obj) | ✅ Nativo | OK para geometria estática simples |
| **FBX** (.fbx) | ⚠️ Via conversor | Não recomendado — Godot 4 removeu suporte nativo |
| **Collada** (.dae) | ✅ Nativo | Aceitável, mas glTF é superior |
| **ESCN** (.escn) | ✅ Nativo | Formato interno do Godot |
| **Blend** (.blend) | ✅ Nativo | Se usar Blender como ferramenta |

## Texturas

| Formato | Suporte | Notas |
|---------|---------|-------|
| PNG | ✅ | Preferido para texturas |
| JPEG | ✅ | OK para texturas grandes sem alpha |
| WebP | ✅ | Suportado, compressão eficiente |
| SVG | ✅ | Para UI, importado como raster |
| KTX | ✅ | Texturas comprimidas para GPU |
| EXR/HDR | ✅ | HDRI e texturas HDR |
| TGA/BMP | ✅ | Formatos legados, evitar |

## Materiais

| Tipo | Suporte |
|------|---------|
| StandardMaterial3D (PBR) | ✅ Nativo |
| ORMMaterial3D | ✅ Nativo |
| ShaderMaterial | ✅ Script personalizado |
| Importação de materiais glTF | ✅ Automática (PBR) |
| Importação de materiais FBX | ❌ Não confiável |

## Animações

| Método | Suporte |
|--------|---------|
| AnimationPlayer | ✅ Nativo Godot |
| Skeleton3D + animações glTF | ✅ Suportado |
| Blend shapes / morph targets | ✅ glTF |
| Animação FBX | ⚠️ Converter para glTF primeiro |

## Assets de Terceiros — Recomendações

### Fab / ArtStation / CGTrader

1. **Sempre preferir glTF/GLB** — Se o asset oferecer múltiplos formatos, escolha glTF.
2. **FBX → glTF** — Se só tiver FBX, converter usando:
   - Blender (gratuito): Import FBX → Export glTF
   - fbx2gltf (CLI): `fbx2gltf input.fbx -o output.glb`
   - Assimp: `assimp export input.fbx output.glb`
3. **Texturas** — Verificar se usam PBR (Albedo, Normal, Roughness, Metallic, AO)
4. **Escala** — Godot usa metros. Verificar escala após importação (ajustar no import settings)
5. **LOD** — Godot suporta LOD via LODGroup node. Assets comprados com LOD são compatíveis.

## Dificuldade de Migração

| Formato Origem | Dificuldade | Tempo Estimado por Asset |
|----------------|-------------|--------------------------|
| glTF/GLB | **Fácil** | 5-15 min (arrastar + ajustar escala) |
| FBX → glTF | **Médio** | 15-30 min (converter + verificar materiais) |
| OBJ | **Fácil** | 10-20 min (texturas separadas, sem animação) |
| Blender | **Fácil** | Direto (se compatível com versão do Blender) |

## Problemas Conhecidos

1. **Texturas FBX perdem links** — Converter para glTF resolve
2. **Escalas inconsistentes** — Godot 1 unidade = 1 metro. Ajustar import scale
3. **Materiais complexos** — Shaders personalizados do Unity/Unreal não convertem automaticamente
4. **Rig/Skeleton FBX** — Pode perder bone weights na conversão
5. **Animação FBX** — Melhor converter via Blender, não via CLI

## Pipeline Recomendado

```
Asset comprado (.fbx, .obj, .gltf)
    ↓
Blender (se FBX/OBJ)
    ↓
Exportar como .glb (glTF Binary)
    ↓
Copiar para godot-client/assets/
    ↓
Godot importa automaticamente
    ↓
Ajustar: escala, materiais, colisão
    ↓
Pronto para uso nas cenas
```

## Orçamento de Tempo para Assets

| Quantidade | Formato | Tempo Estimado |
|------------|---------|----------------|
| 1 dragão | FBX | 30 min (converter + ajustar) |
| 1 dragão | GLTF | 10 min (ajustar escala/materiais) |
| 10 assets ambiente | Misto | 2-4 horas |
| 50+ assets | Misto | 1-2 dias |
