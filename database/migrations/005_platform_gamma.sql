-- Dark World — Migration 005: Platform Foundation Gamma
-- 33 new tables + 2 ALTER + seed data

-- ============================================================
-- PHASE 2: ENHANCED ACCOUNTS
-- ============================================================
ALTER TABLE accounts_profile ADD COLUMN IF NOT EXISTS username TEXT UNIQUE;
ALTER TABLE accounts_profile ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','suspended','banned','deleted'));
ALTER TABLE accounts_profile ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'player' CHECK (role IN ('player','premium','vip','staff','moderator','admin','owner'));
ALTER TABLE accounts_profile ADD COLUMN IF NOT EXISTS premium_status TEXT NOT NULL DEFAULT 'free' CHECK (premium_status IN ('free','premium','vip'));
ALTER TABLE accounts_profile ADD COLUMN IF NOT EXISTS vip_level INTEGER NOT NULL DEFAULT 0;
ALTER TABLE accounts_profile ADD COLUMN IF NOT EXISTS is_staff BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE accounts_profile ADD COLUMN IF NOT EXISTS is_banned BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE accounts_profile ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS auth_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    ip TEXT,
    device TEXT,
    platform TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '30 days',
    is_active BOOLEAN NOT NULL DEFAULT true
);
CREATE INDEX IF NOT EXISTS idx_auth_sessions_user ON auth_sessions(user_id);

