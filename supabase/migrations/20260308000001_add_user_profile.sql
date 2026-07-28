-- Create user_profile table for storing the user's own profile and evaluation
CREATE TABLE IF NOT EXISTS user_profile (
    id TEXT PRIMARY KEY,
    birth_year INTEGER,
    height_cm INTEGER,
    weight_kg REAL,
    years_active TEXT,
    hands TEXT,
    backhand_type TEXT,
    -- Physical attributes (0-100)
    agility INTEGER DEFAULT 50,
    mobility INTEGER DEFAULT 50,
    lean_body INTEGER DEFAULT 50,
    endurance INTEGER DEFAULT 50,
    power INTEGER DEFAULT 50,
    reach INTEGER DEFAULT 50,
    coordination INTEGER DEFAULT 50,
    balance INTEGER DEFAULT 50,
    -- Technical skills (0-100)
    serve INTEGER DEFAULT 50,
    return_serve INTEGER DEFAULT 50,
    forehand INTEGER DEFAULT 50,
    backhand INTEGER DEFAULT 50,
    transition INTEGER DEFAULT 50,
    net INTEGER DEFAULT 50,
    specialty INTEGER DEFAULT 50,
    -- Playing styles (0-100)
    counterpuncher INTEGER DEFAULT 50,
    aggressive_baseliner INTEGER DEFAULT 50,
    all_court_player INTEGER DEFAULT 50,
    net_rusher INTEGER DEFAULT 50,
    serve_and_volleyer INTEGER DEFAULT 50,
    big_server INTEGER DEFAULT 50,
    -- Support system (0-100)
    family INTEGER DEFAULT 50,
    coaches INTEGER DEFAULT 50,
    partners INTEGER DEFAULT 50,
    crowd INTEGER DEFAULT 50,
    sponsors INTEGER DEFAULT 50,
    -- Mental attributes (0-100)
    focus INTEGER DEFAULT 50,
    calmness INTEGER DEFAULT 50,
    clutchness INTEGER DEFAULT 50,
    confidence INTEGER DEFAULT 50,
    -- Timestamps
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

-- Enable Row Level Security
ALTER TABLE user_profile ENABLE ROW LEVEL SECURITY;

-- Create policy for users to manage their own profile
CREATE POLICY "Users can manage their own profile"
    ON user_profile
    FOR ALL
    USING (true)
    WITH CHECK (true);
