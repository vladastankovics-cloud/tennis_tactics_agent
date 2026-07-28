-- ============================================================================
-- Add ai_tactics table for AI-generated tactical suggestions
-- ============================================================================
-- Stores tactics extracted from AI conversation responses
-- Allows users to mark tactics as successful/unsuccessful
-- ============================================================================

-- Create ai_tactics table
CREATE TABLE IF NOT EXISTS ai_tactics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  match_id UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  short_name TEXT NOT NULL,
  description TEXT NOT NULL,
  outcome TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_ai_tactics_user_id ON ai_tactics(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_tactics_match_id ON ai_tactics(match_id);
CREATE INDEX IF NOT EXISTS idx_ai_tactics_conversation_id ON ai_tactics(conversation_id);
CREATE INDEX IF NOT EXISTS idx_ai_tactics_created_at ON ai_tactics(created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE ai_tactics ENABLE ROW LEVEL SECURITY;

-- RLS Policies for ai_tactics
CREATE POLICY "Users can view their own ai_tactics"
  ON ai_tactics FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own ai_tactics"
  ON ai_tactics FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own ai_tactics"
  ON ai_tactics FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own ai_tactics"
  ON ai_tactics FOR DELETE
  USING (auth.uid() = user_id);

-- Add comments
COMMENT ON TABLE ai_tactics IS 'AI-generated tactical suggestions extracted from conversation responses';
COMMENT ON COLUMN ai_tactics.outcome IS 'Outcome of the tactic: null (pending), successful, or unsuccessful';
COMMENT ON COLUMN ai_tactics.short_name IS 'Short name/title of the tactic';
COMMENT ON COLUMN ai_tactics.description IS 'Full description of the tactic';
