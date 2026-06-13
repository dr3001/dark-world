# WORLD_VISUAL_AUDIT.md

**Date:** 2026-06-12T00:46:16Z

## Architecture

World geometry is **100% procedural** in `World.gd` _ready(). Static scene = ground + HUD only.

## Expected content at spawn (0, 3, 0)

| Element | Builder | Expected count |
|---------|---------|----------------|
| Plaza fountain | _build_plaza | 1 |
| Houses | _build_village | 16 (12 road + 4 plaza) |
| NPCs | _spawn_npcs | 8 |
| Castle | _build_castle | 1 complex |
| Dragon | _spawn_dragon | 1 |
| Trees | _build_trees | ~100 (tree_count) |
| Walls | _build_walls | Perimeter segments |
| Rocks | _build_rocks | Scattered |
| Road torches | _build_road_torches | Along roads |
| Roads | _plane in _build_village | 2 strips |

## Code verification

- `_build_plaza` — present
- `_build_village` — present
- `_build_walls` — present
- `_build_rocks` — present
- `_spawn_npcs` — present
- `_build_castle` — present
- `_spawn_dragon` — present
- `_build_trees` — present
- `_build_road_torches` — present
- `_spawn_player` — present

## Visual quality note

Meshes are primitive (boxes, cylinders, planes). This reads as **prototype** visually but is **not** an empty world if _ready() completes.

## Failure modes

1. Stale game binary (debug export / old CDN cache) → green field + HUD only
2. World.gd parse error → same symptom
3. Camera at spawn — should see plaza immediately (fountain at origin)

## Log verification (Rogério)

Check `%LOCALAPPDATA%/DarkWorld/logs/game/game.log` for:

```
[WORLD] DONE - Trees:N Houses:N NPCs:N Dragons:N
```

If N>0 and screen still empty → GPU/rendering issue (report with screenshot).

## CDN game build
- Local exe: 245541472 bytes
- Hash: 76e8bc46e3ebaaba91fa215b408e58cc6b8d30bc511f25668a784f6f68384414
- CDN game_version: 5.0.6
