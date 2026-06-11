-- Dark World — Migration 009: Lore Engine
-- Persistent narrative history for characters, clans, kingdoms, territories, NPCs

-- ============================================================
-- CHARACTER HISTORY
-- ============================================================
CREATE TABLE IF NOT EXISTS character_biographies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
    origin_name TEXT NOT NULL DEFAULT 'Viajante do Vale Cinzento',
    birth_homeland TEXT NOT NULL DEFAULT 'Vale Cinzento',
    first_server_id UUID REFERENCES game_servers(id),
    class_path TEXT,
    public_biography TEXT DEFAULT '',
    private_notes TEXT DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(character_id)
);

CREATE TABLE IF NOT EXISTS character_timeline (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL CHECK (event_type IN ('birth','quest_complete','war_victory','clan_join','kingdom_join','title_earned','death','resurrection','exile','return','other')),
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    world_time TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_timeline_char ON character_timeline(character_id);

CREATE TABLE IF NOT EXISTS character_reputation (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
    target_type TEXT NOT NULL CHECK (target_type IN ('npc','clan','kingdom','faction','world')),
    target_id TEXT NOT NULL DEFAULT 'world',
    reputation_score INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(character_id, target_type, target_id)
);

CREATE TABLE IF NOT EXISTS character_titles_earned (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    earned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(character_id, title)
);

-- ============================================================
-- CLAN LORE
-- ============================================================
CREATE TABLE IF NOT EXISTS clan_lore (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clan_id UUID NOT NULL REFERENCES clans(id) ON DELETE CASCADE,
    founder_name TEXT DEFAULT 'Desconhecido',
    founding_story TEXT DEFAULT '',
    ideology TEXT DEFAULT '',
    motto TEXT DEFAULT '',
    symbol TEXT DEFAULT '',
    territory_origin TEXT DEFAULT 'Vale Cinzento',
    is_secret BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(clan_id)
);

CREATE TABLE IF NOT EXISTS clan_chronicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clan_id UUID NOT NULL REFERENCES clans(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    actor_id UUID REFERENCES characters(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_clan_chronicles ON clan_chronicles(clan_id);

-- ============================================================
-- KINGDOM LORE
-- ============================================================
CREATE TABLE IF NOT EXISTS kingdom_lore (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kingdom_id UUID NOT NULL REFERENCES kingdom_registry(id) ON DELETE CASCADE,
    origin_story TEXT DEFAULT '',
    culture TEXT DEFAULT 'Medieval dark fantasy',
    laws_json JSONB NOT NULL DEFAULT '[]',
    territory_description TEXT DEFAULT '',
    is_secret BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(kingdom_id)
);

CREATE TABLE IF NOT EXISTS kingdom_chronicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kingdom_id UUID NOT NULL REFERENCES kingdom_registry(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TERRITORY LORE
-- ============================================================
CREATE TABLE IF NOT EXISTS territory_lore (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    territory_id UUID NOT NULL REFERENCES territory_map(id) ON DELETE CASCADE,
    history_text TEXT DEFAULT '',
    notable_events JSONB NOT NULL DEFAULT '[]',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(territory_id)
);

CREATE TABLE IF NOT EXISTS territory_chronicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    territory_id UUID NOT NULL REFERENCES territory_map(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    actor_type TEXT,
    actor_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- NPC LORE
-- ============================================================
CREATE TABLE IF NOT EXISTS npc_lore (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    npc_name TEXT NOT NULL UNIQUE,
    role TEXT NOT NULL DEFAULT 'villager',
    biography TEXT DEFAULT '',
    allowed_topics JSONB NOT NULL DEFAULT '[]',
    lore_function TEXT CHECK (lore_function IN ('scribe','herald','quest_giver','merchant','blacksmith','healer','guard',NULL)),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- GLOBAL CHRONICLES
-- ============================================================
CREATE TABLE IF NOT EXISTS world_chronicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    world_id UUID REFERENCES worlds(id),
    is_public BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_world_chronicles ON world_chronicles(created_at);

-- ============================================================
-- SEEDS
-- ============================================================
INSERT INTO character_biographies (character_id, origin_name, birth_homeland) 
SELECT id, 'Viajante do Vale Cinzento', 'Vale Cinzento' FROM characters
ON CONFLICT DO NOTHING;

INSERT INTO character_timeline (character_id, event_type, title, description) 
SELECT id, 'birth', 'Nascimento', 'Despertou no Vale Cinzento pela primeira vez' FROM characters
ON CONFLICT DO NOTHING;

INSERT INTO character_reputation (character_id, target_type, target_id, reputation_score) 
SELECT id, 'world', 'world', 0 FROM characters
ON CONFLICT DO NOTHING;

INSERT INTO clan_lore (clan_id, founder_name, founding_story, ideology, motto) 
SELECT id, 'Guardião Anônimo', 'Clã oficial do Dark World', 'Ordem e proteção do Vale Cinzento', 'Pela luz do Vale' FROM clans
ON CONFLICT DO NOTHING;

INSERT INTO territory_lore (territory_id, history_text) 
SELECT id, 'Território ancestral do Vale Cinzento' FROM territory_map
ON CONFLICT DO NOTHING;

INSERT INTO npc_lore (npc_name, role, biography, lore_function, allowed_topics) VALUES
('Ferreiro Thorin', 'blacksmith', 'Mestre ferreiro do Vale. Sua forja ancestral forjou armas para gerações de aventureiros.', 'blacksmith', '["armas","forja","upgrades","história","metais"]'::jsonb),
('Curandeira Lyra', 'healer', 'Curandeira que protege o Vale com ervas ancestrais e conhecimento arcano.', 'healer', '["cura","poções","ervas","vorak","proteção"]'::jsonb),
('Guardiao do Vale', 'guard', 'Protetor lendário do Vale Cinzento. Conhece os segredos antigos da região.', 'quest_giver', '["missões","história","vorak","lore","ameaças"]'::jsonb),
('Escriba do Vale', 'scribe', 'Cronista oficial. Registra feitos de heróis, guerras e eventos do mundo.', 'scribe', '["história","personagens","clãs","reinos","eventos","crônicas","guerras","reputação"]'::jsonb),
('Arauto do Vale', 'herald', 'Mensageiro oficial. Anuncia eventos, temporadas e notícias importantes.', 'herald', '["eventos","temporadas","rankings","notícias","alertas","clima"]'::jsonb)
ON CONFLICT (npc_name) DO NOTHING;
