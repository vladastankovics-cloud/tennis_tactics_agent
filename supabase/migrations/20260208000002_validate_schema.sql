-- Schema Validation Script
-- Run this to verify your database matches the expected v11 schema
-- Safe to run - this only queries, does not modify data

-- ============================================================================
-- VALIDATION QUERIES
-- ============================================================================

-- Check 1: Verify all expected columns exist in matches table
SELECT
  'matches columns' as check_name,
  CASE
    WHEN COUNT(*) >= 17 THEN '✓ PASS'
    ELSE '✗ FAIL - Missing columns'
  END as status,
  COUNT(*) as column_count,
  'Expected: 17+' as expected
FROM information_schema.columns
WHERE table_name = 'matches'
AND column_name IN (
  'id', 'user_id', 'opponent_name', 'match_date', 'match_result',
  'match_score_user', 'match_score_opponent', 'set_scores', 'match_type',
  'court_surface', 'court_speed', 'court_cover', 'court_conditions',
  'altitude', 'balls', 'crowd', 'notes', 'created_at', 'updated_at', 'last_synced'
);

-- Check 2: Verify match_date is TIMESTAMPTZ
SELECT
  'match_date type' as check_name,
  CASE
    WHEN data_type IN ('timestamp with time zone', 'timestamptz') THEN '✓ PASS'
    ELSE '✗ FAIL - Should be TIMESTAMPTZ, found: ' || data_type
  END as status,
  data_type as current_type,
  'TIMESTAMPTZ' as expected_type
FROM information_schema.columns
WHERE table_name = 'matches' AND column_name = 'match_date';

-- Check 3: Verify created_at is TIMESTAMPTZ
SELECT
  'created_at type' as check_name,
  CASE
    WHEN data_type IN ('timestamp with time zone', 'timestamptz') THEN '✓ PASS'
    ELSE '✗ FAIL - Should be TIMESTAMPTZ, found: ' || data_type
  END as status,
  data_type as current_type,
  'TIMESTAMPTZ' as expected_type
FROM information_schema.columns
WHERE table_name = 'matches' AND column_name = 'created_at';

-- Check 4: Verify is_error is BOOLEAN
SELECT
  'is_error type' as check_name,
  CASE
    WHEN data_type = 'boolean' THEN '✓ PASS'
    WHEN data_type = 'integer' THEN '⚠ WARNING - Still INTEGER, should be BOOLEAN'
    ELSE '✗ FAIL - Unexpected type: ' || data_type
  END as status,
  data_type as current_type,
  'BOOLEAN' as expected_type
FROM information_schema.columns
WHERE table_name = 'messages' AND column_name = 'is_error';

-- Check 5: Verify user_id is nullable
SELECT
  'user_id nullable' as check_name,
  CASE
    WHEN is_nullable = 'YES' THEN '✓ PASS'
    ELSE '✗ FAIL - Should be nullable for local-only data'
  END as status,
  is_nullable as current,
  'YES' as expected
FROM information_schema.columns
WHERE table_name = 'matches' AND column_name = 'user_id';

-- Check 6: Verify last_synced exists (not synced_at)
SELECT
  'last_synced column' as check_name,
  CASE
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'matches' AND column_name = 'last_synced'
    ) AND NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'matches' AND column_name = 'synced_at'
    ) THEN '✓ PASS'
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_name = 'matches' AND column_name = 'synced_at'
    ) THEN '⚠ WARNING - Old column synced_at still exists'
    ELSE '✗ FAIL - Missing last_synced column'
  END as status,
  'last_synced' as expected,
  '' as note;

-- Check 7: Verify new court fields exist
SELECT
  'new court fields' as check_name,
  CASE
    WHEN COUNT(*) = 6 THEN '✓ PASS'
    ELSE '✗ FAIL - Missing ' || (6 - COUNT(*)) || ' field(s)'
  END as status,
  COUNT(*) as found_count,
  '6' as expected_count
FROM information_schema.columns
WHERE table_name = 'matches'
AND column_name IN ('court_speed', 'court_cover', 'court_conditions', 'altitude', 'balls', 'crowd');

