-- ============================================================================
-- COMBINED MIGRATION: All changes since February 8th, 2026
-- ============================================================================
-- This script combines all migrations from Feb 8th to March 15th, 2026
-- Safe to run - uses IF NOT EXISTS / IF EXISTS checks
-- ============================================================================

-- ============================================================================
-- PART 0: Missing columns from initial schema (if not applied)
-- ============================================================================
-- These columns should exist but may be missing from some deployments

ALTER TABLE matches ADD COLUMN IF NOT EXISTS opponent_name_2 TEXT;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS partner_name TEXT;

-- ============================================================================
-- PART 1: Court Name (Feb 20)
-- ============================================================================
-- Add court_name column to matches table for identifying courts by name

ALTER TABLE matches ADD COLUMN IF NOT EXISTS court_name TEXT;

-- ============================================================================
-- PART 2: Adjustments (Feb 22)
-- ============================================================================
-- Add adjustment columns for tracking player conditions during matches

ALTER TABLE matches ADD COLUMN IF NOT EXISTS my_adjustment TEXT;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS opponent_adjustment TEXT;

-- ============================================================================
-- PART 3: Opponents Table (Mar 8)
-- ============================================================================
-- Create opponents table for storing opponent profiles and evaluations

CREATE TABLE IF NOT EXISTS opponents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    -- Profile fields
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
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index for opponents
CREATE INDEX IF NOT EXISTS idx_opponents_user_id ON opponents(user_id);
CREATE INDEX IF NOT EXISTS idx_opponents_name ON opponents(name);

-- Enable Row Level Security for opponents
ALTER TABLE opponents ENABLE ROW LEVEL SECURITY;

-- RLS Policies for opponents
DROP POLICY IF EXISTS "Users can view their own opponents" ON opponents;
CREATE POLICY "Users can view their own opponents"
    ON opponents FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own opponents" ON opponents;
CREATE POLICY "Users can insert their own opponents"
    ON opponents FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own opponents" ON opponents;
CREATE POLICY "Users can update their own opponents"
    ON opponents FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own opponents" ON opponents;
CREATE POLICY "Users can delete their own opponents"
    ON opponents FOR DELETE
    USING (auth.uid() = user_id);

-- Create trigger to automatically update updated_at for opponents
DROP TRIGGER IF EXISTS update_opponents_updated_at ON opponents;
CREATE TRIGGER update_opponents_updated_at
    BEFORE UPDATE ON opponents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- PART 4: User Profile Table (Mar 8)
-- ============================================================================
-- Create user_profile table for storing the user's own profile and evaluation

CREATE TABLE IF NOT EXISTS user_profile (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
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
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index for user_profile
CREATE INDEX IF NOT EXISTS idx_user_profile_user_id ON user_profile(user_id);

-- Enable Row Level Security for user_profile
ALTER TABLE user_profile ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_profile
DROP POLICY IF EXISTS "Users can view their own profile" ON user_profile;
CREATE POLICY "Users can view their own profile"
    ON user_profile FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON user_profile;
CREATE POLICY "Users can insert their own profile"
    ON user_profile FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own profile" ON user_profile;
CREATE POLICY "Users can update their own profile"
    ON user_profile FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own profile" ON user_profile;
CREATE POLICY "Users can delete their own profile"
    ON user_profile FOR DELETE
    USING (auth.uid() = user_id);

-- Create trigger to automatically update updated_at for user_profile
DROP TRIGGER IF EXISTS update_user_profile_updated_at ON user_profile;
CREATE TRIGGER update_user_profile_updated_at
    BEFORE UPDATE ON user_profile
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- PART 5: Match Format (Mar 15)
-- ============================================================================
-- Add match format columns for tracking scoring formats

-- match_format: stores format like "Full sets (best of 3, 6 games)", "Pro set", "Tiebreak"
ALTER TABLE matches ADD COLUMN IF NOT EXISTS match_format TEXT;

-- no_ads: sudden death at deuce (no advantage scoring)
ALTER TABLE matches ADD COLUMN IF NOT EXISTS no_ads BOOLEAN DEFAULT FALSE;

-- tiebreak_set: final set uses tiebreak format (at 1:1 in best of 3, 2:2 in best of 5)
ALTER TABLE matches ADD COLUMN IF NOT EXISTS tiebreak_set BOOLEAN DEFAULT FALSE;

-- ============================================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE opponents IS 'Stores opponent profiles with physical, technical, and mental attributes';
COMMENT ON TABLE user_profile IS 'Stores the user own profile with physical, technical, and mental attributes';

COMMENT ON COLUMN matches.court_name IS 'Name/identifier for the court';
COMMENT ON COLUMN matches.my_adjustment IS 'User condition adjustments (injury, fatigue, etc.)';
COMMENT ON COLUMN matches.opponent_adjustment IS 'Opponent condition adjustments';
COMMENT ON COLUMN matches.match_format IS 'Match scoring format (e.g., Full sets best of 3, Pro set, Tiebreak)';
COMMENT ON COLUMN matches.no_ads IS 'Whether match uses no-ad scoring (sudden death at deuce)';
COMMENT ON COLUMN matches.tiebreak_set IS 'Whether final set uses tiebreak format';

-- ============================================================================
-- VERIFICATION QUERY (optional - run to verify changes applied)
-- ============================================================================

-- Uncomment to verify all changes:
/*
SELECT 'matches columns' as check_type, column_name, data_type
FROM information_schema.columns
WHERE table_name = 'matches'
AND column_name IN ('court_name', 'my_adjustment', 'opponent_adjustment', 'match_format', 'no_ads', 'tiebreak_set')
UNION ALL
SELECT 'opponents table' as check_type, 'exists' as column_name,
    CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'opponents')
    THEN 'YES' ELSE 'NO' END
UNION ALL
SELECT 'user_profile table' as check_type, 'exists' as column_name,
    CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'user_profile')
    THEN 'YES' ELSE 'NO' END;
*/
