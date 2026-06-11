-- Dark World — Migration 007: World Simulation (Epsilon)

CREATE TABLE IF NOT EXISTS world_time (
    world_id UUID PRIMARY KEY REFERENCES worlds(id),
    hour INTEGER NOT NULL DEFAULT 12 CHECK (hour >= 0 AND hour <= 23),
    day INTEGER NOT NULL DEFAULT 1 CHECK (day >= 1 AND day <= 30),
    month INTEGER NOT NULL DEFAULT 1 CHECK (month >= 1 AND month <= 12),
    year INTEGER NOT NULL DEFAULT 1,
    season TEXT NOT NULL DEFAULT 'spring' CHECK (season IN ('spring','summer','autumn','winter')),
    tick_speed NUMERIC(5,2) NOT NULL DEFAULT 1.0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS world_weather (
    world_id UUID PRIMARY KEY REFERENCES worlds(id),
    state TEXT NOT NULL DEFAULT 'clear' CHECK (state IN ('clear','cloudy','light_rain','heavy_rain','storm','fog','drought','cold','heat')),
    temperature NUMERIC(5,1) NOT NULL DEFAULT 22.0,
    humidity NUMERIC(5,1) NOT NULL DEFAULT 50.0,
    wind_speed NUMERIC(5,1) NOT NULL DEFAULT 5.0,
    wind_direction NUMERIC(5,1) NOT NULL DEFAULT 0.0,
    visibility NUMERIC(5,1) NOT NULL DEFAULT 100.0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS world_season_config (
    season TEXT PRIMARY KEY CHECK (season IN ('spring','summer','autumn','winter')),
    temp_min NUMERIC(5,1) NOT NULL,
    temp_max NUMERIC(5,1) NOT NULL,
    rain_chance NUMERIC(3,2) NOT NULL DEFAULT 0.3,
    fog_chance NUMERIC(3,2) NOT NULL DEFAULT 0.1,
    description TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS world_events_environmental (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    world_id UUID REFERENCES worlds(id),
    event_type TEXT NOT NULL CHECK (event_type IN ('storm','drought','cold_wave','heat_wave','fog','flood','wildfire')),
    severity TEXT NOT NULL DEFAULT 'mild' CHECK (severity IN ('mild','moderate','severe')),
    starts_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ends_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '1 hour',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seeds
INSERT INTO world_time (world_id, hour, day, month, year, season) VALUES
('a0000000-0000-0000-0000-000000000001', 12, 1, 6, 1, 'summer')
ON CONFLICT (world_id) DO NOTHING;

INSERT INTO world_weather (world_id, state, temperature, humidity, wind_speed) VALUES
('a0000000-0000-0000-0000-000000000001', 'clear', 24.0, 45.0, 8.0)
ON CONFLICT (world_id) DO NOTHING;

INSERT INTO world_season_config (season, temp_min, temp_max, rain_chance, fog_chance, description) VALUES
('spring', 12.0, 25.0, 0.35, 0.15, 'Flores e chuvas leves'),
('summer', 22.0, 38.0, 0.15, 0.05, 'Calor intenso e seca'),
('autumn', 8.0, 20.0, 0.40, 0.25, 'Ventos e folhas caindo'),
('winter', -5.0, 10.0, 0.30, 0.35, 'Frio intenso e neblina')
ON CONFLICT (season) DO NOTHING;
