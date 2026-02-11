-- ============================================
-- RUN THIS MIGRATION FIRST
-- ============================================
-- This adds completion tracking to end_game_assignments
-- Required for level progression system to work
-- ============================================

-- Add completion tracking columns to end_game_assignments
ALTER TABLE end_game_assignments
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS score INTEGER DEFAULT 0;

-- Comment on columns
COMMENT ON COLUMN end_game_assignments.completed_at IS 'Timestamp when the user successfully completed the End Game';
COMMENT ON COLUMN end_game_assignments.score IS 'Score achieved in the End Game';

-- Verify the migration
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns
WHERE table_name = 'end_game_assignments'
ORDER BY ordinal_position;
