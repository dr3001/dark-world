-- Dark World — Migration 012: Combat VFX Foundation

CREATE TABLE IF NOT EXISTS combat_vfx_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id) ON DELETE CASCADE,
    brutality_level TEXT NOT NULL DEFAULT 'dark' CHECK (brutality_level IN ('clean','dark','brutal')),
    particle_quality TEXT NOT NULL DEFAULT 'medium' CHECK (particle_quality IN ('low','medium','high')),
    camera_shake_enabled BOOLEAN NOT NULL DEFAULT true,
    blood_decals_enabled BOOLEAN NOT NULL DEFAULT true,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id)
);

CREATE TABLE IF NOT EXISTS combat_visual_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type TEXT NOT NULL,
    attacker_id UUID,
    target_id UUID,
    position JSONB NOT NULL DEFAULT '{}',
    server_tick INTEGER NOT NULL DEFAULT 0,
    synced BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_cvl_event ON combat_visual_logs(event_type);

CREATE TABLE IF NOT EXISTS combat_effect_presets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    blood_level TEXT NOT NULL DEFAULT 'medium' CHECK (blood_level IN ('none','low','medium','high','brutal')),
    particle_count INTEGER NOT NULL DEFAULT 10,
    shake_intensity NUMERIC(3,2) NOT NULL DEFAULT 0.5,
    decal_max INTEGER NOT NULL DEFAULT 15,
    audio_enabled BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS training_ground_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES accounts_profile(id),
    character_id UUID REFERENCES characters(id),
    effects_tested JSONB NOT NULL DEFAULT '[]',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO combat_effect_presets (id, name, blood_level, particle_count, shake_intensity) VALUES
('e1000000-0000-0000-0000-000000000001', 'clean', 'none', 5, 0.1),
('e1000000-0000-0000-0000-000000000002', 'dark', 'medium', 10, 0.5),
('e1000000-0000-0000-0000-000000000003', 'brutal', 'brutal', 20, 0.8)
ON CONFLICT (id) DO NOTHING;
