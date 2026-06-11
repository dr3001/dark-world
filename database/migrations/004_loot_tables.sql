-- Dark World — Migration 004: Loot Tables
CREATE TABLE IF NOT EXISTS loot_tables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_type TEXT NOT NULL CHECK (source_type IN ('dragon','monster','chest','quest','event')),
    source_id UUID,
    item_id UUID NOT NULL REFERENCES items(id),
    drop_chance NUMERIC(5,4) NOT NULL DEFAULT 1.0 CHECK (drop_chance > 0 AND drop_chance <= 1),
    min_qty INTEGER NOT NULL DEFAULT 1,
    max_qty INTEGER NOT NULL DEFAULT 1,
    min_level INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_loot_source ON loot_tables(source_type, source_id);

INSERT INTO loot_tables (source_type, source_id, item_id, drop_chance, min_qty, max_qty) VALUES
('dragon', 'b0000000-0000-0000-0000-000000000050', 'c0000000-0000-0000-0000-000000000010', 1.0, 1, 1),
('dragon', 'b0000000-0000-0000-0000-000000000050', 'c0000000-0000-0000-0000-000000000009', 0.30, 1, 1),
('dragon', 'b0000000-0000-0000-0000-000000000050', 'c0000000-0000-0000-0000-000000000003', 0.80, 1, 3)
ON CONFLICT DO NOTHING;
