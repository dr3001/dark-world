-- Dark World — Mission 2 Schema
-- Migration 002: Estrutura alinhada com spec da Missão 2

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- ACCOUNTS PROFILE (vinculado ao Nakama)
-- ============================================================
CREATE TABLE accounts_profile (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nakama_user_id TEXT NULL,
  display_name TEXT NOT NULL,
  email TEXT,
  is_admin BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- WORLDS
-- ============================================================
CREATE TABLE worlds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  world_type TEXT NOT NULL,
  description TEXT,
  state JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ENTITIES (tabela genérica central)
-- ============================================================
CREATE TABLE entities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  world_id UUID REFERENCES worlds(id),
  entity_type TEXT NOT NULL,
  name TEXT,
  owner_account_id UUID,
  position_x NUMERIC DEFAULT 0,
  position_y NUMERIC DEFAULT 0,
  position_z NUMERIC DEFAULT 0,
  status TEXT DEFAULT 'active',
  state JSONB DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ NULL
);

-- ============================================================
-- ENTITY COMPONENTS
-- ============================================================
CREATE TABLE entity_components (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
  component_type TEXT NOT NULL,
  data JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- EVENTS
-- ============================================================
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type TEXT NOT NULL,
  source_entity_id UUID NULL,
  target_entity_id UUID NULL,
  world_id UUID NULL,
  payload JSONB DEFAULT '{}',
  status TEXT DEFAULT 'created',
  created_by TEXT DEFAULT 'system',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ NULL,
  error TEXT NULL
);

-- ============================================================
-- EVENT QUEUE
-- ============================================================
CREATE TABLE event_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  priority INTEGER DEFAULT 100,
  available_at TIMESTAMPTZ DEFAULT NOW(),
  attempts INTEGER DEFAULT 0,
  locked_at TIMESTAMPTZ NULL,
  locked_by TEXT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- AUDIT LOGS
-- ============================================================
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_type TEXT NOT NULL,
  actor_id TEXT NULL,
  action TEXT NOT NULL,
  target_type TEXT NULL,
  target_id TEXT NULL,
  payload JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- CHARACTERS
-- ============================================================
CREATE TABLE characters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID REFERENCES accounts_profile(id),
  entity_id UUID REFERENCES entities(id),
  character_name TEXT NOT NULL,
  character_role TEXT DEFAULT 'wanderer',
  life_state TEXT DEFAULT 'alive',
  mirror_character_id UUID NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- TERRITORIES
-- ============================================================
CREATE TABLE territories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id UUID REFERENCES entities(id),
  world_id UUID REFERENCES worlds(id),
  name TEXT NOT NULL,
  controlled_by_faction_id UUID NULL,
  danger_level INTEGER DEFAULT 1,
  state JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- FACTIONS
-- ============================================================
CREATE TABLE factions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id UUID REFERENCES entities(id),
  name TEXT NOT NULL,
  faction_type TEXT NOT NULL,
  leader_account_id UUID NULL,
  member_count INTEGER DEFAULT 0,
  state JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- KINGDOMS
-- ============================================================
CREATE TABLE kingdoms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id UUID REFERENCES entities(id),
  name TEXT NOT NULL,
  ruler_character_id UUID NULL,
  faction_id UUID,
  state JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- WARS
-- ============================================================
CREATE TABLE wars (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  attacker_faction_id UUID NULL,
  defender_faction_id UUID NULL,
  status TEXT DEFAULT 'active',
  reason TEXT NULL,
  state JSONB DEFAULT '{}',
  started_at TIMESTAMPTZ DEFAULT NOW(),
  ended_at TIMESTAMPTZ NULL
);

-- ============================================================
-- AFTERLIFE RECORDS
-- ============================================================
CREATE TABLE afterlife_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  character_id UUID REFERENCES characters(id),
  death_event_id UUID REFERENCES events(id),
  from_world_id UUID REFERENCES worlds(id),
  afterlife_world_id UUID REFERENCES worlds(id),
  entered_at TIMESTAMPTZ DEFAULT NOW(),
  eligible_return_at TIMESTAMPTZ NULL,
  returned_at TIMESTAMPTZ NULL,
  state JSONB DEFAULT '{}'
);

-- ============================================================
-- DRAGONS
-- ============================================================
CREATE TABLE dragons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
  dragon_name TEXT NOT NULL,
  dragon_type TEXT DEFAULT 'ancient',
  threat_level INTEGER DEFAULT 10,
  territory_id UUID NULL,
  spawn_world_id UUID,
  is_alive BOOLEAN DEFAULT true,
  state JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- SYSTEM JOBS
-- ============================================================
CREATE TABLE system_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_type TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  payload JSONB DEFAULT '{}',
  scheduled_at TIMESTAMPTZ DEFAULT NOW(),
  started_at TIMESTAMPTZ NULL,
  finished_at TIMESTAMPTZ NULL,
  error TEXT NULL
);

-- ============================================================
-- ADMIN ACTIONS
-- ============================================================
CREATE TABLE admin_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id TEXT NOT NULL,
  action TEXT NOT NULL,
  payload JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- DEATHS (registro histórico)
-- ============================================================
CREATE TABLE deaths (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  character_id UUID REFERENCES characters(id),
  killed_by_entity_id UUID REFERENCES entities(id),
  world_id UUID REFERENCES worlds(id),
  death_location JSONB DEFAULT '{}',
  died_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ÍNDICES
-- ============================================================
CREATE INDEX idx_events_type ON events(event_type);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_entities_type ON entities(entity_type);
CREATE INDEX idx_entities_world ON entities(world_id);
CREATE INDEX idx_entity_components_entity ON entity_components(entity_id);
CREATE INDEX idx_entity_components_type ON entity_components(component_type);
CREATE INDEX idx_characters_account ON characters(account_id);
CREATE INDEX idx_territories_world ON territories(world_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_event_queue_available ON event_queue(available_at);
