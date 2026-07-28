-- ============================================================================
-- COMBINED MIGRATION: All changes since April 12th, 2026
-- ============================================================================
-- This script combines all migrations from Apr 12th to May 17th, 2026
-- Safe to run - uses IF NOT EXISTS / IF EXISTS checks
-- ============================================================================

-- ============================================================================
-- PART 1: Play Adjustments - Add outcome column (May 16)
-- ============================================================================
-- Add outcome column to play_adjustments table for tracking successful/unsuccessful adjustments
-- Values: NULL (no outcome yet), 'successful', 'unsuccessful'

ALTER TABLE play_adjustments ADD COLUMN IF NOT EXISTS outcome TEXT;

-- ============================================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON COLUMN play_adjustments.outcome IS 'Outcome of the adjustment: null (no outcome), successful, or unsuccessful';

-- ============================================================================
-- VERIFICATION QUERY (optional - run to verify changes applied)
-- ============================================================================

-- Uncomment to verify all changes:
/*
SELECT 'play_adjustments.outcome' as check_type,
    CASE WHEN EXISTS (
        SELECT FROM information_schema.columns
        WHERE table_name = 'play_adjustments' AND column_name = 'outcome'
    ) THEN 'YES' ELSE 'NO' END as exists;
*/