-- ============================================================
-- PHASE 3: LOGIN TRACKING
-- ============================================================
CREATE TABLE IF NOT EXISTS login_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id) ON DELETE CASCADE,
    ip TEXT,
    device TEXT,
    platform TEXT,
    success BOOLEAN NOT NULL DEFAULT true,
    failure_reason TEXT,
    session_id UUID REFERENCES auth_sessions(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_login_history_user ON login_history(user_id);
CREATE INDEX IF NOT EXISTS idx_login_history_date ON login_history(created_at);

-- ============================================================
-- PHASE 4: ZORIUM LEDGER
-- ============================================================
CREATE TABLE IF NOT EXISTS zorium_ledger (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES accounts_profile(id),
    character_id UUID REFERENCES characters(id),
    amount NUMERIC(15,2) NOT NULL,
    tx_type TEXT NOT NULL CHECK (tx_type IN ('admin_grant','purchase_pending','purchase_confirmed','shop_purchase','quest_reward','event_reward','refund','adjustment','heal','forge','trade','loot')),
    source TEXT NOT NULL DEFAULT 'system',
    reason TEXT DEFAULT '',
    created_by TEXT DEFAULT 'system',
    metadata JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_zorium_ledger_user ON zorium_ledger(user_id);
CREATE INDEX IF NOT EXISTS idx_zorium_ledger_char ON zorium_ledger(character_id);
CREATE INDEX IF NOT EXISTS idx_zorium_ledger_type ON zorium_ledger(tx_type);

-- ============================================================
-- PHASE 5: VIP SYSTEM
-- ============================================================
CREATE TABLE IF NOT EXISTS vip_levels (
    level INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    badge TEXT NOT NULL DEFAULT '',
    color TEXT NOT NULL DEFAULT '#FFFFFF',
    benefits JSONB NOT NULL DEFAULT '{}',
    priority INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS user_vip (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id) ON DELETE CASCADE,
    vip_level INTEGER NOT NULL REFERENCES vip_levels(level),
    starts_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','expired','cancelled')),
    granted_by TEXT DEFAULT 'system',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_user_vip_user ON user_vip(user_id);

-- ============================================================
-- PHASE 6: POWER RUSH
-- ============================================================
CREATE TABLE IF NOT EXISTS power_rush_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    effect_type TEXT NOT NULL CHECK (effect_type IN ('speed','energy','glow','bubble','icon')),
    duration_seconds INTEGER NOT NULL DEFAULT 3600,
    cost_zorium NUMERIC(10,2) NOT NULL DEFAULT 10,
    effects JSONB NOT NULL DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS user_power_rush (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id),
    character_id UUID REFERENCES characters(id),
    power_rush_id UUID NOT NULL REFERENCES power_rush_items(id),
    activated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_user_pr_user ON user_power_rush(user_id);

-- ============================================================
-- PHASE 7: STORE
-- ============================================================
CREATE TABLE IF NOT EXISTS store_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS store_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES store_categories(id),
    name TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    price_cents INTEGER NOT NULL DEFAULT 0,
    price_zorium NUMERIC(10,2) NOT NULL DEFAULT 0,
    product_type TEXT NOT NULL CHECK (product_type IN ('zorium_pack','vip','power_rush','cosmetic','event_item','rare_item','bundle')),
    metadata JSONB NOT NULL DEFAULT '{}',
    is_active BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS store_purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id),
    product_id UUID NOT NULL REFERENCES store_products(id),
    amount_paid INTEGER NOT NULL DEFAULT 0,
    currency TEXT NOT NULL DEFAULT 'BRL',
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','confirmed','failed','refunded')),
    payment_method TEXT DEFAULT 'stripe',
    delivered BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_store_purchases_user ON store_purchases(user_id);

CREATE TABLE IF NOT EXISTS store_deliveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    purchase_id UUID NOT NULL REFERENCES store_purchases(id),
    item_id UUID REFERENCES items(id),
    character_id UUID REFERENCES characters(id),
    quantity INTEGER NOT NULL DEFAULT 1,
    zorium_amount NUMERIC(10,2) DEFAULT 0,
    delivered_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- PHASE 8: STRIPE FOUNDATION
-- ============================================================
CREATE TABLE IF NOT EXISTS stripe_customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id) ON DELETE CASCADE,
    stripe_customer_id TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payment_intents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id),
    stripe_intent_id TEXT UNIQUE,
    amount_cents INTEGER NOT NULL,
    currency TEXT NOT NULL DEFAULT 'BRL',
    status TEXT NOT NULL DEFAULT 'created' CHECK (status IN ('created','processing','succeeded','failed','cancelled')),
    product_id UUID REFERENCES store_products(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS webhook_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type TEXT NOT NULL,
    stripe_event_id TEXT UNIQUE,
    payload JSONB NOT NULL DEFAULT '{}',
    processed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- PHASE 10: CHAT
-- ============================================================
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES accounts_profile(id),
    character_id UUID REFERENCES characters(id),
    display_name TEXT NOT NULL DEFAULT '',
    vip_level INTEGER NOT NULL DEFAULT 0,
    role TEXT NOT NULL DEFAULT 'player',
    message TEXT NOT NULL,
    channel TEXT NOT NULL DEFAULT 'global' CHECK (channel IN ('global','local','clan','system','staff')),
    moderation_status TEXT NOT NULL DEFAULT 'ok' CHECK (moderation_status IN ('ok','flagged','deleted')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_chat_channel ON chat_messages(channel, created_at);

-- ============================================================
-- PHASE 12: CLANS
-- ============================================================
CREATE TABLE IF NOT EXISTS clans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    tag TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL DEFAULT '',
    leader_user_id UUID NOT NULL REFERENCES accounts_profile(id),
    member_count INTEGER NOT NULL DEFAULT 1,
    level INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS clan_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clan_id UUID NOT NULL REFERENCES clans(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES accounts_profile(id),
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('leader','officer','member')),
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(clan_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_clan_members_user ON clan_members(user_id);

CREATE TABLE IF NOT EXISTS clan_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clan_id UUID NOT NULL REFERENCES clans(id) ON DELETE CASCADE,
    from_user_id UUID NOT NULL REFERENCES accounts_profile(id),
    to_user_id UUID NOT NULL REFERENCES accounts_profile(id),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','declined','expired')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '7 days'
);

-- ============================================================
-- PHASE 13: PLAYER PROFILES & TITLES
-- ============================================================
CREATE TABLE IF NOT EXISTS player_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id) ON DELETE CASCADE,
    character_id UUID REFERENCES characters(id),
    title TEXT NOT NULL DEFAULT 'Aventureiro',
    bio TEXT NOT NULL DEFAULT '',
    total_playtime INTEGER NOT NULL DEFAULT 0,
    achievements_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id)
);

