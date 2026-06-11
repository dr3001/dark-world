-- Dark World — Migration 008: War Kingdom Foundation
-- ~30 new tables for servers, classes, troops, wars, kingdoms, territories

-- ============================================================
-- SERVERS
-- ============================================================
CREATE TABLE IF NOT EXISTS game_servers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    region TEXT NOT NULL DEFAULT 'sa-east-1',
    host TEXT NOT NULL DEFAULT '5.78.142.138',
    port INTEGER NOT NULL DEFAULT 9000,
    status TEXT NOT NULL DEFAULT 'online' CHECK (status IN ('online','offline','maintenance','full')),
    max_players INTEGER NOT NULL DEFAULT 500,
    current_players INTEGER NOT NULL DEFAULT 0,
    is_pvp_enabled BOOLEAN NOT NULL DEFAULT false,
    is_cross_server_enabled BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- HERO CLASSES
-- ============================================================
CREATE TABLE IF NOT EXISTS hero_classes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL DEFAULT '',
    base_hp INTEGER NOT NULL DEFAULT 100,
    base_mana INTEGER NOT NULL DEFAULT 50,
    base_stamina INTEGER NOT NULL DEFAULT 100,
    primary_attribute TEXT NOT NULL DEFAULT 'strength',
    secondary_attribute TEXT DEFAULT NULL,
    allowed_weapons JSONB NOT NULL DEFAULT '[]',
    troop_capacity_base INTEGER NOT NULL DEFAULT 10,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- CHARACTER ORIGIN & ALLEGIANCE
-- ============================================================
CREATE TABLE IF NOT EXISTS character_origins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
    origin_name TEXT NOT NULL DEFAULT 'Viajante do Vale Cinzento',
    homeland TEXT NOT NULL DEFAULT 'Vale Cinzento',
    class_id UUID REFERENCES hero_classes(id),
    server_id UUID REFERENCES game_servers(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(character_id)
);

CREATE TABLE IF NOT EXISTS character_allegiances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
    allegiance_type TEXT NOT NULL DEFAULT 'wanderer' CHECK (allegiance_type IN ('kingdom','clan','order','guild','faction','mercenary','exile','wanderer','staff')),
    allegiance_id UUID,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(character_id)
);

-- ============================================================
-- TROOPS
-- ============================================================
CREATE TABLE IF NOT EXISTS troop_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    category TEXT NOT NULL CHECK (category IN ('infantry','archer','cavalry','scout','guard','mage_unit','siege_unit')),
    base_attack INTEGER NOT NULL DEFAULT 5,
    base_defense INTEGER NOT NULL DEFAULT 5,
    base_hp INTEGER NOT NULL DEFAULT 50,
    cost_zorium NUMERIC(10,2) NOT NULL DEFAULT 10,
    training_time_minutes INTEGER NOT NULL DEFAULT 30,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS hero_troop_capacity (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id UUID NOT NULL REFERENCES hero_classes(id),
    troop_type_id UUID NOT NULL REFERENCES troop_types(id),
    max_capacity INTEGER NOT NULL DEFAULT 10,
    UNIQUE(class_id, troop_type_id)
);

CREATE TABLE IF NOT EXISTS troop_squads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
    troop_type_id UUID NOT NULL REFERENCES troop_types(id),
    quantity INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- SKILLS FOUNDATION
-- ============================================================
CREATE TABLE IF NOT EXISTS skill_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    skill_type TEXT NOT NULL CHECK (skill_type IN ('active','passive','aura','ultimate','formation','troop_skill')),
    class_id UUID REFERENCES hero_classes(id),
    cast_time NUMERIC(5,2) NOT NULL DEFAULT 0,
    cooldown NUMERIC(5,2) NOT NULL DEFAULT 5,
    mana_cost INTEGER NOT NULL DEFAULT 10,
    base_damage INTEGER NOT NULL DEFAULT 0,
    range_meters NUMERIC(5,1) NOT NULL DEFAULT 1,
    server_validation_required BOOLEAN NOT NULL DEFAULT true,
    acquisition_type TEXT NOT NULL DEFAULT 'earned' CHECK (acquisition_type IN ('earned','purchased','event_reward','vip_cosmetic','admin_grant')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS skill_unlocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES skill_definitions(id),
    unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(character_id, skill_id)
);

