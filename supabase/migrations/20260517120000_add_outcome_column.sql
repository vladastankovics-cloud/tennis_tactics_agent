-- ============================================================================
-- Add outcome column to play_adjustments table
-- ============================================================================
-- Tracks whether an adjustment was successful or unsuccessful
-- Values: NULL (no outcome yet), 'successful', 'unsuccessful'
-- ============================================================================

ALTER TABLE play_adjustments ADD COLUMN IF NOT EXISTS outcome TEXT;

COMMENT ON COLUMN play_adjustments.outcome IS 'Outcome of the adjustment: null (no outcome), successful, or unsuccessful';
