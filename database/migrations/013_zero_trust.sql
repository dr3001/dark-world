-- Dark World — Migration 013: Zero Trust Security Foundation
-- Device Fingerprint, Trust Engine, Fraud Engine, Anti-Cheat Foundation

-- ============================================================
-- DEVICE FINGERPRINT
-- ============================================================
CREATE TABLE IF NOT EXISTS device_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES accounts_profile(id),
    installation_id TEXT NOT NULL,
    device_id_hash TEXT NOT NULL,
    os_name TEXT DEFAULT 'unknown',
    cpu_hash TEXT,
    gpu_hash TEXT,
    ram_mb INTEGER DEFAULT 0,
    resolution TEXT DEFAULT 'unknown',
    language TEXT DEFAULT 'pt',
    ip_first TEXT,
    ip_last TEXT,
    country TEXT,
    first_seen TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    trust_score INTEGER NOT NULL DEFAULT 500 CHECK (trust_score >= 0 AND trust_score <= 1000),
    is_blacklisted BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_device_user ON device_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_device_install ON device_profiles(installation_id);

CREATE TABLE IF NOT EXISTS device_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id UUID REFERENCES device_profiles(id) ON DELETE CASCADE,
    user_id UUID REFERENCES accounts_profile(id),
    ip TEXT,
    country TEXT,
    action TEXT NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_device_history ON device_history(device_id);

-- ============================================================
-- TRUST ENGINE
-- ============================================================
CREATE TABLE IF NOT EXISTS trust_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id) ON DELETE CASCADE,
    trust_score INTEGER NOT NULL DEFAULT 500 CHECK (trust_score >= 0 AND trust_score <= 1000),
    device_changes INTEGER NOT NULL DEFAULT 0,
    ip_changes INTEGER NOT NULL DEFAULT 0,
    login_failures INTEGER NOT NULL DEFAULT 0,
    spam_flags INTEGER NOT NULL DEFAULT 0,
    fraud_flags INTEGER NOT NULL DEFAULT 0,
    economy_flags INTEGER NOT NULL DEFAULT 0,
    last_calculated TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id)
);

CREATE TABLE IF NOT EXISTS trust_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id),
    event_type TEXT NOT NULL,
    score_delta INTEGER NOT NULL DEFAULT 0,
    old_score INTEGER NOT NULL DEFAULT 500,
    new_score INTEGER NOT NULL DEFAULT 500,
    reason TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_trust_events_user ON trust_events(user_id);

-- ============================================================
-- FRAUD ENGINE
-- ============================================================
CREATE TABLE IF NOT EXISTS fraud_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES accounts_profile(id),
    category TEXT NOT NULL CHECK (category IN ('account','session','device','economy','trade','chat','ranking','guild','store','payment','vip','power_rush','combat','world','network')),
    severity TEXT NOT NULL DEFAULT 'low' CHECK (severity IN ('low','medium','high','critical','blocker')),
    source TEXT NOT NULL DEFAULT 'auto',
    evidence JSONB NOT NULL DEFAULT '{}',
    resolved BOOLEAN NOT NULL DEFAULT false,
    resolved_by UUID REFERENCES accounts_profile(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_fraud_user ON fraud_events(user_id);
CREATE INDEX IF NOT EXISTS idx_fraud_severity ON fraud_events(severity);

CREATE TABLE IF NOT EXISTS fraud_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    category TEXT NOT NULL,
    condition_json JSONB NOT NULL DEFAULT '{}',
    action TEXT NOT NULL DEFAULT 'flag' CHECK (action IN ('flag','warn','suspend','ban')),
    enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- ANTI-CHEAT FOUNDATION
-- ============================================================
CREATE TABLE IF NOT EXISTS anti_cheat_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES accounts_profile(id),
    character_id UUID REFERENCES characters(id),
    cheat_type TEXT NOT NULL CHECK (cheat_type IN ('speed_hack','teleport','cooldown_bypass','inventory_injection','packet_manipulation','economy_manipulation','duplicate_item','ranking_manipulation','chat_automation','macro_abuse','bot_behavior')),
    evidence JSONB NOT NULL DEFAULT '{}',
    confidence INTEGER NOT NULL DEFAULT 50 CHECK (confidence >= 0 AND confidence <= 100),
    auto_action TEXT DEFAULT 'flag',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_ac_user ON anti_cheat_events(user_id);

CREATE TABLE IF NOT EXISTS movement_validations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    character_id UUID NOT NULL REFERENCES characters(id),
    x NUMERIC(10,2) NOT NULL,
    y NUMERIC(10,2) NOT NULL,
    z NUMERIC(10,2) NOT NULL,
    speed NUMERIC(8,2) NOT NULL DEFAULT 0,
    valid BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- SEEDS: Fraud Rules
-- ============================================================
INSERT INTO fraud_rules (id, name, category, condition_json, action) VALUES
('ff000000-0000-0000-0000-000000000001', 'economy_gain_impossible', 'economy', '{"zorium_per_hour":10000,"check_window_hours":1}', 'flag'),
('ff000000-0000-0000-0000-000000000002', 'multi_account_same_ip', 'account', '{"max_accounts_per_ip":5}', 'flag'),
('ff000000-0000-0000-0000-000000000003', 'spam_detected', 'chat', '{"max_messages_per_minute":20}', 'warn'),
('ff000000-0000-0000-0000-000000000004', 'speed_hack', 'world', '{"max_speed":20}', 'flag'),
('ff000000-0000-0000-0000-000000000005', 'teleport_impossible', 'world', '{"max_distance_per_tick":100}', 'flag')
ON CONFLICT (id) DO NOTHING;
