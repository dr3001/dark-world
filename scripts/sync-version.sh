#!/bin/bash
# Sync version.json across portal and templates
set -euo pipefail
ROOT="/opt/darkworld"
V="$ROOT/version.json"
GV=$(python3 -c "import json; print(json.load(open('$V'))['game_version'])")
LV=$(python3 -c "import json; print(json.load(open('$V'))['launcher_version'])")
echo "Syncing versions: game=$GV launcher=$LV"
PORTAL="/var/www/zorionlabs/dark/index.html"
if [ -f "$PORTAL" ]; then
  sed -i "s/v[0-9]\+\.[0-9]\+\.[0-9]\+/v$GV/g" "$PORTAL" 2>/dev/null || true
fi
mkdir -p "$ROOT/scripts/templates"
python3 -c "
import json
v = json.load(open('$V'))
with open('$ROOT/scripts/templates/installer-version.json', 'w') as f:
    json.dump({'game_version': v['game_version'], 'launcher_version': v['launcher_version']}, f)
"
echo "Version sync complete: game=$GV launcher=$LV"
