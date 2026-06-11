# WORLD STATUS — Dark World

## Object Counts
| Type | Count |
|------|-------|
| Houses | 16 |
| NPCs | 5 (Guarda do Vale, Ferreiro Thorin, Mercador Ivan, Curandeira Lyra, Campones Finn) |
| Trees | 80 + 8 (plaza) = 88 |
| Dragons | 1 (BlueDemon.gltf) |
| Torches | 4 (plaza fountain) |
| Benches | 4 (plaza) |
| Carts | 2 |
| Well | 1 |
| Fountain | 1 |
| Castle | 1 (keep + 4 towers + walls) |

## Positions
| Object | Position |
|--------|----------|
| Player spawn | Vector3(0, 2, 0) |
| Camera start | Vector3(0, 9, 16) |
| Ground | Vector3(0, -0.1, 0) size=1000x1000 |
| Plaza center | Vector3(0, 0, 0) |
| Castle | Vector3(-60, 0, 40) |
| Dragon | Vector3(30, 0, 0) scale=6 |
| Village road | Z axis, houses at ±X starting at Z=15 |
| Fountain | Vector3(0, 0, 0) |

## Environment
| Setting | Value |
|---------|-------|
| Sky | ProceduralSkyMaterial (blue gradient) |
| Sun | DirectionalLight3D energy=8, shadows enabled |
| Ambient | Color(0.65, 0.65, 0.68) |
| Fog | enabled, density=0.0004, blue tint |
| Background | mode=2 (Sky) |
