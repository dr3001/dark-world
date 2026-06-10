#!/bin/bash
set -e
echo "=== Dragon Spawn Test ==="
DRAGON_COUNT=$(docker exec darkworld-postgres psql -U darkworld_admin -d darkworld -t -c "SELECT count(*) FROM dragons WHERE is_alive = true;" 2>/dev/null | tr -d " ")
echo "Dragons alive: $DRAGON_COUNT"
if [ "$DRAGON_COUNT" -ge 1 ] 2>/dev/null; then
  echo "PASS: Dragon exists"
else
  echo "FAIL: No dragon found"
  exit 1
fi
