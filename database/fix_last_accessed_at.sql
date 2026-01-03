-- Fix last_accessed_at column in user_pathway
-- Run this in Supabase SQL Editor

-- Step 1: Set initial value for existing records
-- Set last_accessed_at to enrolled_at for records where it's NULL
UPDATE user_pathway
SET last_accessed_at = enrolled_at
WHERE last_accessed_at IS NULL;

-- Step 2: Create trigger to auto-update last_accessed_at
-- This trigger will update last_accessed_at whenever the record is updated
CREATE OR REPLACE FUNCTION update_last_accessed_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_accessed_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists
DROP TRIGGER IF EXISTS trigger_update_last_accessed_at ON user_pathway;

-- Create trigger
CREATE TRIGGER trigger_update_last_accessed_at
  BEFORE UPDATE ON user_pathway
  FOR EACH ROW
  EXECUTE FUNCTION update_last_accessed_at();

-- Step 3: Verify the fix
SELECT 
  'user_pathway with last_accessed_at' as info,
  pathway_name,
  enrolled_at,
  last_accessed_at,
  assigned_at
FROM user_pathway
ORDER BY enrolled_at DESC;
