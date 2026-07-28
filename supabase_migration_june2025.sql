-- Tennis Tactics Agent - Supabase Migration (Post June 7, 2025)
-- Run this script in your Supabase SQL Editor to add new tables and columns

-- ============================================================================
-- PART 1: Add missing columns to matches table
-- ============================================================================

ALTER TABLE matches ADD COLUMN IF NOT EXISTS opponent_name_2 TEXT;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS partner_name TEXT;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS set_scores TEXT;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS match_format TEXT;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS no_ads INTEGER DEFAULT 0;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS tiebreak_set INTEGER DEFAULT 0;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS court_name TEXT;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS court_speed TEXT;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS court_cover TEXT;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS court_conditions TEXT;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS altitude TEXT;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS my_adjustment TEXT;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS opponent_adjustment TEXT;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS balls TEXT;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS crowd TEXT;

-- ============================================================================
-- PART 2: Create practice_hidden table (Version 26)
-- ============================================================================

CREATE TABLE IF NOT EXISTS practice_hidden (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  short_name TEXT NOT NULL,
  hidden_at BIGINT NOT NULL,
  synced_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, short_name)
);

CREATE INDEX IF NOT EXISTS idx_practice_hidden_user_id ON practice_hidden(user_id);

-- Enable RLS for practice_hidden
ALTER TABLE practice_hidden ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own practice_hidden"
  ON practice_hidden FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own practice_hidden"
  ON practice_hidden FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own practice_hidden"
  ON practice_hidden FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own practice_hidden"
  ON practice_hidden FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- PART 3: Create function and trigger for synced_at
-- ============================================================================

-- Create the function if it doesn't exist
CREATE OR REPLACE FUNCTION update_synced_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.synced_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_practice_hidden_synced_at
  BEFORE UPDATE ON practice_hidden
  FOR EACH ROW
  EXECUTE FUNCTION update_synced_at();
