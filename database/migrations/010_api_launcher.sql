-- Dark World — Migration 010: Public API + Launcher Foundation
-- API keys, clients, rate limits, usage logs + launcher manifests

CREATE TABLE IF NOT EXISTS public_api_clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    owner_user_id UUID REFERENCES accounts_profile(id),
    client_secret_hash TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','revoked','suspended')),
    allowed_origins TEXT[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public_api_scopes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES public_api_clients(id) ON DELETE CASCADE,
    scope TEXT NOT NULL CHECK (scope IN ('read:profile','read:world','read:ranking','read:events','read:clans','read:chat','read:lore','write:chat','webhook:subscribe')),
    UNIQUE(client_id, scope)
);

CREATE TABLE IF NOT EXISTS public_api_usage_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID REFERENCES public_api_clients(id),
    endpoint TEXT NOT NULL,
    response_code INTEGER NOT NULL DEFAULT 200,
    request_ip TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_api_usage_client ON public_api_usage_logs(client_id);
CREATE INDEX IF NOT EXISTS idx_api_usage_time ON public_api_usage_logs(created_at);

CREATE TABLE IF NOT EXISTS public_api_rate_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES public_api_clients(id) ON DELETE CASCADE,
    scope TEXT NOT NULL DEFAULT 'default',
    max_requests INTEGER NOT NULL DEFAULT 60,
    window_seconds INTEGER NOT NULL DEFAULT 60,
    UNIQUE(client_id, scope)
);

CREATE TABLE IF NOT EXISTS launcher_manifests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_version TEXT NOT NULL,
    launcher_version TEXT NOT NULL DEFAULT '0.1.0',
    platform TEXT NOT NULL CHECK (platform IN ('windows','macos','linux')),
    channel TEXT NOT NULL DEFAULT 'stable' CHECK (channel IN ('stable','beta','staff','dev')),
    manifest_json JSONB NOT NULL DEFAULT '{}',
    published_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS launcher_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES accounts_profile(id),
    character_id UUID REFERENCES characters(id),
    platform TEXT,
    action TEXT NOT NULL CHECK (action IN ('start','login','update_check','download_start','download_complete','hash_failed','repair','game_launch','game_exit','crash','rollback')),
    details JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed: API client for internal use
INSERT INTO public_api_clients (id, name, client_secret_hash, allowed_origins) VALUES
('b1000000-0000-0000-0000-000000000001', 'Dark World Internal', 'INTERNAL_NO_AUTH', '{"*"}')
ON CONFLICT (id) DO NOTHING;