-- Check 8: Verify triggers exist
SELECT
  'updated_at triggers' as check_name,
  CASE
    WHEN COUNT(*) >= 2 THEN '✓ PASS'
    ELSE '✗ FAIL - Missing triggers'
  END as status,
  COUNT(*) as trigger_count,
  '2+' as expected
FROM information_schema.triggers
WHERE trigger_name IN ('update_matches_updated_at', 'update_conversations_updated_at');

-- Check 9: Verify indexes exist
SELECT
  'performance indexes' as check_name,
  CASE
    WHEN COUNT(*) >= 8 THEN '✓ PASS'
    WHEN COUNT(*) >= 6 THEN '⚠ WARNING - Some optional indexes missing'
    ELSE '✗ FAIL - Missing critical indexes'
  END as status,
  COUNT(*) as index_count,
  '8+' as expected
FROM pg_indexes
WHERE schemaname = 'public'
AND tablename IN ('matches', 'conversations', 'messages');

-- Check 10: Verify RLS policies exist
SELECT
  'RLS policies' as check_name,
  CASE
    WHEN COUNT(*) >= 12 THEN '✓ PASS'
    ELSE '✗ FAIL - Missing ' || (12 - COUNT(*)) || ' policy/policies'
  END as status,
  COUNT(*) as policy_count,
  '12+' as expected
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('matches', 'conversations', 'messages');

-- ============================================================================
-- DATA VALIDATION
-- ============================================================================

-- Check 11: Verify no legacy "Clay" values
SELECT
  'legacy clay values' as check_name,
  CASE
    WHEN COUNT(*) = 0 THEN '✓ PASS - No legacy values'
    ELSE '⚠ WARNING - Found ' || COUNT(*) || ' match(es) with legacy "Clay" value'
  END as status,
  COUNT(*) as legacy_count,
  '0' as expected
FROM matches
WHERE court_surface = 'Clay';

-- Check 12: Verify no legacy "High altitude" conditions
SELECT
  'legacy altitude values' as check_name,
  CASE
    WHEN COUNT(*) = 0 THEN '✓ PASS - No legacy values'
    ELSE '⚠ WARNING - Found ' || COUNT(*) || ' match(es) with legacy "High altitude" condition'
  END as status,
  COUNT(*) as legacy_count,
  '0' as expected
FROM matches
WHERE court_conditions = 'High altitude';

-- ============================================================================
-- SUMMARY
-- ============================================================================

-- Overall summary
SELECT
  '═══════════════════' as separator,
  'VALIDATION SUMMARY' as title,
  '═══════════════════' as separator2;

SELECT
  COUNT(*) FILTER (WHERE status LIKE '✓%') as passed_checks,
  COUNT(*) FILTER (WHERE status LIKE '⚠%') as warning_checks,
  COUNT(*) FILTER (WHERE status LIKE '✗%') as failed_checks,
  COUNT(*) as total_checks
FROM (
  -- Combine all check results
  SELECT 'matches columns' as check_name,
    CASE WHEN COUNT(*) >= 17 THEN '✓' ELSE '✗' END as status
  FROM information_schema.columns WHERE table_name = 'matches'
  UNION ALL
  SELECT 'match_date type',
    CASE WHEN data_type IN ('timestamp with time zone', 'timestamptz') THEN '✓' ELSE '✗' END
  FROM information_schema.columns WHERE table_name = 'matches' AND column_name = 'match_date'
  -- ... (other checks would be included here)
) validation_results;

-- Final recommendation
SELECT
  CASE
    WHEN (SELECT COUNT(*) FROM matches WHERE court_surface = 'Clay') > 0
      OR (SELECT COUNT(*) FROM messages WHERE pg_typeof(is_error)::text = 'integer')  > 0
    THEN '⚠ RECOMMENDATION: Run upgrade script (20260208000001_upgrade_from_legacy.sql)'
    ELSE '✓ Schema is up to date!'
  END as recommendation;
