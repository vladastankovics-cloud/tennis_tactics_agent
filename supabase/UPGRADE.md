# Upgrading Supabase Schema

## Overview

If you previously deployed the `supabase_migrations.sql` schema, you need to run the upgrade script to add new fields and update data types.

## What's Changed

### New Fields Added
- ✅ `court_speed` - Court speed (Slow, Medium, Fast, etc.)
- ✅ `court_cover` - Indoor/outdoor/bubble/retractable
- ✅ `court_conditions` - Weather conditions
- ✅ `altitude` - Low/Mid/High altitude
- ✅ `balls` - Ball type or brand
- ✅ `crowd` - Crowd behavior
- ✅ `set_scores` - Detailed set scores

### Data Type Changes
- 📅 Timestamps: `BIGINT` → `TIMESTAMPTZ` (match_date, created_at, updated_at, timestamp)
- ✓ Error flag: `INTEGER` → `BOOLEAN` (is_error)
- 🔄 Sync column: `synced_at` → `last_synced` (consistent naming)

### Schema Changes
- 🔓 `user_id` now nullable (allows local-only data before cloud sync)
- 🔓 `match_date` now nullable (can create matches without dates)
- 🎾 Legacy data migrated: "Clay" → "Red clay"
- 🏔️ Legacy condition removed: "High altitude" → NULL (moved to altitude field)

## Upgrade Steps

### Option 1: Using Supabase CLI (Recommended)

1. **Make sure you have the latest migrations:**
   ```bash
   cd C:\Users\Vlada\projects\tennis_tactics_agent
   ```

2. **Link to your Supabase project** (if not already linked):
   ```bash
   supabase link --project-ref YOUR_PROJECT_REF
   ```

3. **Push migrations:**
   ```bash
   supabase db push
   ```

   This will:
   - Detect existing tables
   - Apply only the upgrade script (20260208000001_upgrade_from_legacy.sql)
   - Safely migrate your data
   - Take ~30 seconds with typical data volumes

4. **Verify the upgrade:**
   ```bash
   supabase db diff
   ```
   Should show no pending changes.

### Option 2: Using Supabase Dashboard

1. **Open your Supabase project**
   - Go to https://supabase.com/dashboard
   - Select your project

2. **Go to SQL Editor**
   - Click "SQL Editor" in the left sidebar
   - Click "+ New query"

3. **Run the upgrade script**
   - Copy the contents of `supabase/migrations/20260208000001_upgrade_from_legacy.sql`
   - Paste into the SQL editor
   - Click "Run" (or press Ctrl+Enter)

4. **Wait for completion**
   - Should complete in 5-30 seconds
   - Check for "Success" message

5. **Verify the changes**
   - Go to "Table Editor"
   - Open `matches` table
   - Verify new columns are present: court_speed, altitude, crowd, etc.

## Verification Checklist

After running the upgrade, verify:

- [ ] New columns exist: `court_speed`, `altitude`, `crowd`, `balls`, `court_cover`, `court_conditions`, `set_scores`
- [ ] Column `last_synced` exists (replaces `synced_at`)
- [ ] Timestamp columns are TIMESTAMPTZ (not BIGINT)
- [ ] `is_error` column is BOOLEAN (not INTEGER)
- [ ] Existing data is intact (check a few matches)
- [ ] Legacy "Clay" values converted to "Red clay"
- [ ] No errors in Supabase logs

## Rollback (If Needed)

If you encounter issues, you can rollback by:

1. **Create a backup first:**
   ```bash
   supabase db dump -f backup_before_upgrade.sql
   ```

2. **Restore from backup:**
   ```bash
   supabase db reset --db-url YOUR_DATABASE_URL
   psql YOUR_DATABASE_URL < backup_before_upgrade.sql
   ```

## Data Migration Details

### Timestamp Conversion
- Old: `1706774400000` (milliseconds since epoch)
- New: `2024-02-01 00:00:00+00` (TIMESTAMPTZ)
- Conversion: `to_timestamp(bigint_value / 1000.0)`

### Boolean Conversion
- Old: `0` (false), `1` or other (true)
- New: `false`, `true`
- Conversion: `is_error != 0`

### Surface Migration
- Old: `Clay`
- New: `Red clay`
- Rationale: Split clay into red/green for better granularity

## Testing After Upgrade

1. **Test data retrieval:**
   - Open your app
   - View existing matches
   - Verify all fields display correctly

2. **Test new fields:**
   - Create a new match
   - Fill in new fields (speed, altitude, crowd)
   - Save and verify

3. **Test sync (if implemented):**
   - Make changes locally
   - Sync to cloud
   - Verify `last_synced` is updated

## Support

If you encounter issues during upgrade:
1. Check Supabase logs for detailed error messages
2. Verify your database version is PostgreSQL 15+
3. Ensure you have sufficient permissions
4. Create a backup before retrying

## Migration SQL Reference

The upgrade script is idempotent and safe to run multiple times. It includes:
- `IF NOT EXISTS` checks for all new columns
- `DO $$ BEGIN ... END $$` blocks for conditional logic
- Data type checking before conversions
- Proper rollback on errors
