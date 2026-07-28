# Supabase Database Setup

This directory contains Supabase migrations for the Tennis Tactics Agent app.

## Overview

The app currently uses local SQLite storage, with optional Supabase cloud sync planned for the future. These migrations create the cloud database schema that mirrors the local SQLite schema.

## Database Schema

### Tables

1. **matches** - Stores tennis match records
   - Match details (opponent, date, score)
   - Court information (surface, speed, cover, conditions, altitude)
   - Additional details (balls, crowd, notes)

2. **conversations** - Stores AI coaching conversation sessions
   - Can be linked to specific matches
   - Contains metadata and timestamps

3. **messages** - Stores individual messages within conversations
   - User prompts and AI responses
   - Role-based (user/assistant)
   - Error tracking

### Key Features

- **Row Level Security (RLS)**: Users can only access their own data
- **Automatic timestamps**: `updated_at` is automatically updated on record changes
- **Cascading deletes**: Deleting a conversation also deletes its messages
- **User isolation**: All tables include `user_id` for multi-user support
- **Soft delete support**: Includes `last_synced` columns for sync tracking

## Setup Instructions

### Prerequisites

1. Install Supabase CLI:
   ```bash
   npm install -g supabase
   ```

2. Create a Supabase project at https://supabase.com

### Local Development

1. Initialize Supabase locally:
   ```bash
   supabase init
   ```

2. Start local Supabase services:
   ```bash
   supabase start
   ```

3. Apply migrations:
   ```bash
   supabase db reset
   ```

4. Access local Studio at http://localhost:54323

### Production Deployment

1. Link your Supabase project:
   ```bash
   supabase link --project-ref YOUR_PROJECT_REF
   ```

2. Push migrations to production:
   ```bash
   supabase db push
   ```

3. Update your Flutter app's `.env` file with production credentials:
   ```
   SUPABASE_URL=your_production_url
   SUPABASE_ANON_KEY=your_production_anon_key
   ```

## Migrations

### Migration Files

1. **20260208000000_initial_schema.sql** - Initial database schema for new installations
   - All tables (matches, conversations, messages)
   - Indexes for performance
   - Row Level Security policies
   - Automatic timestamp triggers
   - Documentation comments

2. **20260208000001_upgrade_from_legacy.sql** - Upgrade script for existing databases
   - Migrates from old `supabase_migrations.sql` schema to v11
   - Adds new columns (court_speed, altitude, crowd, etc.)
   - Converts BIGINT timestamps to TIMESTAMPTZ
   - Converts is_error from INTEGER to BOOLEAN
   - Migrates legacy data values (Clay → Red clay)
   - Renames synced_at to last_synced
   - Makes user_id and match_date nullable
   - Updates triggers and indexes

3. **20260208000002_validate_schema.sql** - Validation script (optional)
   - Checks all columns exist
   - Verifies data types are correct
   - Confirms legacy values have been migrated
   - Reports missing indexes or policies
   - Safe to run anytime (read-only queries)

### Migration Paths

**For new installations:**
```bash
supabase db reset
```
This will apply `20260208000000_initial_schema.sql` and create a fresh database.

**For existing databases (upgrading from supabase_migrations.sql):**
```bash
supabase db push
```
This will apply both migrations in order:
1. Initial schema (will skip existing tables)
2. Upgrade script (will add columns and migrate data)

**Manual upgrade (if using Supabase dashboard):**
1. Open your Supabase project
2. Go to SQL Editor
3. Run `20260208000001_upgrade_from_legacy.sql`
4. Wait for completion (should take a few seconds even with lots of data)

**Validating the migration:**
After upgrading, you can verify everything migrated correctly:
```bash
# Using Supabase CLI
supabase db push --dry-run  # Check for drift

# Or run validation script in SQL Editor
# Copy and run: supabase/migrations/20260208000002_validate_schema.sql
```

The validation script will check:
- ✓ All required columns exist
- ✓ Data types are correct (TIMESTAMPTZ, BOOLEAN)
- ✓ Legacy values migrated (Clay → Red clay)
- ✓ Triggers and indexes are in place
- ✓ RLS policies are active

## Field Values

### Court Surface
- Red clay
- Green clay
- Hard
- Grass
- Carpet

### Court Speed (surface-dependent)
- **Clay (Red/Green)**: Slow, Slow-Medium
- **Hard**: Medium, Medium-Fast
- **Grass/Carpet**: Fast

### Court Cover
- Outdoor
- Bubble
- Fabric
- Retractable
- Indoor

### Court Conditions
- Hot-dry
- Hot-humid
- Mild
- Cold-dry
- Cold-humid
- Windy
- Rain

### Altitude
- Low (0-1,000m/0-3,300ft)
- Mid (1,000-1,500m/3,300-5,000ft)
- High (1,500+m/5,000+ft)

### Crowd
- No crowd
- Neutral
- Respectful
- Friendly
- Hostile
- Divided
- Disruptive

### Match Type
- Singles
- Doubles

## Security

All tables have Row Level Security enabled. Users can only:
- View their own data
- Insert records tied to their user ID
- Update their own records
- Delete their own records

## Sync Strategy (Future Enhancement)

When implementing cloud sync:
1. Use `last_synced` timestamp to track sync status
2. Sync local SQLite to Supabase on user login
3. Handle conflicts with "last write wins" or custom logic
4. Support offline-first with eventual consistency

## Development Notes

- UUIDs are used for primary keys (compatible with Supabase)
- Timestamps use TIMESTAMPTZ for proper timezone handling
- Foreign key constraints ensure data integrity
- Indexes are optimized for common query patterns (user_id, dates)
