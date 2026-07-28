-- ============================================================================
-- Add level column to user_profile and opponents tables
-- ============================================================================
-- Stores player skill level (e.g., Beginner, Intermediate, Advanced)
-- ============================================================================

-- Add level column to user_profile
ALTER TABLE user_profile ADD COLUMN IF NOT EXISTS level TEXT;

-- Add level column to opponents
ALTER TABLE opponents ADD COLUMN IF NOT EXISTS level TEXT;

-- Add comments
COMMENT ON COLUMN user_profile.level IS 'Player skill level (e.g., Beginner, Intermediate, Advanced)';
COMMENT ON COLUMN opponents.level IS 'Opponent skill level (e.g., Beginner, Intermediate, Advanced)';
