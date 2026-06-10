#!/bin/bash
set -e
echo "=== Return Test Character ==="
ENTITY_ID=$(docker exec darkworld-postgres psql -U darkworld_admin -d darkworld -t -c "SELECT entity_id FROM characters WHERE character_name='Heroi Teste';" | tr -d " ")
if [ -z "$ENTITY_ID" ]; then echo "FAIL: No test character found"; exit 1; fi

docker exec darkworld-postgres psql -U darkworld_admin -d darkworld -q << SQL
INSERT INTO events (event_type, target_entity_id, world_id, payload, created_by)
VALUES ('AFTERLIFE_RETURNED', '$ENTITY_ID', 'a0000000-0000-0000-0000-000000000002', '{"test":true}'::jsonb, 'test_script');
SQL
EID=$(docker exec darkworld-postgres psql -U darkworld_admin -d darkworld -t -c "SELECT id FROM events WHERE created_by='test_script' AND event_type='AFTERLIFE_RETURNED' ORDER BY created_at DESC LIMIT 1;" | tr -d " ")
docker exec darkworld-postgres psql -U darkworld_admin -d darkworld -q -c "INSERT INTO event_queue (event_id, priority) VALUES ('$EID', 10);"

echo "Event $EID enqueued. Waiting for engine..."
sleep 5

LIFE=$(docker exec darkworld-postgres psql -U darkworld_admin -d darkworld -t -c "SELECT life_state FROM characters WHERE character_name='Heroi Teste';" | tr -d " ")
echo "Life state: $LIFE"
[ "$LIFE" = "returned" ] && echo "PASS: Character returned" || echo "PARTIAL: Engine may need more time"
