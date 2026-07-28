-- Upgrade script from legacy schema to v11
-- This migration adds new fields and updates data types
-- Safe to run on existing production databases

-- ============================================================================
-- PART 1: Add new columns to matches table
-- ============================================================================

-- Add set_scores column (from v6)
ALTER TABLE matches ADD COLUMN IF NOT EXISTS set_scores TEXT;

-- Add court_cover column (from v4)
ALTER TABLE matches ADD COLUMN IF NOT EXISTS court_cover TEXT;

-- Add court_conditions column (from v5)
ALTER TABLE matches ADD COLUMN IF NOT EXISTS court_conditions TEXT;

-- Add balls column (from v7)
ALTER TABLE matches ADD COLUMN IF NOT EXISTS balls TEXT;

-- Add altitude column (from v8)
ALTER TABLE matches ADD COLUMN IF NOT EXISTS altitude TEXT;

-- Add crowd column (from v9)
ALTER TABLE matches ADD COLUMN IF NOT EXISTS crowd TEXT;

-- Add court_speed column (from v10)
ALTER TABLE matches ADD COLUMN IF NOT EXISTS court_speed TEXT;

-- Add opponent_name_2 and partner_name columns (from v12)
ALTER TABLE matches ADD COLUMN IF NOT EXISTS opponent_name_2 TEXT;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS partner_name TEXT;

-- Add last_synced column (replaces synced_at with consistent naming)
ALTER TABLE matches ADD COLUMN IF NOT EXISTS last_synced TIMESTAMPTZ;
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS last_synced TIMESTAMPTZ;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS last_synced TIMESTAMPTZ;

-- ============================================================================
-- PART 2: Migrate timestamp columns from BIGINT to TIMESTAMPTZ
-- ============================================================================

-- For matches table
DO $$
BEGIN
  -- Check if match_date is still BIGINT (needs migration)
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'matches'
    AND column_name = 'match_date'
    AND data_type = 'bigint'
  ) THEN
    -- Add temporary columns
    ALTER TABLE matches ADD COLUMN IF NOT EXISTS match_date_new TIMESTAMPTZ;
    ALTER TABLE matches ADD COLUMN IF NOT EXISTS created_at_new TIMESTAMPTZ;
    ALTER TABLE matches ADD COLUMN IF NOT EXISTS updated_at_new TIMESTAMPTZ;

    -- Migrate data (convert milliseconds since epoch to timestamp)
    UPDATE matches SET
      match_date_new = to_timestamp(match_date / 1000.0),
      created_at_new = to_timestamp(created_at / 1000.0),
      updated_at_new = to_timestamp(updated_at / 1000.0)
    WHERE match_date IS NOT NULL;

    -- Drop old columns and rename new ones
    ALTER TABLE matches DROP COLUMN match_date;
    ALTER TABLE matches DROP COLUMN created_at;
    ALTER TABLE matches DROP COLUMN updated_at;
    ALTER TABLE matches RENAME COLUMN match_date_new TO match_date;
    ALTER TABLE matches RENAME COLUMN created_at_new TO created_at;
    ALTER TABLE matches RENAME COLUMN updated_at_new TO updated_at;

    -- Set defaults and NOT NULL constraints
    ALTER TABLE matches ALTER COLUMN created_at SET DEFAULT NOW();
    ALTER TABLE matches ALTER COLUMN created_at SET NOT NULL;
    ALTER TABLE matches ALTER COLUMN updated_at SET DEFAULT NOW();
    ALTER TABLE matches ALTER COLUMN updated_at SET NOT NULL;
  END IF;
END $$;

-- For conversations table
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'conversations'
    AND column_name = 'created_at'
    AND data_type = 'bigint'
  ) THEN
    ALTER TABLE conversations ADD COLUMN IF NOT EXISTS created_at_new TIMESTAMPTZ;
    ALTER TABLE conversations ADD COLUMN IF NOT EXISTS updated_at_new TIMESTAMPTZ;

    UPDATE conversations SET
      created_at_new = to_timestamp(created_at / 1000.0),
      updated_at_new = to_timestamp(updated_at / 1000.0);

    ALTER TABLE conversations DROP COLUMN created_at;
    ALTER TABLE conversations DROP COLUMN updated_at;
    ALTER TABLE conversations RENAME COLUMN created_at_new TO created_at;
    ALTER TABLE conversations RENAME COLUMN updated_at_new TO updated_at;

    ALTER TABLE conversations ALTER COLUMN created_at SET DEFAULT NOW();
    ALTER TABLE conversations ALTER COLUMN created_at SET NOT NULL;
    ALTER TABLE conversations ALTER COLUMN updated_at SET DEFAULT NOW();
    ALTER TABLE conversations ALTER COLUMN updated_at SET NOT NULL;
  END IF;
END $$;

-- For messages table
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'messages'
    AND column_name = 'timestamp'
    AND data_type = 'bigint'
  ) THEN
    ALTER TABLE messages ADD COLUMN IF NOT EXISTS timestamp_new TIMESTAMPTZ;

    UPDATE messages SET timestamp_new = to_timestamp(timestamp / 1000.0);

    ALTER TABLE messages DROP COLUMN timestamp;
    ALTER TABLE messages RENAME COLUMN timestamp_new TO timestamp;

    ALTER TABLE messages ALTER COLUMN timestamp SET DEFAULT NOW();
    ALTER TABLE messages ALTER COLUMN timestamp SET NOT NULL;
  END IF;
