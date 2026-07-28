-- ============================================================================
-- COMBINED MIGRATION: All changes since March 15th, 2026
-- ============================================================================
-- This script combines all migrations from Mar 15th to April 11th, 2026
-- Safe to run - uses IF NOT EXISTS / IF EXISTS checks
-- ============================================================================

-- ============================================================================
-- PART 1: Play Adjustments Table (Mar 20)
-- ============================================================================
-- Create play_adjustments table for storing tactical adjustments during match play
-- This tracks specific tactics/adjustments for different game situations

CREATE TABLE IF NOT EXISTS play_adjustments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    short_name TEXT NOT NULL,
    description TEXT NOT NULL,
    situation TEXT NOT NULL,
    momentum TEXT NOT NULL,
    grid_position INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for play_adjustments
CREATE INDEX IF NOT EXISTS idx_play_adjustments_user_id ON play_adjustments(user_id);
CREATE INDEX IF NOT EXISTS idx_play_adjustments_match ON play_adjustments(match_id, situation, momentum);

-- Enable Row Level Security for play_adjustments
ALTER TABLE play_adjustments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for play_adjustments
DROP POLICY IF EXISTS "Users can view their own play_adjustments" ON play_adjustments;
CREATE POLICY "Users can view their own play_adjustments"
    ON play_adjustments FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own play_adjustments" ON play_adjustments;
CREATE POLICY "Users can insert their own play_adjustments"
    ON play_adjustments FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own play_adjustments" ON play_adjustments;
CREATE POLICY "Users can update their own play_adjustments"
    ON play_adjustments FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own play_adjustments" ON play_adjustments;
CREATE POLICY "Users can delete their own play_adjustments"
    ON play_adjustments FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- PART 2: Practice Status Table (Apr 5)
-- ============================================================================
-- Create practice_status table for tracking dismissed and "later" matches in practice mode
-- This allows users to manage which past matches they want to review

CREATE TABLE IF NOT EXISTS practice_status (
    match_id UUID PRIMARY KEY REFERENCES matches(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index for practice_status
CREATE INDEX IF NOT EXISTS idx_practice_status_user_id ON practice_status(user_id);

-- Enable Row Level Security for practice_status
ALTER TABLE practice_status ENABLE ROW LEVEL SECURITY;

-- RLS Policies for practice_status
DROP POLICY IF EXISTS "Users can view their own practice_status" ON practice_status;
CREATE POLICY "Users can view their own practice_status"
    ON practice_status FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own practice_status" ON practice_status;
CREATE POLICY "Users can insert their own practice_status"
    ON practice_status FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own practice_status" ON practice_status;
CREATE POLICY "Users can update their own practice_status"
    ON practice_status FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own practice_status" ON practice_status;
CREATE POLICY "Users can delete their own practice_status"
    ON practice_status FOR DELETE
    USING (auth.uid() = user_id);

-- Create trigger to automatically update updated_at for practice_status
DROP TRIGGER IF EXISTS update_practice_status_updated_at ON practice_status;
CREATE TRIGGER update_practice_status_updated_at
    BEFORE UPDATE ON practice_status
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE play_adjustments IS 'Stores tactical adjustments for different game situations during match play';
COMMENT ON COLUMN play_adjustments.short_name IS 'Short display name for the adjustment (e.g., "Attack 2nd serve")';
COMMENT ON COLUMN play_adjustments.description IS 'Full description of the tactical adjustment';
COMMENT ON COLUMN play_adjustments.situation IS 'Game situation: serving or returning';
COMMENT ON COLUMN play_adjustments.momentum IS 'Match momentum: winning, neutral, or losing';
COMMENT ON COLUMN play_adjustments.grid_position IS 'Position in the tactics grid (0-5)';

COMMENT ON TABLE practice_status IS 'Tracks dismissed/later status for past matches in practice review mode';
COMMENT ON COLUMN practice_status.status IS 'Status: dismissed (permanent) or later (session-only, stored for sync)';

-- ============================================================================
-- VERIFICATION QUERY (optional - run to verify changes applied)
-- ============================================================================

-- Uncomment to verify all changes:
/*
SELECT 'play_adjustments table' as check_type, 'exists' as column_name,
    CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'play_adjustments')
    THEN 'YES' ELSE 'NO' END
UNION ALL
SELECT 'practice_status table' as check_type, 'exists' as column_name,
    CASE WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'practice_status')
    THEN 'YES' ELSE 'NO' END;
*/
