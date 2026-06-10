#!/bin/bash
set -e
echo "=== Create Test Character ==="
docker exec darkworld-postgres psql -U darkworld_admin -d darkworld -q << SQL
DELETE FROM event_queue;
DELETE FROM afterlife_records WHERE character_id IN (SELECT id FROM characters WHERE character_name = 'Heroi Teste');
DELETE FROM deaths WHERE character_id IN (SELECT id FROM characters WHERE character_name = 'Heroi Teste');
DELETE FROM characters WHERE character_name = 'Heroi Teste';
DELETE FROM entities WHERE name = 'Heroi Teste';
DELETE FROM events WHERE created_by IN ('test_script', 'final_sweep');
DELETE FROM audit_logs WHERE actor_id IN ('death_module', 'afterlife_module', 'dragon_module');
DELETE FROM accounts_profile WHERE display_name = 'Heroi Teste';
INSERT INTO accounts_profile (id, display_name) VALUES ('d0000000-0000-0000-0000-000000000001', 'Heroi Teste') ON CONFLICT (id) DO NOTHING;
INSERT INTO entities (id, world_id, entity_type, name, owner_account_id, position_x, position_y) VALUES ('d0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'player_character', 'Heroi Teste', 'd0000000-0000-0000-0000-000000000001', 100, 100) ON CONFLICT (id) DO NOTHING;
INSERT INTO characters (id, account_id, entity_id, character_name, character_role, life_state) VALUES ('d0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000002', 'Heroi Teste', 'wanderer', 'alive') ON CONFLICT (id) DO NOTHING;
SQL
echo "Character: Heroi Teste"
LIFE=$(docker exec darkworld-postgres psql -U darkworld_admin -d darkworld -t -c "SELECT life_state FROM characters WHERE character_name='Heroi Teste';" | tr -d " ")
echo "Life state: $LIFE"
echo "PASS: Character created"