END $$;

-- ============================================================================
-- PART 3: Migrate is_error from INTEGER to BOOLEAN
-- ============================================================================

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'messages'
    AND column_name = 'is_error'
    AND data_type = 'integer'
  ) THEN
    -- Add new boolean column
    ALTER TABLE messages ADD COLUMN IF NOT EXISTS is_error_new BOOLEAN DEFAULT FALSE;

    -- Migrate data (0 = false, anything else = true)
    UPDATE messages SET is_error_new = (is_error != 0);

    -- Drop old column and rename new one
    ALTER TABLE messages DROP COLUMN is_error;
    ALTER TABLE messages RENAME COLUMN is_error_new TO is_error;

    -- Set default
    ALTER TABLE messages ALTER COLUMN is_error SET DEFAULT FALSE;
  END IF;
END $$;

-- ============================================================================
-- PART 4: Make user_id nullable (for local-only data before cloud sync)
-- ============================================================================

ALTER TABLE matches ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE conversations ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE messages ALTER COLUMN user_id DROP NOT NULL;

-- ============================================================================
-- PART 5: Make match_date nullable (matches can be created without dates)
-- ============================================================================

ALTER TABLE matches ALTER COLUMN match_date DROP NOT NULL;

-- ============================================================================
-- PART 6: Migrate legacy data values
-- ============================================================================

-- Update "Clay" to "Red clay"
UPDATE matches
SET court_surface = 'Red clay'
WHERE court_surface = 'Clay';

-- Remove legacy "High altitude" from conditions
UPDATE matches
SET court_conditions = NULL
WHERE court_conditions = 'High altitude';

-- ============================================================================
-- PART 7: Copy synced_at to last_synced and drop old column
-- ============================================================================

-- Copy existing synced_at values to last_synced
UPDATE matches SET last_synced = synced_at WHERE synced_at IS NOT NULL;
UPDATE conversations SET last_synced = synced_at WHERE synced_at IS NOT NULL;
UPDATE messages SET last_synced = synced_at WHERE synced_at IS NOT NULL;

-- Drop old synced_at column
ALTER TABLE matches DROP COLUMN IF EXISTS synced_at;
ALTER TABLE conversations DROP COLUMN IF EXISTS synced_at;
ALTER TABLE messages DROP COLUMN IF EXISTS synced_at;

-- ============================================================================
-- PART 8: Update triggers to use updated_at instead of synced_at
-- ============================================================================

-- Drop old triggers
DROP TRIGGER IF EXISTS update_matches_synced_at ON matches;
DROP TRIGGER IF EXISTS update_conversations_synced_at ON conversations;
DROP TRIGGER IF EXISTS update_messages_synced_at ON messages;

-- Drop old function
DROP FUNCTION IF EXISTS update_synced_at();

-- Create new function for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create new triggers for updated_at (only on matches and conversations, not messages)
CREATE TRIGGER update_matches_updated_at
  BEFORE UPDATE ON matches
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_conversations_updated_at
  BEFORE UPDATE ON conversations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- PART 9: Update indexes for better performance
-- ============================================================================

-- Drop old indexes that might conflict
DROP INDEX IF EXISTS idx_matches_date;

-- Create new indexes matching the new schema
CREATE INDEX IF NOT EXISTS idx_matches_date ON matches(match_date DESC);
CREATE INDEX IF NOT EXISTS idx_matches_created_at ON matches(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_created_at ON conversations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages(timestamp DESC);

-- ============================================================================
-- PART 10: Add comments for documentation
-- ============================================================================

COMMENT ON TABLE matches IS 'Stores tennis match records with opponent details, scores, and court information';
COMMENT ON TABLE conversations IS 'Stores AI coaching conversation sessions, optionally linked to matches';
COMMENT ON TABLE messages IS 'Stores individual messages within conversations (user prompts and AI responses)';

COMMENT ON COLUMN matches.court_surface IS 'Values: Red clay, Green clay, Hard, Grass, Carpet';
COMMENT ON COLUMN matches.court_speed IS 'Values: Slow, Slow-Medium (clay), Medium, Medium-Fast (hard), Fast (grass/carpet)';
COMMENT ON COLUMN matches.court_cover IS 'Values: Outdoor, Bubble, Fabric, Retractable, Indoor';
COMMENT ON COLUMN matches.court_conditions IS 'Values: Hot-dry, Hot-humid, Mild, Cold-dry, Cold-humid, Windy, Rain';
COMMENT ON COLUMN matches.altitude IS 'Values: Low (0-1,000m/0-3,300ft), Mid (1,000-1,500m/3,300-5,000ft), High (1,500+m/5,000+ft)';
COMMENT ON COLUMN matches.crowd IS 'Values: No crowd, Neutral, Respectful, Friendly, Hostile, Divided, Disruptive';
COMMENT ON COLUMN matches.match_type IS 'Values: Singles, Doubles';
COMMENT ON COLUMN messages.role IS 'Values: user, assistant';

-- ============================================================================
-- Migration complete!
-- ============================================================================
