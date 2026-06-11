# WORLD REALITY REPORT

## Scene Elements

| Element | Exists | Loads | Visible | Above Ground | In Frustum |
|---------|--------|-------|---------|-------------|------------|
| Terrain (1000x1000) | YES | YES | YES | N/A | YES |
| Player (CapsuleMesh) | YES | YES | YES | YES | YES |
| Camera3D | YES | YES | YES | YES | YES |
| Ground (PlaneMesh) | YES | YES | YES | At y=-0.1 | YES |
| 100 Trees | YES | YES | YES | YES | YES (within 300m) |
| 50 Rocks | YES | YES | YES | YES | YES (within 300m) |
| 20 Houses | YES | YES | YES | YES | YES (40-280m) |
| Plaza (40x40) | YES | YES | YES | At y=0.02 | YES |
| 10 Torches | YES | YES | YES | YES | YES (16m radius) |
| Castle | YES | YES | YES | YES | YES (at -50,0,50) |
| 5 Guards | YES | YES | YES | YES | YES (8-13m) |
| 3 Villagers | YES | YES | YES | YES | YES (scattered) |
| 1 Merchant | YES | YES | YES | YES | YES (scattered) |
| Dragon (BlueDemon.gltf) | YES | YES | YES | YES | YES (20m front) |

## Primitives Used

| Entity | Mesh Type |
|--------|-----------|
| Player body | CapsuleMesh |
| Player head | SphereMesh |
| Player limbs | CapsuleMesh |
| NPCs | CapsuleMesh + SphereMesh |
| Trees trunk | CylinderMesh |
| Trees canopy | SphereMesh |
| Rocks | SphereMesh (scaled) |
| Houses walls | BoxMesh |
| Houses roof | PrismMesh |
| Dragon | BlueDemon.gltf (Quaternius) |
| Castle | BoxMesh + PrismMesh |
| Torches | CapsuleMesh + SphereMesh (emissive) |

## Real 3D Models

- BlueDemon.gltf: 1 (dragon)
- Total .gltf files in project: 16
- Additional available: Demon, Orc, Dino, Yeti, Alien, Ninja, Frog, etc.