CREATE TABLE IF NOT EXISTS player_titles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL DEFAULT '',
    requirement TEXT NOT NULL DEFAULT '',
    rarity TEXT NOT NULL DEFAULT 'common'
);

-- ============================================================
-- PHASE 14-15: RANKINGS & SCORES
-- ============================================================
CREATE TABLE IF NOT EXISTS ranking_seasons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'upcoming' CHECK (status IN ('upcoming','active','ended')),
    rewards JSONB NOT NULL DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS ranking_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id),
    character_id UUID REFERENCES characters(id),
    ranking_type TEXT NOT NULL CHECK (ranking_type IN ('xp','level','zorium','quests','playtime','events','clan','season')),
    score NUMERIC(15,2) NOT NULL DEFAULT 0,
    rank_position INTEGER,
    season_id UUID REFERENCES ranking_seasons(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_ranking_type ON ranking_entries(ranking_type, score DESC);

CREATE TABLE IF NOT EXISTS ranking_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ranking_type TEXT NOT NULL,
    snapshot_date DATE NOT NULL DEFAULT CURRENT_DATE,
    data JSONB NOT NULL DEFAULT '[]',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS score_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id),
    character_id UUID REFERENCES characters(id),
    score_type TEXT NOT NULL CHECK (score_type IN ('quest','event','combat','exploration','participation','clan')),
    amount INTEGER NOT NULL DEFAULT 0,
    source TEXT NOT NULL DEFAULT 'system',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_score_user ON score_entries(user_id);

-- ============================================================
-- PHASE 16-17: EVENTS & CALENDAR
-- ============================================================
CREATE TABLE IF NOT EXISTS game_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    event_type TEXT NOT NULL CHECK (event_type IN ('seasonal','invasion','festival','anniversary','special')),
    description TEXT NOT NULL DEFAULT '',
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled','active','ended','cancelled')),
    rewards JSONB NOT NULL DEFAULT '{}',
    config JSONB NOT NULL DEFAULT '{}',
    ranking_enabled BOOLEAN NOT NULL DEFAULT false,
    shop_items_enabled BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS event_rewards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES game_events(id) ON DELETE CASCADE,
    item_id UUID REFERENCES items(id),
    zorium_amount NUMERIC(10,2) DEFAULT 0,
    xp_amount INTEGER DEFAULT 0,
    min_rank INTEGER DEFAULT 0,
    max_rank INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS event_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES game_events(id) ON DELETE CASCADE,
    item_id UUID NOT NULL REFERENCES items(id),
    is_exclusive BOOLEAN NOT NULL DEFAULT true,
    available_in_shop BOOLEAN NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS scheduled_maintenance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled','active','completed','cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS server_announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    priority INTEGER NOT NULL DEFAULT 5,
    starts_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '24 hours',
    created_by TEXT DEFAULT 'system',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- PHASE 19: MODERATION
-- ============================================================
CREATE TABLE IF NOT EXISTS ban_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id),
    staff_id UUID REFERENCES accounts_profile(id),
    ban_type TEXT NOT NULL CHECK (ban_type IN ('chat_mute','temp_ban','perm_ban','account_suspension')),
    reason TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT true
);
CREATE INDEX IF NOT EXISTS idx_ban_user ON ban_records(user_id);

CREATE TABLE IF NOT EXISTS mute_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id),
    staff_id UUID REFERENCES accounts_profile(id),
    reason TEXT NOT NULL DEFAULT '',
    channel TEXT DEFAULT 'global',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS moderation_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_id UUID REFERENCES accounts_profile(id),
    target_user_id UUID REFERENCES accounts_profile(id),
    action TEXT NOT NULL,
    reason TEXT NOT NULL DEFAULT '',
    metadata JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_mod_logs_target ON moderation_logs(target_user_id);

