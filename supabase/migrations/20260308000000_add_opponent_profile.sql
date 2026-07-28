-- Add profile fields to opponents table
ALTER TABLE opponents ADD COLUMN IF NOT EXISTS birth_year INTEGER;
ALTER TABLE opponents ADD COLUMN IF NOT EXISTS height_cm INTEGER;
ALTER TABLE opponents ADD COLUMN IF NOT EXISTS weight_kg REAL;
ALTER TABLE opponents ADD COLUMN IF NOT EXISTS years_active TEXT;
ALTER TABLE opponents ADD COLUMN IF NOT EXISTS hands TEXT;
ALTER TABLE opponents ADD COLUMN IF NOT EXISTS backhand_type TEXT;
