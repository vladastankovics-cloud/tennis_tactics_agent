-- Add my_adjustment and opponent_adjustment columns to matches table
ALTER TABLE matches ADD COLUMN IF NOT EXISTS my_adjustment TEXT;
ALTER TABLE matches ADD COLUMN IF NOT EXISTS opponent_adjustment TEXT;