-- ============================================================
-- WAR DECLARATIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS war_declarations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attacker_type TEXT NOT NULL CHECK (attacker_type IN ('clan','kingdom','faction')),
    attacker_id UUID NOT NULL,
    defender_type TEXT NOT NULL CHECK (defender_type IN ('clan','kingdom','faction')),
    defender_id UUID NOT NULL,
    state TEXT NOT NULL DEFAULT 'draft' CHECK (state IN ('draft','declared','notified','preparation','active','paused','finished','cancelled')),
    declared_by UUID REFERENCES accounts_profile(id),
    preparation_ends_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    reason TEXT DEFAULT '',
    rules JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_war_decl_state ON war_declarations(state);

CREATE TABLE IF NOT EXISTS war_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    war_id UUID NOT NULL REFERENCES war_declarations(id) ON DELETE CASCADE,
    character_id UUID NOT NULL REFERENCES characters(id),
    side TEXT NOT NULL CHECK (side IN ('attacker','defender')),
    role TEXT NOT NULL DEFAULT 'soldier' CHECK (role IN ('commander','captain','officer','soldier','mercenary')),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS war_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    war_id UUID NOT NULL REFERENCES war_declarations(id),
    target_user_id UUID REFERENCES accounts_profile(id),
    channel TEXT NOT NULL DEFAULT 'in_game' CHECK (channel IN ('in_game','chat_system','admin_log')),
    message TEXT NOT NULL,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TERRITORY MAP (enhanced)