-- ============================================================
-- PHASE 20: NPC CONVERSATION CONTEXTS
-- ============================================================
CREATE TABLE IF NOT EXISTS npc_conversation_contexts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    npc_entity_id TEXT NOT NULL,
    character_id UUID REFERENCES characters(id),
    context JSONB NOT NULL DEFAULT '{}',
    last_interaction TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_npc_ctx_npc ON npc_conversation_contexts(npc_entity_id);

-- ============================================================
-- PHASE 22: ITEM ENHANCEMENTS
-- ============================================================
ALTER TABLE items ADD COLUMN IF NOT EXISTS is_premium BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE items ADD COLUMN IF NOT EXISTS is_event BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE items ADD COLUMN IF NOT EXISTS is_bound BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE items ADD COLUMN IF NOT EXISTS is_tradeable BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE items ADD COLUMN IF NOT EXISTS event_id UUID;

-- ============================================================
-- PHASE 23: WEAPON UPGRADES
-- ============================================================
CREATE TABLE IF NOT EXISTS weapon_upgrades (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_id UUID NOT NULL REFERENCES items(id),
    character_id UUID NOT NULL REFERENCES characters(id),
    weapon_level INTEGER NOT NULL DEFAULT 1,
    upgrade_level INTEGER NOT NULL DEFAULT 0,
    durability INTEGER NOT NULL DEFAULT 100,
    bonus_damage NUMERIC(8,2) NOT NULL DEFAULT 0,
    bonus_critical NUMERIC(5,4) NOT NULL DEFAULT 0,
    upgrade_cost_zorium NUMERIC(10,2) NOT NULL DEFAULT 10,
    upgrade_materials JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(item_id, character_id)
);

-- ============================================================
-- SEEDS
-- ============================================================

