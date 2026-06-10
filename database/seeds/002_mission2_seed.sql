-- Dark World — Mission 2 Seed Data

-- ============================================================
-- 1. MUNDOS
-- ============================================================
INSERT INTO worlds (id, slug, name, world_type, description, state) VALUES
  ('a0000000-0000-0000-0000-000000000001', 'living_world', 'Mundo dos Vivos', 'living', 'O mundo principal onde os vivos habitam, constroem e guerreiam.', '{"climate":"temperate","danger":"moderate"}'),
  ('a0000000-0000-0000-0000-000000000002', 'frozen_afterlife', 'Mundo Congelado', 'frozen', 'O reino gelado para onde as almas sao enviadas apos a morte.', '{"climate":"frozen","danger":"high","afterlife":true}'),
  ('a0000000-0000-0000-0000-000000000003', 'shadow_realm', 'Reino das Sombras', 'shadow', 'Dimensao sombria reservada para expansao futura.', '{"climate":"cursed","danger":"extreme"}');

-- ============================================================
-- 2. ENTIDADES — Território
-- ============================================================
INSERT INTO entities (id, world_id, entity_type, name, position_x, position_y, status, state, metadata) VALUES
  ('b0000000-0000-0000-0000-000000000010', 'a0000000-0000-0000-0000-000000000001', 'territory', 'Vale Cinzento', 0, 0, 'active', '{"controlled":true}', '{"region":"central","climate":"temperate","danger":1}');

INSERT INTO territories (id, entity_id, world_id, name, controlled_by_faction_id, danger_level, state) VALUES
  ('c0000000-0000-0000-0000-000000000010', 'b0000000-0000-0000-0000-000000000010', 'a0000000-0000-0000-0000-000000000001', 'Vale Cinzento', 'c0000000-0000-0000-0000-000000000020', 1, '{}');

-- ============================================================
-- 3. ENTIDADES — Facções
-- ============================================================
INSERT INTO entities (id, world_id, entity_type, name, status, state, metadata) VALUES
  ('b0000000-0000-0000-0000-000000000020', 'a0000000-0000-0000-0000-000000000001', 'faction', 'Reino Central', 'active', '{"active":true}', '{"type":"kingdom","alignment":"lawful","race":"human"}'),
  ('b0000000-0000-0000-0000-000000000021', 'a0000000-0000-0000-0000-000000000002', 'faction', 'Legião Gelada', 'active', '{"active":true}', '{"type":"undead_horde","alignment":"chaotic","race":"undead"}');

INSERT INTO factions (id, entity_id, name, faction_type, member_count, state) VALUES
  ('c0000000-0000-0000-0000-000000000020', 'b0000000-0000-0000-0000-000000000020', 'Reino Central', 'kingdom', 0, '{}'),
  ('c0000000-0000-0000-0000-000000000021', 'b0000000-0000-0000-0000-000000000021', 'Legião Gelada', 'undead_horde', 0, '{}');

-- ============================================================
-- 4. ENTIDADE — Dragão
-- ============================================================
INSERT INTO entities (id, world_id, entity_type, name, position_x, position_y, status, state, metadata) VALUES
  ('b0000000-0000-0000-0000-000000000050', 'a0000000-0000-0000-0000-000000000001', 'dragon', 'Vorak, o Antigo', 200, 200, 'active', '{"alive":true,"roaming":false}', '{"type":"ancient","element":"frost","size":"colossal"}');

INSERT INTO dragons (id, entity_id, dragon_name, dragon_type, threat_level, territory_id, spawn_world_id, is_alive, state) VALUES
  ('c0000000-0000-0000-0000-000000000050', 'b0000000-0000-0000-0000-000000000050', 'Vorak, o Antigo', 'ancient', 10, 'c0000000-0000-0000-0000-000000000010', 'a0000000-0000-0000-0000-000000000001', true, '{}');

-- ============================================================
-- 5. EVENTOS INICIAIS
-- ============================================================
INSERT INTO events (id, event_type, source_entity_id, world_id, payload, status, created_by) VALUES
  ('e0000000-0000-0000-0000-000000000001', 'WORLD_CREATED', NULL, 'a0000000-0000-0000-0000-000000000001', '{"description":"Mundo dos Vivos inicializado com territorios, faccoes e dragao."}', 'completed', 'system'),
  ('e0000000-0000-0000-0000-000000000002', 'DRAGON_SPAWNED', 'b0000000-0000-0000-0000-000000000050', 'a0000000-0000-0000-0000-000000000001', '{"description":"Vorak, o Antigo, surgiu nas montanhas do Vale Cinzento."}', 'completed', 'system');

-- ============================================================
-- 6. AUDITORIA INICIAL
-- ============================================================
INSERT INTO audit_logs (actor_type, actor_id, action, target_type, target_id, payload) VALUES
  ('system', 'mission_2', 'worlds_seeded', 'world', 'a0000000-0000-0000-0000-000000000001', '{"worlds":3,"territories":1,"factions":2,"dragons":1}'),
  ('system', 'mission_2', 'dragon_spawned', 'dragon', 'b0000000-0000-0000-0000-000000000050', '{"dragon_name":"Vorak, o Antigo"}');
