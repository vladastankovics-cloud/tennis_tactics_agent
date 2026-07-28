# Supabase Cloud Sync Setup Guide

This guide will help you set up Supabase cloud sync for the Tennis Tactics Agent app.

## Prerequisites

- A Supabase account (sign up at [supabase.com](https://supabase.com))
- Your Supabase project URL and anon key (already configured in `main.dart`)

## Step 1: Run the SQL Migration

1. Go to your Supabase Dashboard
2. Navigate to **SQL Editor** (in the left sidebar)
3. Click **New query**
4. Copy the entire contents of `supabase_migrations.sql` and paste it into the SQL editor
5. Click **Run** to execute the migration

This will create:
- `matches` table
- `conversations` table
- `messages` table
- Necessary indexes
- Row Level Security (RLS) policies
- Triggers for automatic timestamp updates

## Step 2: Verify Tables Were Created

1. Navigate to **Table Editor** in your Supabase Dashboard
2. You should see three new tables:
   - `matches`
   - `conversations`
   - `messages`

## Step 3: Enable Email Authentication

1. Navigate to **Authentication** > **Providers** in your Supabase Dashboard
2. Make sure **Email** provider is enabled
3. Configure email templates if desired (optional)

## Step 4: Test the Setup

### In the App:

1. Launch the app
2. Go to **Settings** tab
3. Tap on **Sign In**
4. Create a new account with your email
5. Check your email for confirmation (if email confirmation is enabled)
6. Sign in to the app
7. Navigate to **Settings** > **Account & Sync**
8. Tap **Sync Now** to perform your first sync

## Features

### Cloud Sync

The app now supports full bidirectional sync between your device and Supabase cloud:

- **Auto-sync**: Data syncs automatically when you sign in
- **Manual sync**: Use "Sync Now" button in Account screen
- **Pull from Cloud**: Replace local data with cloud data
- **Push to Cloud**: Upload local data to cloud

### Security

- **Row Level Security (RLS)**: Each user can only access their own data
- **User isolation**: Data is tied to your Supabase auth user ID
- **Secure authentication**: Uses Supabase's built-in auth system

### Guest Mode

- Users can use the app without signing in
- All data is stored locally in SQLite
- Sign in anytime to enable cloud sync

## Database Schema

### Matches Table
```sql
CREATE TABLE matches (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  opponent_name TEXT NOT NULL,
  match_date BIGINT NOT NULL,
  match_result TEXT,
  match_score_user INTEGER,
  match_score_opponent INTEGER,
  match_type TEXT,
  court_surface TEXT,
  notes TEXT,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  synced_at TIMESTAMP WITH TIME ZONE
);
```

### Conversations Table
```sql
CREATE TABLE conversations (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  match_id UUID REFERENCES matches(id),
  title TEXT,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  synced_at TIMESTAMP WITH TIME ZONE
);
```

### Messages Table
```sql
CREATE TABLE messages (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  conversation_id UUID REFERENCES conversations(id),
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  timestamp BIGINT NOT NULL,
  is_error INTEGER DEFAULT 0,
  synced_at TIMESTAMP WITH TIME ZONE
);
```

## Troubleshooting

### Error: "User not authenticated"
- Make sure you're signed in to the app
- Check Settings > Account & Sync to verify your sign-in status

### Error: "Permission denied"
- Verify RLS policies are properly set up
- Check that you ran the entire SQL migration script

### Sync not working
1. Check your internet connection
2. Verify Supabase project URL and anon key in `main.dart`
3. Check Supabase Dashboard > Logs for any errors
4. Try signing out and signing back in

### Data not appearing after sync
1. Try "Pull from Cloud" in Account screen
2. Check Table Editor in Supabase Dashboard to verify data exists
3. Ensure you're using the same account on all devices

## Data Migration

If you have existing local data before enabling sync:

1. Sign in to the app
2. Go to Settings > Account & Sync
3. Tap "Push to Cloud" to upload all local data
4. Your existing matches and conversations will be uploaded to Supabase

## Support

For issues related to:
- **Supabase setup**: Check [Supabase Docs](https://supabase.com/docs)
- **App functionality**: Check the main README.md

## Privacy & Data

- All data is stored in YOUR Supabase project
- You have full control over your data
- Data is NOT shared with other users
- You can delete your account and data anytime from Account screen
