-- Add court_name column to matches table
-- This migration adds a court_name field for identifying courts by name
-- The detailed court properties (surface, speed, cover, conditions, altitude) remain for data storage

ALTER TABLE matches ADD COLUMN IF NOT EXISTS court_name TEXT;
