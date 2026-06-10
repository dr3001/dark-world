-- Dark World — Schema Inicial
-- Migration 001: Estrutura base

-- Extensões
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- WORLDS (mundos paralelos)
-- ============================================================
CREATE TABLE worlds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  world_type VARCHAR(50) NOT NULL, -- living, dead, frozen
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ACCOUNTS (vinculado ao Nakama)
-- ============================================================
CREATE TABLE accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nakama_user_id UUID, -- FK para users do Nakama (soft ref)
  display_name VARCHAR(255),
  email VARCHAR(255),
  is_admin BOOLEAN DEFAULT false,
  is_banned BOOLEAN DEFAULT false,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- PLAYERS
-- ============================================================
CREATE TABLE players (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID REFERENCES accounts(id) ON DELETE CASCADE,
  display_name VARCHAR(255) NOT NULL,
  status VARCHAR(50) DEFAULT 'active',
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- CHARACTERS
-- ============================================================
CREATE TABLE characters (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id UUID, -- FK adicionada depois (entidades criadas primeiro)
  player_id UUID REFERENCES players(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  faction_id UUID,
  is_alive BOOLEAN DEFAULT true,
  death_count INTEGER DEFAULT 0,
  afterlife_world_id UUID REFERENCES worlds(id),
  last_death_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ENTITIES (tabela genérica principal)
-- ============================================================
CREATE TABLE entities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type VARCHAR(50) NOT NULL,
  name VARCHAR(255) NOT NULL,
  world_id UUID REFERENCES worlds(id),
  owner_account_id UUID REFERENCES accounts(id),
  position_x DOUBLE PRECISION DEFAULT 0,
  position_y DOUBLE PRECISION DEFAULT 0,
  position_z DOUBLE PRECISION DEFAULT 0,
  state JSONB DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- FK de characters.entity_id para entities
ALTER TABLE characters ADD CONSTRAINT fk_characters_entity 
  FOREIGN KEY (entity_id) REFERENCES entities(id) ON DELETE SET NULL;

-- ============================================================
-- ENTITY COMPONENTS (comportamento modular)
-- ============================================================
CREATE TABLE entity_components (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
  component_type VARCHAR(100) NOT NULL,
  data JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_entity_components_entity ON entity_components(entity_id);
CREATE INDEX idx_entity_components_type ON entity_components(component_type);

-- ============================================================
-- TERRITORIES
-- ============================================================
CREATE TABLE territories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
  territory_type VARCHAR(50) DEFAULT 'region',
  controlling_faction_id UUID,
  contested BOOLEAN DEFAULT false,
  risk_level INTEGER DEFAULT 1 CHECK (risk_level BETWEEN 1 AND 10),
  boundaries JSONB DEFAULT '{}', -- { x1, y1, x2, y2 }
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- FACTIONS
-- ============================================================
CREATE TABLE factions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
  faction_type VARCHAR(50) DEFAULT 'kingdom',
  leader_account_id UUID REFERENCES accounts(id),
  member_count INTEGER DEFAULT 0,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- KINGDOMS
-- ============================================================
CREATE TABLE kingdoms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
  ruler_account_id UUID REFERENCES accounts(id),
  faction_id UUID REFERENCES factions(id),
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- WARS
-- ============================================================
CREATE TABLE wars (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  attacker_faction_id UUID REFERENCES factions(id),
  defender_faction_id UUID REFERENCES factions(id),
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'ended', 'truce')),
  started_at TIMESTAMPTZ DEFAULT NOW(),
  ended_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- DEATHS
-- ============================================================
CREATE TABLE deaths (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  character_id UUID REFERENCES characters(id),
  killed_by_entity_id UUID REFERENCES entities(id),
  world_id UUID REFERENCES worlds(id),
  death_location JSONB DEFAULT '{}', -- { x, y, z }
  afterlife_world_id UUID REFERENCES worlds(id),
  died_at TIMESTAMPTZ DEFAULT NOW(),
  returned_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}'
);

-- ============================================================
-- AFTERLIFE RECORDS
-- ============================================================
CREATE TABLE afterlife_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  character_id UUID REFERENCES characters(id),
  death_id UUID REFERENCES deaths(id),
  afterlife_world_id UUID REFERENCES worlds(id),
  entered_at TIMESTAMPTZ DEFAULT NOW(),
  returned_at TIMESTAMPTZ,
  afterlife_actions JSONB DEFAULT '[]',
  metadata JSONB DEFAULT '{}'
);

-- ============================================================
-- DRAGONS
-- ============================================================
CREATE TABLE dragons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id UUID REFERENCES entities(id) ON DELETE CASCADE,
  dragon_type VARCHAR(50) DEFAULT 'ancient',
  is_alive BOOLEAN DEFAULT true,
  territory_id UUID REFERENCES territories(id),
  spawn_world_id UUID REFERENCES worlds(id),
  last_spawned_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- EVENTS
-- ============================================================
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(100) NOT NULL,
  source_entity_id UUID REFERENCES entities(id),
  target_entity_id UUID REFERENCES entities(id),
  world_id UUID REFERENCES worlds(id),
  payload JSONB DEFAULT '{}',
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'retrying')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ,
  created_by UUID REFERENCES accounts(id),
  error_message TEXT,
  retry_count INTEGER DEFAULT 0
);

CREATE INDEX idx_events_type ON events(event_type);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_world ON events(world_id);

-- ============================================================
-- EVENT QUEUE
-- ============================================================
CREATE TABLE event_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID REFERENCES events(id) ON DELETE CASCADE,
  priority INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- AUDIT LOGS
-- ============================================================
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(100),
  entity_id UUID REFERENCES entities(id),
  account_id UUID REFERENCES accounts(id),
  action VARCHAR(255) NOT NULL,
  details JSONB DEFAULT '{}',
  ip_address INET,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_account ON audit_logs(account_id);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_id);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at);

-- ============================================================
-- ADMIN ACTIONS
-- ============================================================
CREATE TABLE admin_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_account_id UUID REFERENCES accounts(id),
  action_type VARCHAR(100) NOT NULL,
  target_entity_id UUID REFERENCES entities(id),
  payload JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- SYSTEM JOBS (agendados)
-- ============================================================
CREATE TABLE system_jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_type VARCHAR(100) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'completed', 'failed')),
  payload JSONB DEFAULT '{}',
  scheduled_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- ÍNDICES ADICIONAIS
-- ============================================================
CREATE INDEX idx_entities_type ON entities(type);
CREATE INDEX idx_entities_world ON entities(world_id);
CREATE INDEX idx_entities_owner ON entities(owner_account_id);