-- VIP Levels (1-20)
INSERT INTO vip_levels (level, name, badge, color, benefits, priority) VALUES
(1, 'VIP Bronze I', 'vip1', '#CD7F32', '{"chat_badge":true}', 1),
(2, 'VIP Bronze II', 'vip2', '#CD7F32', '{"chat_badge":true}', 2),
(3, 'VIP Bronze III', 'vip3', '#CD7F32', '{"chat_badge":true,"profile_frame":true}', 3),
(4, 'VIP Prata I', 'vip4', '#C0C0C0', '{"chat_badge":true,"profile_frame":true}', 4),
(5, 'VIP Prata II', 'vip5', '#C0C0C0', '{"chat_badge":true,"profile_frame":true,"xp_bonus":0.05}', 5),
(6, 'VIP Prata III', 'vip6', '#C0C0C0', '{"chat_badge":true,"profile_frame":true,"xp_bonus":0.05}', 6),
(7, 'VIP Ouro I', 'vip7', '#FFD700', '{"chat_badge":true,"profile_frame":true,"xp_bonus":0.10,"glow":true}', 7),
(8, 'VIP Ouro II', 'vip8', '#FFD700', '{"chat_badge":true,"profile_frame":true,"xp_bonus":0.10,"glow":true}', 8),
(9, 'VIP Ouro III', 'vip9', '#FFD700', '{"chat_badge":true,"profile_frame":true,"xp_bonus":0.15,"glow":true}', 9),
(10, 'VIP Platina I', 'vip10', '#E5E4E2', '{"chat_badge":true,"profile_frame":true,"xp_bonus":0.15,"glow":true,"bubble_effect":true}', 10),
(11, 'VIP Platina II', 'vip11', '#E5E4E2', '{"chat_badge":true,"profile_frame":true,"xp_bonus":0.20,"glow":true,"bubble_effect":true}', 11),
(12, 'VIP Platina III', 'vip12', '#E5E4E2', '{"chat_badge":true,"profile_frame":true,"xp_bonus":0.20,"glow":true,"bubble_effect":true}', 12),
(13, 'VIP Diamante I', 'vip13', '#B9F2FF', '{"chat_badge":true,"profile_frame":true,"xp_bonus":0.25,"glow":true,"bubble_effect":true,"title":"Diamante"}', 13),
(14, 'VIP Diamante II', 'vip14', '#B9F2FF', '{"chat_badge":true,"profile_frame":true,"xp_bonus":0.25,"glow":true,"bubble_effect":true,"title":"Diamante"}', 14),
(15, 'VIP Diamante III', 'vip15', '#B9F2FF', '{"chat_badge":true,"profile_frame":true,"xp_bonus":0.30,"glow":true,"bubble_effect":true,"title":"Diamante"}', 15),
(16, 'VIP Mestre I', 'vip16', '#9400D3', '{"chat_badge":true,"profile_frame":true,"xp_bonus":0.30,"glow":true,"bubble_effect":true,"title":"Mestre","priority_queue":true}', 16),
(17, 'VIP Mestre II', 'vip17', '#9400D3', '{"chat_badge":true,"profile_frame":true,"xp_bonus":0.35,"glow":true,"bubble_effect":true,"title":"Mestre","priority_queue":true}', 17),
(18, 'VIP Mestre III', 'vip18', '#9400D3', '{"chat_badge":true,"profile_frame":true,"xp_bonus":0.35,"glow":true,"bubble_effect":true,"title":"Mestre","priority_queue":true}', 18),
(19, 'VIP Lenda I', 'vip19', '#FF4500', '{"chat_badge":true,"profile_frame":true,"xp_bonus":0.40,"glow":true,"bubble_effect":true,"title":"Lenda","priority_queue":true,"exclusive_events":true}', 19),
(20, 'VIP Lenda II', 'vip20', '#FF4500', '{"chat_badge":true,"profile_frame":true,"xp_bonus":0.50,"glow":true,"bubble_effect":true,"title":"Lenda","priority_queue":true,"exclusive_events":true}', 20)
ON CONFLICT (level) DO NOTHING;

-- Store Categories
INSERT INTO store_categories (id, name, slug, sort_order, is_active) VALUES
('e0000000-0000-0000-0000-000000000001', 'Zorium', 'zorium', 1, false),
('e0000000-0000-0000-0000-000000000002', 'VIP', 'vip', 2, false),
('e0000000-0000-0000-0000-000000000003', 'Power Ups', 'power-ups', 3, false),
('e0000000-0000-0000-0000-000000000004', 'Cosmeticos', 'cosmetics', 4, false),
('e0000000-0000-0000-0000-000000000005', 'Itens de Evento', 'event-items', 5, false),
('e0000000-0000-0000-0000-000000000006', 'Itens Raros', 'rare-items', 6, false),
('e0000000-0000-0000-0000-000000000007', 'Pacotes', 'bundles', 7, false)
ON CONFLICT (id) DO NOTHING;

-- Store Products (inactive — preparacao)
INSERT INTO store_products (id, category_id, name, description, price_cents, price_zorium, product_type, is_active) VALUES
('f0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001', 'Pacote Zorium Pequeno', '100 Zorium', 990, 0, 'zorium_pack', false),
('f0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000001', 'Pacote Zorium Medio', '500 Zorium', 3990, 0, 'zorium_pack', false),
('f0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000001', 'Pacote Zorium Grande', '1500 Zorium', 9990, 0, 'zorium_pack', false),
('f0000000-0000-0000-0000-000000000004', 'e0000000-0000-0000-0000-000000000002', 'VIP Mensal', 'VIP Bronze I por 30 dias', 1990, 0, 'vip', false),
('f0000000-0000-0000-0000-000000000005', 'e0000000-0000-0000-0000-000000000003', 'Power Rush', 'Efeitos visuais por 1 hora', 0, 50, 'power_rush', false),
('f0000000-0000-0000-0000-000000000006', 'e0000000-0000-0000-0000-000000000005', 'Item de Evento', 'Item exclusivo do evento ativo', 0, 100, 'event_item', false),
('f0000000-0000-0000-0000-000000000007', 'e0000000-0000-0000-0000-000000000006', 'Item Raro', 'Item raro de colecao', 4990, 0, 'rare_item', false)
ON CONFLICT (id) DO NOTHING;

