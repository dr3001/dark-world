#!/bin/bash
# Visual world content audit — counts expected procedural objects from World.gd
set -euo pipefail

ROOT="/opt/darkworld"
OUT="$ROOT/docs/forensics/WORLD_VISUAL_AUDIT.md"
WORLD="$ROOT/godot-client/scripts/World.gd"

{
echo "# WORLD_VISUAL_AUDIT.md"
echo ""
echo "**Date:** $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""
echo "## Architecture"
echo ""
echo "World geometry is **100% procedural** in \`World.gd\` _ready(). Static scene = ground + HUD only."
echo ""
echo "## Expected content at spawn (0, 3, 0)"
echo ""
echo "| Element | Builder | Expected count |"
echo "|---------|---------|----------------|"
echo "| Plaza fountain | _build_plaza | 1 |"
echo "| Houses | _build_village | 16 (12 road + 4 plaza) |"
echo "| NPCs | _spawn_npcs | 8 |"
echo "| Castle | _build_castle | 1 complex |"
echo "| Dragon | _spawn_dragon | 1 |"
echo "| Trees | _build_trees | ~100 (tree_count) |"
echo "| Walls | _build_walls | Perimeter segments |"
echo "| Rocks | _build_rocks | Scattered |"
echo "| Road torches | _build_road_torches | Along roads |"
echo "| Roads | _plane in _build_village | 2 strips |"
echo ""
echo "## Code verification"
echo ""
for fn in _build_plaza _build_village _build_walls _build_rocks _spawn_npcs _build_castle _spawn_dragon _build_trees _build_road_torches _spawn_player; do
  if grep -q "func $fn" "$WORLD"; then
    echo "- \`$fn\` — present"
  else
    echo "- \`$fn\` — **MISSING**"
  fi
done
echo ""
echo "## Visual quality note"
echo ""
echo "Meshes are primitive (boxes, cylinders, planes). This reads as **prototype** visually but is **not** an empty world if _ready() completes."
echo ""
echo "## Failure modes"
echo ""
echo "1. Stale game binary (debug export / old CDN cache) → green field + HUD only"
echo "2. World.gd parse error → same symptom"
echo "3. Camera at spawn — should see plaza immediately (fountain at origin)"
echo ""
echo "## Log verification (Rogério)"
echo ""
echo "Check \`%LOCALAPPDATA%/DarkWorld/logs/game/game.log\` for:"
echo ""
echo "\`\`\`"
echo "[WORLD] DONE - Trees:N Houses:N NPCs:N Dragons:N"
echo "\`\`\`"
echo ""
echo "If N>0 and screen still empty → GPU/rendering issue (report with screenshot)."
echo ""
echo "## CDN game build"
if [ -f "$ROOT/build/windows/DarkWorld.exe" ]; then
  echo "- Local exe: $(stat -c%s "$ROOT/build/windows/DarkWorld.exe") bytes"
  echo "- Hash: $(sha256sum "$ROOT/build/windows/DarkWorld.exe" | awk '{print $1}')"
fi
MANIFEST=$(curl -sf "https://dark.zorionlabs.net/downloads/launcher/manifest.json" 2>/dev/null || echo "")
if [ -n "$MANIFEST" ]; then
  echo "- CDN game_version: $(echo "$MANIFEST" | python3 -c 'import sys,json; print(json.load(sys.stdin)["game_version"])')"
fi
} > "$OUT"

echo "Written $OUT"
