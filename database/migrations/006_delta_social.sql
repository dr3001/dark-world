-- Dark World — Migration 006: Delta Social & Multiplayer
-- 12 new tables + 2 ALTER + seeds

-- ============================================================
-- ENHANCED ACCOUNTS
-- ============================================================
ALTER TABLE accounts_profile ADD COLUMN IF NOT EXISTS password_hash TEXT;
ALTER TABLE accounts_profile ADD COLUMN IF NOT EXISTS email_verified BOOLEAN NOT NULL DEFAULT false;

CREATE TABLE IF NOT EXISTS email_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '24 hours',
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS password_resets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '1 hour',
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- ROLES & PERMISSIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    priority INTEGER NOT NULL DEFAULT 0,
    permissions JSONB NOT NULL DEFAULT '[]'
);

CREATE TABLE IF NOT EXISTS role_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission TEXT NOT NULL,
    UNIQUE(role_id, permission)
);

-- ============================================================
-- FRIENDS
-- ============================================================
CREATE TABLE IF NOT EXISTS friends (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES accounts_profile(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','blocked')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, friend_id)
);
CREATE INDEX IF NOT EXISTS idx_friends_user ON friends(user_id);

CREATE TABLE IF NOT EXISTS friend_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_user_id UUID NOT NULL REFERENCES accounts_profile(id) ON DELETE CASCADE,
    to_user_id UUID NOT NULL REFERENCES accounts_profile(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','declined','cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(from_user_id, to_user_id)
);

-- ============================================================
-- ENHANCED CLANS
-- ============================================================
CREATE TABLE IF NOT EXISTS clan_ranks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clan_id UUID NOT NULL REFERENCES clans(id) ON DELETE CASCADE,
    rank_name TEXT NOT NULL,
    permissions JSONB NOT NULL DEFAULT '[]',
    priority INTEGER NOT NULL DEFAULT 0,
    UNIQUE(clan_id, rank_name)
);

CREATE TABLE IF NOT EXISTS clan_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clan_id UUID NOT NULL REFERENCES clans(id) ON DELETE CASCADE,
    user_id UUID REFERENCES accounts_profile(id),
    action TEXT NOT NULL,
    details JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_clan_logs_clan ON clan_logs(clan_id);

-- ============================================================
-- CHAT MODERATION
-- ============================================================
CREATE TABLE IF NOT EXISTS chat_moderation_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_type TEXT NOT NULL CHECK (rule_type IN ('word','link','domain','regex')),
    pattern TEXT NOT NULL,
    action TEXT NOT NULL DEFAULT 'block' CHECK (action IN ('block','flag','warn')),
    created_by TEXT DEFAULT 'system',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- MULTIPLAYER POSITIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS player_positions (
    character_id UUID PRIMARY KEY REFERENCES characters(id) ON DELETE CASCADE,
    user_id UUID REFERENCES accounts_profile(id),
    world_id UUID REFERENCES worlds(id),
    x NUMERIC(10,2) NOT NULL DEFAULT 0,
    y NUMERIC(10,2) NOT NULL DEFAULT 3,
    z NUMERIC(10,2) NOT NULL DEFAULT 0,
    display_name TEXT NOT NULL DEFAULT '',
    vip_level INTEGER NOT NULL DEFAULT 0,
    role TEXT NOT NULL DEFAULT 'player',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS online_sessions (
    character_id UUID PRIMARY KEY REFERENCES characters(id) ON DELETE CASCADE,
    user_id UUID REFERENCES accounts_profile(id),
    last_heartbeat TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_online BOOLEAN NOT NULL DEFAULT true
);

-- ============================================================
-- SECURITY
-- ============================================================
CREATE TABLE IF NOT EXISTS security_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES accounts_profile(id),
    action TEXT NOT NULL,
    ip TEXT,
    risk_level TEXT NOT NULL DEFAULT 'low' CHECK (risk_level IN ('low','medium','high','critical')),
    metadata JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_security_user ON security_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_security_risk ON security_logs(risk_level);

-- ============================================================
-- EXTEND CHAT CHANNELS
-- ============================================================
ALTER TABLE chat_messages DROP CONSTRAINT IF EXISTS chat_messages_channel_check;
ALTER TABLE chat_messages ADD CONSTRAINT chat_messages_channel_check
    CHECK (channel IN ('global','local','clan','system','staff','ch1','ch2','ch3','ch4','ch5','ch6','ch7','ch8','ch9','ch10'));

-- ============================================================
-- SEEDS
-- ============================================================
INSERT INTO roles (id, name, priority, permissions) VALUES
('r0000000-0000-0000-0000-000000000001', 'player', 1, '["chat","play","trade"]'),
('r0000000-0000-0000-0000-000000000002', 'vip', 2, '["chat","play","trade","vip_features"]'),
('r0000000-0000-0000-0000-000000000003', 'moderator', 3, '["chat","play","trade","mute","kick","chat_moderate"]'),
('r0000000-0000-0000-0000-000000000004', 'gm', 4, '["chat","play","trade","mute","kick","chat_moderate","spawn_items","teleport"]'),
('r0000000-0000-0000-0000-000000000005', 'admin', 5, '["chat","play","trade","mute","kick","chat_moderate","spawn_items","teleport","ban","grant_zorium","manage_events"]'),
('r0000000-0000-0000-0000-000000000006', 'owner', 6, '["all"]')
ON CONFLICT (id) DO NOTHING;

INSERT INTO chat_moderation_rules (rule_type, pattern, action, created_by) VALUES
('word', 'hack', 'flag', 'system'),
('word', 'cheat', 'flag', 'system'),
('domain', 'bit.ly', 'block', 'system')
ON CONFLICT DO NOTHING;

-- Staff clan
INSERT INTO clans (id, name, tag, description, leader_user_id) 
SELECT 'cl000000-0000-0000-0000-000000000001', 'STAFF', 'STF', 'Equipe oficial do Dark World', id
FROM accounts_profile WHERE role = 'owner' OR is_admin = true LIMIT 1
ON CONFLICT DO NOTHING;
