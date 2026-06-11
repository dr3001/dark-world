-- Dark World — Migration 003: RPG Foundation
-- Tabelas para stats, itens, inventario, equipamentos, economia, NPCs, quests, save

-- ============================================================
-- CHARACTER STATS
-- ============================================================
CREATE TABLE IF NOT EXISTS character_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
    hp INTEGER NOT NULL DEFAULT 100,
    max_hp INTEGER NOT NULL DEFAULT 100,
    mana INTEGER NOT NULL DEFAULT 50,
    max_mana INTEGER NOT NULL DEFAULT 50,
    level INTEGER NOT NULL DEFAULT 1,
    xp INTEGER NOT NULL DEFAULT 0,
    zorium NUMERIC(15,2) NOT NULL DEFAULT 0,
    strength INTEGER NOT NULL DEFAULT 5,
    dexterity INTEGER NOT NULL DEFAULT 5,
    intelligence INTEGER NOT NULL DEFAULT 5,
    vitality INTEGER NOT NULL DEFAULT 5,
    charisma INTEGER NOT NULL DEFAULT 3,
    luck INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(character_id)
);

-- ============================================================
-- ITEMS
-- ============================================================
CREATE TABLE IF NOT EXISTS items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    item_type TEXT NOT NULL CHECK (item_type IN ('weapon','armor','consumable','quest_item','accessory','material')),
    rarity TEXT NOT NULL DEFAULT 'common' CHECK (rarity IN ('common','uncommon','rare','epic','legendary','mythic')),
    slot_type TEXT CHECK (slot_type IN ('weapon','helmet','chest','gloves','boots','ring','amulet',NULL)),
    base_stats JSONB NOT NULL DEFAULT '{}',
    description TEXT NOT NULL DEFAULT '',
    stackable BOOLEAN NOT NULL DEFAULT false,
    max_stack INTEGER NOT NULL DEFAULT 1,
    value_zorium NUMERIC(10,2) NOT NULL DEFAULT 0,
    icon_id TEXT DEFAULT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- INVENTORY
-- ============================================================
CREATE TABLE IF NOT EXISTS inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES items(id),
    slot_index INTEGER NOT NULL CHECK (slot_index >= 0 AND slot_index < 40),
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(character_id, slot_index)
);
CREATE INDEX IF NOT EXISTS idx_inventory_character ON inventory(character_id);

-- ============================================================
-- EQUIPMENT
-- ============================================================
CREATE TABLE IF NOT EXISTS equipment (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
    slot_type TEXT NOT NULL CHECK (slot_type IN ('weapon','helmet','chest','gloves','boots','ring','amulet')),
    item_id UUID NOT NULL REFERENCES items(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(character_id, slot_type)
);
CREATE INDEX IF NOT EXISTS idx_equipment_character ON equipment(character_id);

-- ============================================================
-- WALLETS
-- ============================================================
CREATE TABLE IF NOT EXISTS wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
    balance NUMERIC(15,2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(character_id)
);

-- ============================================================
-- TRANSACTIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_wallet_id UUID REFERENCES wallets(id),
    to_wallet_id UUID REFERENCES wallets(id),
    amount NUMERIC(15,2) NOT NULL CHECK (amount > 0),
    tx_type TEXT NOT NULL CHECK (tx_type IN ('loot','quest_reward','purchase','sale','trade','admin_grant','stripe_purchase')),
    description TEXT DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_transactions_from ON transactions(from_wallet_id);
CREATE INDEX IF NOT EXISTS idx_transactions_to ON transactions(to_wallet_id);

-- ============================================================
-- NPC PROFILES
-- ============================================================
CREATE TABLE IF NOT EXISTS npc_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id UUID NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'villager',
    personality JSONB NOT NULL DEFAULT '{}',
    knowledge JSONB NOT NULL DEFAULT '{}',
    ai_provider TEXT DEFAULT NULL,
    ai_config JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(entity_id)
);

-- ============================================================
-- NPC MEMORY
-- ============================================================
CREATE TABLE IF NOT EXISTS npc_memory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    npc_entity_id UUID NOT NULL REFERENCES entities(id) ON DELETE CASCADE,
    character_id UUID REFERENCES characters(id) ON DELETE SET NULL,
    memory_type TEXT NOT NULL CHECK (memory_type IN ('interaction','observation','rumor','quest','trade','combat')),
    content JSONB NOT NULL DEFAULT '{}',
    importance INTEGER NOT NULL DEFAULT 5 CHECK (importance >= 1 AND importance <= 10),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_npc_memory_npc ON npc_memory(npc_entity_id);
CREATE INDEX IF NOT EXISTS idx_npc_memory_char ON npc_memory(character_id);

