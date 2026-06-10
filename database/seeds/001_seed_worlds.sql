-- Dark World — Seed Data
-- Popula dados iniciais para o MVP

-- Mundos
INSERT INTO worlds (id, name, world_type, description) VALUES
  ('00000000-0000-0000-0000-000000000001', 'Reino dos Vivos', 'living', 'O mundo principal onde os vivos habitam'),
  ('00000000-0000-0000-0000-000000000002', 'Mundo dos Mortos', 'dead', 'Para onde as almas vão após a morte'),
  ('00000000-0000-0000-0000-000000000003', 'Mundo Congelado', 'frozen', 'Terras eternamente congeladas');

-- Conta admin
INSERT INTO accounts (id, display_name, email, is_admin) VALUES
  ('00000000-0000-0000-0000-000000000100', 'Admin Supremo', 'admin@darkworld.local', true);

-- Entidades — Territórios
INSERT INTO entities (id, type, name, world_id, position_x, position_y, state, metadata) VALUES
  ('00000000-0000-0000-0000-000000000010', 'territory', 'Reino Central', '00000000-0000-0000-0000-000000000001', 0, 0, '{"controlled":true}', '{"region":"central","climate":"temperate"}'),
  ('00000000-0000-0000-0000-000000000011', 'territory', 'Norte Congelado', '00000000-0000-0000-0000-000000000001', -100, 100, '{"controlled":false}', '{"region":"north","climate":"frozen"}'),
  ('00000000-0000-0000-0000-000000000012', 'territory', 'Terras Sombrias', '00000000-0000-0000-0000-000000000001', 100, -50, '{"controlled":false}', '{"region":"dark","climate":"cursed"}'),
  ('00000000-0000-0000-0000-000000000013', 'territory', 'Montanhas Dracônicas', '00000000-0000-0000-0000-000000000001', 80, 80, '{"controlled":false}', '{"region":"mountain","climate":"volcanic"}'),
  ('00000000-0000-0000-0000-000000000014', 'territory', 'Zona de Guerra', '00000000-0000-0000-0000-000000000001', -50, -50, '{"controlled":false}', '{"region":"warzone","climate":"devastated"}');

-- Entidades — Facções
INSERT INTO entities (id, type, name, world_id, state, metadata) VALUES
  ('00000000-0000-0000-0000-000000000020', 'faction', 'Ordem da Luz', '00000000-0000-0000-0000-000000000001', '{"active":true}', '{"type":"kingdom","alignment":"lawful"}'),
  ('00000000-0000-0000-0000-000000000021', 'faction', 'Legião das Sombras', '00000000-0000-0000-0000-000000000001', '{"active":true}', '{"type":"horde","alignment":"chaotic"}'),
  ('00000000-0000-0000-0000-000000000022', 'faction', 'Clãs do Norte', '00000000-0000-0000-0000-000000000001', '{"active":true}', '{"type":"clan","alignment":"neutral"}');

-- Facções (dados específicos)
INSERT INTO factions (id, entity_id, faction_type, leader_account_id, member_count) VALUES
  ('00000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000020', 'kingdom', '00000000-0000-0000-0000-000000000100', 0),
  ('00000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000021', 'horde', NULL, 0),
  ('00000000-0000-0000-0000-000000000032', '00000000-0000-0000-0000-000000000022', 'clan', NULL, 0);

-- Territórios (dados específicos)
INSERT INTO territories (id, entity_id, territory_type, controlling_faction_id, risk_level, boundaries) VALUES
  ('00000000-0000-0000-0000-000000000040', '00000000-0000-0000-0000-000000000010', 'region', '00000000-0000-0000-0000-000000000030', 1, '{"x1":-50,"y1":-50,"x2":50,"y2":50}'),
  ('00000000-0000-0000-0000-000000000041', '00000000-0000-0000-0000-000000000011', 'region', '00000000-0000-0000-0000-000000000032', 5, '{"x1":-150,"y1":50,"x2":-50,"y2":150}'),
  ('00000000-0000-0000-0000-000000000042', '00000000-0000-0000-0000-000000000012', 'region', '00000000-0000-0000-0000-000000000031', 8, '{"x1":50,"y1":-100,"x2":150,"y2":0}'),
  ('00000000-0000-0000-0000-000000000043', '00000000-0000-0000-0000-000000000013', 'region', NULL, 10, '{"x1":30,"y1":30,"x2":130,"y2":130}'),
  ('00000000-0000-0000-0000-000000000044', '00000000-0000-0000-0000-000000000014', 'region', NULL, 9, '{"x1":-100,"y1":-100,"x2":0,"y2":0}');

-- Entidade Dragão (placeholder)
INSERT INTO entities (id, type, name, world_id, position_x, position_y, state, metadata) VALUES
  ('00000000-0000-0000-0000-000000000050', 'dragon', 'Vermithrax, o Antigo', '00000000-0000-0000-0000-000000000001', 105, 105, '{"alive":true,"roaming":false}', '{"type":"ancient","size":"colossal","element":"fire"}');

INSERT INTO dragons (id, entity_id, dragon_type, territory_id, spawn_world_id) VALUES
  ('00000000-0000-0000-0000-000000000060', '00000000-0000-0000-0000-000000000050', 'ancient', '00000000-0000-0000-0000-000000000043', '00000000-0000-0000-0000-000000000001');

-- Auditoria inicial
INSERT INTO audit_logs (event_type, account_id, action, details) VALUES
  ('SYSTEM_INIT', '00000000-0000-0000-0000-000000000100', 'world_initialized', '{"phase":"seed","version":"0.1.0"}');

-- Registro de evento inicial
INSERT INTO events (id, event_type, source_entity_id, world_id, payload, status) VALUES
  ('00000000-0000-0000-0000-000000000070', 'ADMIN_EVENT_TRIGGERED', NULL, '00000000-0000-0000-0000-000000000001', '{"action":"world_created","description":"Mundo inicial povoado com 5 territorios, 3 faccoes e 1 dragao."}', 'completed');
