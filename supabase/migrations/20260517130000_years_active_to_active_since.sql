-- ============================================================================
-- Migration: Rename years_active to active_since_year
-- ============================================================================
-- The field now stores "active since year" (e.g., 2015)
-- Renamed for clarity: years_active -> active_since_year
-- ============================================================================

-- Rename column in user_profile table
ALTER TABLE user_profile RENAME COLUMN years_active TO active_since_year;

-- Rename column in opponents table
ALTER TABLE opponents RENAME COLUMN years_active TO active_since_year;

-- No schema change needed - column remains TEXT
-- This migration documents the semantic change

-- Optional: Add comments for documentation
COMMENT ON COLUMN user_profile.active_since_year IS 'Year player started playing (e.g., 2015). App calculates years active.';
COMMENT ON COLUMN opponents.active_since_year IS 'Year opponent started playing (e.g., 2015). App calculates years active.';

-- Optional: Clear invalid old data (uncomment if needed)
-- UPDATE user_profile SET active_since_year = NULL WHERE active_since_year !~ '^\d{4}$';
-- UPDATE opponents SET active_since_year = NULL WHERE active_since_year !~ '^\d{4}$';
