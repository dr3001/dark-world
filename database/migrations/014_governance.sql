-- Dark World — Migration 014: Governance (Terms, KYC, Forum, Tickets, Translation)

-- ============================================================
-- TERMS ACCEPTANCE
-- ============================================================
CREATE TABLE IF NOT EXISTS terms_acceptance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id) ON DELETE CASCADE,
    terms_version TEXT NOT NULL DEFAULT '1.0.0',
    privacy_version TEXT NOT NULL DEFAULT '1.0.0',
    accepted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ip TEXT,
    device_id TEXT,
    UNIQUE(user_id, terms_version)
);

-- ============================================================
-- KYC FIELDS on accounts_profile
-- ============================================================
ALTER TABLE accounts_profile ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE accounts_profile ADD COLUMN IF NOT EXISTS birthdate DATE;
ALTER TABLE accounts_profile ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE accounts_profile ADD COLUMN IF NOT EXISTS state TEXT;
ALTER TABLE accounts_profile ADD COLUMN IF NOT EXISTS country TEXT DEFAULT 'BR';
ALTER TABLE accounts_profile ADD COLUMN IF NOT EXISTS cpf_hash TEXT;
ALTER TABLE accounts_profile ADD COLUMN IF NOT EXISTS kyc_status TEXT NOT NULL DEFAULT 'none' CHECK (kyc_status IN ('none','pending','verified','rejected'));

-- ============================================================
-- VIOLATION CATALOG
-- ============================================================
CREATE TABLE IF NOT EXISTS violation_catalog (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    category TEXT NOT NULL,
    severity TEXT NOT NULL DEFAULT 'medium' CHECK (severity IN ('low','medium','high','critical','permanent')),
    default_action TEXT NOT NULL DEFAULT 'warn',
    description TEXT DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- ENHANCED BAN RECORDS
-- ============================================================
ALTER TABLE ban_records ADD COLUMN IF NOT EXISTS violation_type TEXT;
ALTER TABLE ban_records ADD COLUMN IF NOT EXISTS owner_only BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE ban_records ADD COLUMN IF NOT EXISTS evidence_bundle JSONB;

-- ============================================================
-- FORUM
-- ============================================================
CREATE TABLE IF NOT EXISTS forum_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT DEFAULT '',
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_staff_only BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS forum_threads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id UUID NOT NULL REFERENCES forum_categories(id),
    user_id UUID NOT NULL REFERENCES accounts_profile(id),
    title TEXT NOT NULL,
    is_pinned BOOLEAN NOT NULL DEFAULT false,
    is_locked BOOLEAN NOT NULL DEFAULT false,
    view_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_forum_threads_cat ON forum_threads(category_id);

CREATE TABLE IF NOT EXISTS forum_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID NOT NULL REFERENCES forum_threads(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES accounts_profile(id),
    content TEXT NOT NULL,
    edited_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_forum_posts_thread ON forum_posts(thread_id);

-- ============================================================
-- TICKETS
-- ============================================================
CREATE TABLE IF NOT EXISTS tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES accounts_profile(id),
    category TEXT NOT NULL CHECK (category IN ('account','login','payment','ban','bug','report','clan','zorium','vip','power_rush','other')),
    priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low','medium','high','urgent')),
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open','waiting_player','waiting_staff','under_review','escalated_to_owner','resolved','closed')),
    assigned_to UUID REFERENCES accounts_profile(id),
    title TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_tickets_user ON tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_tickets_status ON tickets(status);

CREATE TABLE IF NOT EXISTS ticket_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES accounts_profile(id),
    content TEXT NOT NULL,
    is_staff_reply BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_ticket_msgs ON ticket_messages(ticket_id);

-- ============================================================
-- CHAT TRANSLATION
-- ============================================================
CREATE TABLE IF NOT EXISTS chat_translations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id UUID REFERENCES chat_messages(id),
    original_language TEXT NOT NULL DEFAULT 'auto',
    target_language TEXT NOT NULL DEFAULT 'pt',
    original_text TEXT NOT NULL,
    translated_text TEXT NOT NULL,
    provider TEXT NOT NULL DEFAULT 'deepseek',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- SEEDS: Violations + Forum Categories
-- ============================================================
INSERT INTO violation_catalog (id, name, category, severity, default_action, description) VALUES
('v1000000-0000-0000-0000-000000000001', 'cheat_software', 'security', 'permanent', 'perm_ban', 'Uso de software de trapaça'),
('v1000000-0000-0000-0000-000000000002', 'speed_hack', 'security', 'critical', 'temp_ban', 'Alteração ilegal de velocidade'),
('v1000000-0000-0000-0000-000000000003', 'economy_exploit', 'economy', 'critical', 'economy_ban', 'Exploração de falha econômica'),
('v1000000-0000-0000-0000-000000000004', 'duplicate_item', 'economy', 'high', 'temp_ban', 'Duplicação de itens'),
('v1000000-0000-0000-0000-000000000005', 'racism', 'behavior', 'permanent', 'perm_ban', 'Discurso racista'),
('v1000000-0000-0000-0000-000000000006', 'harassment', 'behavior', 'high', 'temp_ban', 'Assédio a outros jogadores'),
('v1000000-0000-0000-0000-000000000007', 'spam', 'chat', 'low', 'chat_mute', 'Spam no chat'),
('v1000000-0000-0000-0000-000000000008', 'phishing', 'security', 'permanent', 'perm_ban', 'Tentativa de phishing'),
('v1000000-0000-0000-0000-000000000009', 'bot_usage', 'security', 'critical', 'temp_ban', 'Uso de bot/automação'),
('v1000000-0000-0000-0000-000000000010', 'multi_account_abuse', 'account', 'high', 'temp_ban', 'Múltiplas contas abusivas')
ON CONFLICT (id) DO NOTHING;

INSERT INTO forum_categories (id, name, description, sort_order) VALUES
('fc000000-0000-0000-0000-000000000001', 'Anuncios', 'Anúncios oficiais do Dark World', 1),
('fc000000-0000-0000-0000-000000000002', 'Suporte', 'Dúvidas e ajuda', 2),
('fc000000-0000-0000-0000-000000000003', 'Bugs', 'Relatos de bugs', 3),
('fc000000-0000-0000-0000-000000000004', 'Clas', 'Recrutamento e discussão de clãs', 4),
('fc000000-0000-0000-0000-000000000005', 'Comercio', 'Compra e venda entre jogadores', 5),
('fc000000-0000-0000-0000-000000000006', 'Eventos', 'Discussão de eventos', 6),
('fc000000-0000-0000-0000-000000000007', 'Denuncias', 'Denúncias de jogadores', 7),
('fc000000-0000-0000-0000-000000000008', 'Sugestoes', 'Sugestões para o jogo', 8)
ON CONFLICT (id) DO NOTHING;
