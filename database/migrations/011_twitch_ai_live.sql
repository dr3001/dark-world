-- Dark World — Migration 011: Twitch + AI Coaching + Live Windows

-- ============================================================
-- TWITCH INTEGRATION
-- ============================================================
CREATE TABLE IF NOT EXISTS twitch_account_links (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id) ON DELETE CASCADE,
    twitch_user_id TEXT NOT NULL,
    twitch_login TEXT NOT NULL,
    twitch_display_name TEXT NOT NULL,
    access_token_encrypted TEXT NOT NULL,
    refresh_token_encrypted TEXT,
    scopes TEXT[] NOT NULL DEFAULT '{}',
    expires_at TIMESTAMPTZ,
    linked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'active',
    UNIQUE(user_id)
);

CREATE TABLE IF NOT EXISTS twitch_eventsub_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id),
    subscription_id TEXT NOT NULL UNIQUE,
    event_type TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS twitch_eventsub_deliveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id TEXT,
    event_type TEXT NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}',
    received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed BOOLEAN NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS streamer_overlays (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id),
    overlay_token TEXT NOT NULL UNIQUE,
    scene_type TEXT NOT NULL DEFAULT 'player_profile',
    config JSONB NOT NULL DEFAULT '{}',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS overlay_widgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    overlay_id UUID NOT NULL REFERENCES streamer_overlays(id) ON DELETE CASCADE,
    widget_type TEXT NOT NULL CHECK (widget_type IN ('player_profile','hp_mana','clan','ranking','event','chat_filtered','legends','battle_status','map')),
    config JSONB NOT NULL DEFAULT '{}',
    position_x INTEGER NOT NULL DEFAULT 0,
    position_y INTEGER NOT NULL DEFAULT 0
);

-- ============================================================
-- AI COACHING + TRANSCRIPTION
-- ============================================================
CREATE TABLE IF NOT EXISTS ai_transcription_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id),
    character_id UUID REFERENCES characters(id),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','active','completed','failed')),
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    used_tokens INTEGER NOT NULL DEFAULT 0,
    cost_estimated NUMERIC(10,4) NOT NULL DEFAULT 0,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ai_coaching_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id),
    character_id UUID REFERENCES characters(id),
    coaching_type TEXT NOT NULL CHECK (coaching_type IN ('lore','map','ranking','event','battle','profile')),
    context JSONB NOT NULL DEFAULT '{}',
    messages JSONB NOT NULL DEFAULT '[]',
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS ai_usage_meters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id),
    window_id UUID,
    service TEXT NOT NULL CHECK (service IN ('transcription','coaching','text_generation')),
    tokens_used INTEGER NOT NULL DEFAULT 0,
    cost_estimated NUMERIC(10,4) NOT NULL DEFAULT 0,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ai_content_safety_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID,
    safety_check TEXT NOT NULL,
    passed BOOLEAN NOT NULL DEFAULT true,
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- LIVE WINDOWS
-- ============================================================
CREATE TABLE IF NOT EXISTS live_windows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id),
    twitch_channel_id TEXT,
    window_type TEXT NOT NULL DEFAULT 'standard' CHECK (window_type IN ('standard','pro','event')),
    status TEXT NOT NULL DEFAULT 'pending_payment' CHECK (status IN ('pending_payment','active','paused','expired','cancelled','suspended')),
    starts_at TIMESTAMPTZ,
    ends_at TIMESTAMPTZ,
    duration_minutes INTEGER NOT NULL DEFAULT 240,
    max_streams INTEGER NOT NULL DEFAULT 50,
    used_streams INTEGER NOT NULL DEFAULT 0,
    max_ai_minutes INTEGER NOT NULL DEFAULT 60,
    used_ai_minutes NUMERIC(5,1) NOT NULL DEFAULT 0,
    max_transcription_minutes INTEGER NOT NULL DEFAULT 30,
    used_transcription_minutes NUMERIC(5,1) NOT NULL DEFAULT 0,
    stripe_payment_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS live_window_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    window_type TEXT NOT NULL,
    duration_minutes INTEGER NOT NULL DEFAULT 240,
    max_streams INTEGER NOT NULL DEFAULT 50,
    price_cents INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS live_billing_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id),
    window_id UUID REFERENCES live_windows(id),
    amount_cents INTEGER NOT NULL DEFAULT 0,
    billing_type TEXT NOT NULL CHECK (billing_type IN ('window_purchase','ai_overage','transcription_overage','stream_overage')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','paid','failed','refunded')),
    stripe_intent_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seeds
INSERT INTO live_window_products (id, name, window_type, duration_minutes, max_streams, price_cents, is_active) VALUES
('c2000000-0000-0000-0000-000000000001', 'Janela Standard 4h', 'standard', 240, 50, 990, false),
('c2000000-0000-0000-0000-000000000002', 'Janela Pro 8h', 'pro', 480, 100, 2490, false),
('c2000000-0000-0000-0000-000000000003', 'Janela Evento', 'event', 720, 500, 9990, false)
ON CONFLICT (id) DO NOTHING;