-- ============================================================
CREATE TABLE IF NOT EXISTS territory_map (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    world_id UUID REFERENCES worlds(id),
    server_id UUID REFERENCES game_servers(id),
    owner_type TEXT CHECK (owner_type IN ('kingdom','clan','faction','npc',NULL)),
    owner_id UUID,
    biome TEXT NOT NULL DEFAULT 'plains' CHECK (biome IN ('plains','forest','mountain','desert','swamp','tundra','coastal','volcanic')),
    danger_level INTEGER NOT NULL DEFAULT 1 CHECK (danger_level >= 1 AND danger_level <= 10),
    resource_level INTEGER NOT NULL DEFAULT 1,
    pvp_enabled BOOLEAN NOT NULL DEFAULT false,
    war_enabled BOOLEAN NOT NULL DEFAULT false,
    coordinates JSONB NOT NULL DEFAULT '{"x":0,"z":0}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS territory_claims (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    territory_id UUID NOT NULL REFERENCES territory_map(id),
    claimer_type TEXT NOT NULL,
    claimer_id UUID NOT NULL,
    state TEXT NOT NULL DEFAULT 'pending' CHECK (state IN ('pending','active','disputed','lost')),
    claimed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS territory_resources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    territory_id UUID NOT NULL REFERENCES territory_map(id),
    resource_type TEXT NOT NULL CHECK (resource_type IN ('wood','stone','iron','gold','herbs','mana_crystal','food')),
    amount INTEGER NOT NULL DEFAULT 100,
    regen_rate INTEGER NOT NULL DEFAULT 10,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- KINGDOMS (enhanced)
-- ============================================================
CREATE TABLE IF NOT EXISTS kingdom_registry (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    tag TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL DEFAULT '',
    ruler_user_id UUID REFERENCES accounts_profile(id),
    origin_clan_id UUID REFERENCES clans(id),
    member_count INTEGER NOT NULL DEFAULT 1,
    level INTEGER NOT NULL DEFAULT 1,
    treasury_zorium NUMERIC(15,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS kingdom_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kingdom_id UUID NOT NULL REFERENCES kingdom_registry(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES accounts_profile(id),
    rank TEXT NOT NULL DEFAULT 'member' CHECK (rank IN ('king','queen','lord','commander','captain','officer','member','mercenary')),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(kingdom_id, user_id)
);

CREATE TABLE IF NOT EXISTS kingdom_laws (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kingdom_id UUID NOT NULL REFERENCES kingdom_registry(id) ON DELETE CASCADE,
    law_type TEXT NOT NULL,
    value JSONB NOT NULL DEFAULT '{}',
    enacted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- LEADERSHIP
-- ============================================================
CREATE TABLE IF NOT EXISTS leadership_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    priority INTEGER NOT NULL DEFAULT 0,
    permissions JSONB NOT NULL DEFAULT '[]'
);

-- ============================================================
-- WAR RANKINGS
-- ============================================================
CREATE TABLE IF NOT EXISTS war_ranking_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type TEXT NOT NULL CHECK (entity_type IN ('character','clan','kingdom')),
    entity_id UUID NOT NULL,
    score NUMERIC(15,2) NOT NULL DEFAULT 0,
    wars_won INTEGER NOT NULL DEFAULT 0,
    wars_lost INTEGER NOT NULL DEFAULT 0,
    territories_held INTEGER NOT NULL DEFAULT 0,
    season_id UUID REFERENCES ranking_seasons(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- WAR AUDIT LOGS
-- ============================================================
CREATE TABLE IF NOT EXISTS war_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    war_id UUID REFERENCES war_declarations(id),
    actor_id UUID,
    action TEXT NOT NULL,
    details JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_war_logs_war ON war_logs(war_id);

CREATE TABLE IF NOT EXISTS battle_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    war_id UUID REFERENCES war_declarations(id),
    territory_id UUID REFERENCES territory_map(id),
    attacker_id UUID,
    defender_id UUID,
    result TEXT CHECK (result IN ('attacker_won','defender_won','draw','cancelled')),
    score JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- SERVER BALANCE
-- ============================================================
CREATE TABLE IF NOT EXISTS server_power_ratings (
    server_id UUID PRIMARY KEY REFERENCES game_servers(id),
    total_players INTEGER NOT NULL DEFAULT 0,
    avg_level NUMERIC(5,1) NOT NULL DEFAULT 1,
    total_wars INTEGER NOT NULL DEFAULT 0,
    power_score NUMERIC(10,2) NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- SEEDS
-- ============================================================

-- Server 01
INSERT INTO game_servers (id, name, region, host, port, status, max_players) VALUES
('s0000000-0000-0000-0000-000000000001', 'Vale Cinzento', 'eu-central-1', '5.78.142.138', 9000, 'online', 500)
ON CONFLICT (id) DO NOTHING;

-- 10 Hero Classes
INSERT INTO hero_classes (id, name, description, base_hp, base_mana, base_stamina, primary_attribute, secondary_attribute, allowed_weapons, troop_capacity_base) VALUES
('h0000000-0000-0000-0000-000000000001', 'Knight', 'Cavaleiro de armadura pesada', 150, 30, 120, 'strength', 'vitality', '["sword","shield","lance"]', 15),
('h0000000-0000-0000-0000-000000000002', 'Archer', 'Atirador de longa distancia', 90, 40, 130, 'dexterity', 'luck', '["bow","crossbow","dagger"]', 12),
('h0000000-0000-0000-0000-000000000003', 'Mage', 'Mago arcano', 70, 150, 60, 'intelligence', 'charisma', '["staff","wand","orb"]', 8),
('h0000000-0000-0000-0000-000000000004', 'Assassin', 'Assassino das sombras', 80, 50, 150, 'dexterity', 'strength', '["dagger","short_sword","poison"]', 6),
('h0000000-0000-0000-0000-000000000005', 'Warrior', 'Guerreiro brutal', 130, 20, 140, 'strength', 'dexterity', '["axe","hammer","great_sword"]', 14),
('h0000000-0000-0000-0000-000000000006', 'Priest', 'Sacerdote curador', 80, 130, 70, 'intelligence', 'vitality', '["staff","holy_symbol","mace"]', 8),
('h0000000-0000-0000-0000-000000000007', 'Beastmaster', 'Domador de criaturas', 100, 60, 120, 'charisma', 'dexterity', '["whip","spear","claw"]', 20),
('h0000000-0000-0000-0000-000000000008', 'Warlock', 'Feiticeiro sombrio', 75, 140, 50, 'intelligence', 'luck', '["dark_staff","tome","ring"]', 10),
('h0000000-0000-0000-0000-000000000009', 'Guardian', 'Protetor do vale', 160, 40, 100, 'vitality', 'strength', '["tower_shield","mace","spear"]', 16),
('h0000000-0000-0000-0000-000000000010', 'Mercenary', 'Mercenario sem lealdade', 110, 40, 130, 'strength', 'luck', '["any"]', 12)
ON CONFLICT (id) DO NOTHING;

-- 7 Troop Types
INSERT INTO troop_types (id, name, category, base_attack, base_defense, base_hp, cost_zorium) VALUES
('t0000000-0000-0000-0000-000000000001', 'Infantaria Leve', 'infantry', 5, 3, 40, 5),
('t0000000-0000-0000-0000-000000000002', 'Infantaria Pesada', 'infantry', 8, 7, 70, 15),
('t0000000-0000-0000-0000-000000000003', 'Arqueiro', 'archer', 7, 2, 30, 8),
('t0000000-0000-0000-0000-000000000004', 'Cavalaria', 'cavalry', 10, 5, 60, 20),
('t0000000-0000-0000-0000-000000000005', 'Batedor', 'scout', 4, 2, 25, 4),
('t0000000-0000-0000-0000-000000000006', 'Unidade Arcana', 'mage_unit', 12, 1, 20, 25),
('t0000000-0000-0000-0000-000000000007', 'Maquina de Cerco', 'siege_unit', 15, 10, 100, 50)
ON CONFLICT (id) DO NOTHING;

-- 8 Leadership Roles
INSERT INTO leadership_roles (id, name, priority, permissions) VALUES
('l0000000-0000-0000-0000-000000000001', 'King', 8, '["all"]'),
('l0000000-0000-0000-0000-000000000002', 'Queen', 7, '["all"]'),
('l0000000-0000-0000-0000-000000000003', 'Lord', 6, '["recruit","manage_treasury","declare_war"]'),
('l0000000-0000-0000-0000-000000000004', 'Commander', 5, '["recruit","assign_troops","lead_battle"]'),
('l0000000-0000-0000-0000-000000000005', 'Captain', 4, '["assign_troops","lead_squad"]'),
('l0000000-0000-0000-0000-000000000006', 'Officer', 3, '["lead_squad","send_announcement"]'),
('l0000000-0000-0000-0000-000000000007', 'Member', 1, '["participate"]'),
('l0000000-0000-0000-0000-000000000008', 'Mercenary', 0, '["participate_limited"]')
ON CONFLICT (id) DO NOTHING;

-- 5 Territory Map entries
INSERT INTO territory_map (id, name, world_id, biome, danger_level, resource_level, coordinates) VALUES
('tm000000-0000-0000-0000-000000000001', 'Vale Cinzento Central', 'a0000000-0000-0000-0000-000000000001', 'plains', 3, 5, '{"x":0,"z":0}'),
('tm000000-0000-0000-0000-000000000002', 'Floresta Sombria', 'a0000000-0000-0000-0000-000000000001', 'forest', 6, 7, '{"x":-100,"z":50}'),
('tm000000-0000-0000-0000-000000000003', 'Montanhas de Ferro', 'a0000000-0000-0000-0000-000000000001', 'mountain', 8, 9, '{"x":150,"z":-80}'),
('tm000000-0000-0000-0000-000000000004', 'Pantano Venenoso', 'a0000000-0000-0000-0000-000000000001', 'swamp', 7, 4, '{"x":-80,"z":-120}'),
('tm000000-0000-0000-0000-000000000005', 'Costa dos Dragoes', 'a0000000-0000-0000-0000-000000000001', 'coastal', 9, 8, '{"x":200,"z":100}')
ON CONFLICT (id) DO NOTHING;
