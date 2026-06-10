#!/bin/bash
# Test Death → Afterlife flow
set -e
echo "=== Death → Afterlife Flow Test ==="
cd /opt/darkworld/world-engine
# Clean previous test data
docker exec darkworld-postgres psql -U darkworld_admin -d darkworld -c "DELETE FROM event_queue; DELETE FROM afterlife_records; DELETE FROM deaths; DELETE FROM characters WHERE character_name='Heroi Teste'; DELETE FROM entities WHERE name='Heroi Teste'; DELETE FROM events WHERE payload->>'test'='true'; DELETE FROM accounts_profile WHERE display_name='Heroi Teste';" -q 2>/dev/null
# Run test
npx tsx src/seed-run.ts 2>&1
echo "PASS: Death flow test completed"
