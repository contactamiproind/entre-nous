-- Add tracking columns to user_pathway table
-- Track who assigned the pathway and when user last worked on it

-- Step 1: Add assigned_by column (admin who assigned this pathway)
ALTER TABLE user_pathway 
ADD COLUMN IF NOT EXISTS assigned_by UUID REFERENCES profiles(user_id);

-- Step 2: Add last_accessed_at column (when user last worked on this pathway)
ALTER TABLE user_pathway 
ADD COLUMN IF NOT EXISTS last_accessed_at TIMESTAMP WITH TIME ZONE;

-- Step 3: Set initial last_accessed_at to enrolled_at for existing records
UPDATE user_pathway
SET last_accessed_at = enrolled_at
WHERE last_accessed_at IS NULL;

-- Step 4: Create function to auto-update last_accessed_at
CREATE OR REPLACE FUNCTION update_pathway_last_accessed()
RETURNS TRIGGER AS $$
BEGIN
  -- Update last_accessed_at when user_progress is updated for this pathway
  UPDATE user_pathway
  SET last_accessed_at = NOW()
  WHERE user_id = NEW.user_id
  AND pathway_id = NEW.pathway_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 5: Create trigger on user_progress to update last_accessed_at
DROP TRIGGER IF EXISTS update_last_accessed_trigger ON user_progress;
CREATE TRIGGER update_last_accessed_trigger
  AFTER UPDATE ON user_progress
  FOR EACH ROW
  EXECUTE FUNCTION update_pathway_last_accessed();

-- Step 6: Add comments for documentation
COMMENT ON COLUMN user_pathway.assigned_by IS 'Admin user who assigned this pathway (NULL if self-enrolled)';
COMMENT ON COLUMN user_pathway.last_accessed_at IS 'Last time user worked on this pathway (updated when progress changes)';

-- Verification
SELECT 
  'USER_PATHWAY COLUMNS' as check_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'user_pathway'
ORDER BY ordinal_position;

-- Sample data
SELECT 
  user_id,
  pathway_name,
  enrolled_at,
  assigned_by,
  last_accessed_at,
  is_current
FROM user_pathway
LIMIT 5;