-- Power Rush Items
INSERT INTO power_rush_items (id, name, effect_type, duration_seconds, cost_zorium, effects) VALUES
('f1000000-0000-0000-0000-000000000001', 'Rush de Velocidade', 'speed', 3600, 30, '{"speed_bonus":0.2}'),
('f1000000-0000-0000-0000-000000000002', 'Rush de Energia', 'energy', 3600, 30, '{"mana_regen":0.5}'),
('f1000000-0000-0000-0000-000000000003', 'Rush Brilhante', 'glow', 3600, 50, '{"glow_color":"#FFD700","bubble_glow":true}')
ON CONFLICT (id) DO NOTHING;

-- Player Titles
INSERT INTO player_titles (id, name, description, requirement, rarity) VALUES
('f2000000-0000-0000-0000-000000000001', 'Aventureiro', 'Titulo inicial de todo heroi', 'default', 'common'),
('f2000000-0000-0000-0000-000000000002', 'Guardiao do Vale', 'Protetor do Vale Cinzento', 'quest_vorak_complete', 'uncommon'),
('f2000000-0000-0000-0000-000000000003', 'Cacador de Vorak', 'Derrotou o dragao Vorak', 'kill_vorak', 'rare'),
('f2000000-0000-0000-0000-000000000004', 'Fundador', 'Jogou durante o periodo de fundacao', 'founder_period', 'epic'),
('f2000000-0000-0000-0000-000000000005', 'VIP', 'Membro VIP ativo', 'vip_active', 'uncommon'),
('f2000000-0000-0000-0000-000000000006', 'Staff', 'Membro da equipe', 'staff_role', 'legendary')
ON CONFLICT (id) DO NOTHING;

-- Game Events (placeholder — scheduled for future)
INSERT INTO game_events (id, name, event_type, description, starts_at, ends_at, status) VALUES
('f3000000-0000-0000-0000-000000000001', 'Halloween do Vale', 'seasonal', 'Criaturas sombrias invadem o Vale Cinzento', '2026-10-25 00:00:00+00', '2026-11-02 00:00:00+00', 'scheduled'),
('f3000000-0000-0000-0000-000000000002', 'Natal Cinzento', 'seasonal', 'Neve cobre o Vale e presentes aparecem', '2026-12-20 00:00:00+00', '2027-01-03 00:00:00+00', 'scheduled'),
('f3000000-0000-0000-0000-000000000003', 'Ano Novo', 'festival', 'Fogos de artificio e recompensas especiais', '2026-12-31 00:00:00+00', '2027-01-02 00:00:00+00', 'scheduled'),
('f3000000-0000-0000-0000-000000000004', 'Festival do Vale', 'festival', 'Celebracao anual do Vale Cinzento', '2027-06-01 00:00:00+00', '2027-06-15 00:00:00+00', 'scheduled'),
('f3000000-0000-0000-0000-000000000005', 'Invasao de Vorak', 'invasion', 'Vorak retorna com forca total', '2027-03-01 00:00:00+00', '2027-03-15 00:00:00+00', 'scheduled'),
('f3000000-0000-0000-0000-000000000006', 'Aniversario do Servidor', 'anniversary', 'Primeiro aniversario do Dark World', '2027-06-11 00:00:00+00', '2027-06-18 00:00:00+00', 'scheduled'),
('f3000000-0000-0000-0000-000000000007', 'Pascoa Sombria', 'seasonal', 'Ovos magicos escondidos pelo mundo', '2027-04-10 00:00:00+00', '2027-04-20 00:00:00+00', 'scheduled')
ON CONFLICT (id) DO NOTHING;