-- ============================================================
-- QUEST DATA (definitions)
-- ============================================================
CREATE TABLE IF NOT EXISTS quest_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    quest_type TEXT NOT NULL DEFAULT 'main' CHECK (quest_type IN ('main','side','daily','event')),
    min_level INTEGER NOT NULL DEFAULT 1,
    requirements JSONB NOT NULL DEFAULT '{}',
    rewards JSONB NOT NULL DEFAULT '{}',
    chain_next_id UUID REFERENCES quest_data(id) DEFAULT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- QUEST PROGRESS
-- ============================================================
CREATE TABLE IF NOT EXISTS quest_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
    quest_id UUID NOT NULL REFERENCES quest_data(id),
    state TEXT NOT NULL DEFAULT 'available' CHECK (state IN ('available','active','completed','failed','turned_in')),
    progress JSONB NOT NULL DEFAULT '{}',
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(character_id, quest_id)
);
CREATE INDEX IF NOT EXISTS idx_quest_progress_char ON quest_progress(character_id);

-- ============================================================
-- SAVE STATES
-- ============================================================
CREATE TABLE IF NOT EXISTS save_states (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID NOT NULL REFERENCES characters(id) ON DELETE CASCADE,
    position JSONB NOT NULL DEFAULT '{"x":0,"y":3,"z":0}',
    stats_snapshot JSONB NOT NULL DEFAULT '{}',
    inventory_snapshot JSONB NOT NULL DEFAULT '[]',
    equipment_snapshot JSONB NOT NULL DEFAULT '{}',
    quest_snapshot JSONB NOT NULL DEFAULT '[]',
    saved_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_save_states_char ON save_states(character_id);

-- ============================================================
-- SEED: BASE ITEMS
-- ============================================================
INSERT INTO items (id, name, item_type, rarity, slot_type, base_stats, description, stackable, max_stack, value_zorium) VALUES
('c0000000-0000-0000-0000-000000000001', 'Espada de Madeira', 'weapon', 'common', 'weapon', '{"attack":3,"speed":1.0}', 'Uma espada simples feita de madeira resistente.', false, 1, 5),
('c0000000-0000-0000-0000-000000000002', 'Armadura de Couro', 'armor', 'common', 'chest', '{"defense":2,"hp":10}', 'Protecao basica de couro curtido.', false, 1, 8),
('c0000000-0000-0000-0000-000000000003', 'Pocao de Vida', 'consumable', 'common', NULL, '{"heal_hp":30}', 'Restaura 30 pontos de vida.', true, 10, 3),
('c0000000-0000-0000-0000-000000000004', 'Anel de Sorte', 'accessory', 'uncommon', 'ring', '{"luck":2,"critical":0.05}', 'Um anel que traz sorte ao portador.', false, 1, 25),
('c0000000-0000-0000-0000-000000000005', 'Amuleto Simples', 'accessory', 'common', 'amulet', '{"mana":10,"intelligence":1}', 'Um amuleto com leve aura magica.', false, 1, 12),
('c0000000-0000-0000-0000-000000000006', 'Elmo de Ferro', 'armor', 'uncommon', 'helmet', '{"defense":3,"vitality":1}', 'Elmo resistente de ferro forjado.', false, 1, 20),
('c0000000-0000-0000-0000-000000000007', 'Luvas de Combate', 'armor', 'common', 'gloves', '{"defense":1,"strength":1}', 'Luvas de couro reforçado.', false, 1, 10),
('c0000000-0000-0000-0000-000000000008', 'Botas de Viajante', 'armor', 'common', 'boots', '{"defense":1,"speed":0.5}', 'Botas confortaveis para longas jornadas.', false, 1, 10),
('c0000000-0000-0000-0000-000000000009', 'Espada de Ferro', 'weapon', 'uncommon', 'weapon', '{"attack":8,"speed":0.9,"critical":0.03}', 'Espada forjada em ferro resistente.', false, 1, 30),
('c0000000-0000-0000-0000-000000000010', 'Cristal de Vorak', 'quest_item', 'epic', NULL, '{}', 'Um cristal escuro pulsando com a energia de Vorak.', false, 1, 0)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- SEED: QUEST - DERROTE VORAK
-- ============================================================
INSERT INTO quest_data (id, name, description, quest_type, min_level, requirements, rewards) VALUES
('d0000000-0000-0000-0000-000000000001', 'Derrote Vorak, o Antigo', 'O dragao Vorak ameaca o Vale Cinzento. Derrote-o para salvar a regiao.', 'main', 1, '{"kill":{"entity_type":"dragon","entity_name":"Vorak"}}', '{"xp":500,"zorium":100,"items":["c0000000-0000-0000-0000-000000000010"]}')
ON CONFLICT (id) DO NOTHING;
