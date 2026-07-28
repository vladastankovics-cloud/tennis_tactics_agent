# Supabase Quick Start Guide

## Choose Your Path

### 🆕 New Installation

**You're setting up Supabase for the first time**

```bash
# 1. Initialize Supabase (if not done)
supabase init

# 2. Start local Supabase
supabase start

# 3. Apply migrations
supabase db reset

# 4. Done! Access Studio at http://localhost:54323
```

---

### 🔄 Upgrading Existing Database

**You previously deployed `supabase_migrations.sql`**

```bash
# 1. Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# 2. Push migrations
supabase db push

# 3. Validate (optional)
# Run 20260208000002_validate_schema.sql in SQL Editor

# 4. Done! Your database is upgraded
```

---

### 🔍 Quick Validation

After setup or upgrade, verify your database:

**Option A: Using Supabase CLI**
```bash
supabase db diff  # Should show no pending changes
```

**Option B: Using SQL Editor**
1. Open Supabase Dashboard → SQL Editor
2. Copy contents of `supabase/migrations/20260208000002_validate_schema.sql`
3. Run it
4. Check for ✓ PASS on all checks

---

## Common Commands

```bash
# Start local Supabase
supabase start

# Stop local Supabase
supabase stop

# Reset local database (fresh start)
supabase db reset

# Push migrations to production
supabase db push

# Check for schema drift
supabase db diff

# Generate TypeScript types
supabase gen types typescript --local > lib/types/supabase.ts
```

---

## Configuration

### Update Flutter App

After deploying, update your `.env` file:

```env
# For local development
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your_local_anon_key

# For production
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_production_anon_key
```

Get keys from:
- **Local**: Run `supabase status` after `supabase start`
- **Production**: Supabase Dashboard → Settings → API

---

## What's Included

✅ **Tables**: matches, conversations, messages
✅ **Security**: Row Level Security (users can only see their data)
✅ **Performance**: Indexes on frequently queried columns
✅ **Automation**: Auto-update timestamps, cascading deletes
✅ **Documentation**: Column comments explaining valid values

---

## Next Steps

1. **Test locally**: `supabase start` → test app with local Supabase
2. **Deploy to prod**: `supabase db push` → push to production
3. **Implement sync**: Add cloud sync logic to Flutter app (future)
4. **Enable auth**: Set up user authentication in Supabase dashboard

---

## Need Help?

📖 **Documentation**:
- `supabase/README.md` - Detailed setup guide
- `supabase/UPGRADE.md` - Upgrade instructions
- Migration files - Well-commented SQL scripts

🔗 **External Resources**:
- [Supabase Docs](https://supabase.com/docs)
- [Supabase CLI Docs](https://supabase.com/docs/guides/cli)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)

⚠️ **Troubleshooting**:
- Run validation script to check schema
- Check Supabase logs for errors
- Ensure PostgreSQL 15+ compatibility
- Verify sufficient database permissions
