-- Convert to Admin-Only Pathway Assignment System
-- This migration makes assigned_by required and adds tracking

-- Step 0: Create columns if they don't exist
ALTER TABLE user_pathway 
ADD COLUMN IF NOT EXISTS assigned_by UUID REFERENCES profiles(user_id);

ALTER TABLE user_pathway 
ADD COLUMN IF NOT EXISTS last_accessed_at TIMESTAMP WITH TIME ZONE;

-- Step 1: Add assigned_at column
ALTER TABLE user_pathway 
ADD COLUMN IF NOT EXISTS assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Step 2: Set assigned_at to enrolled_at for existing records
UPDATE user_pathway
SET assigned_at = enrolled_at
WHERE assigned_at IS NULL;

-- Step 3: Set assigned_by for existing records (use first admin)
UPDATE user_pathway
SET assigned_by = (
  SELECT user_id FROM profiles WHERE role = 'admin' LIMIT 1
)
WHERE assigned_by IS NULL;

-- Step 4: Make assigned_by NOT NULL (required)
ALTER TABLE user_pathway 
ALTER COLUMN assigned_by SET NOT NULL;

-- Step 5: Rename enrolled_at to assigned_at for clarity
-- (Keep both for now, will deprecate enrolled_at later)

-- Step 6: Add index for faster queries
CREATE INDEX IF NOT EXISTS idx_user_pathway_assigned_by 
ON user_pathway(assigned_by);

-- Step 7: Add comments
COMMENT ON COLUMN user_pathway.assigned_by IS 'Admin who assigned this pathway to the user (required)';
COMMENT ON COLUMN user_pathway.assigned_at IS 'When the admin assigned this pathway';
COMMENT ON COLUMN user_pathway.last_accessed_at IS 'Last time user worked on this pathway';

-- Verification
SELECT 
  'USER_PATHWAY SCHEMA' as check_name,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'user_pathway'
ORDER BY ordinal_position;

-- Sample data with admin info
SELECT 
  up.user_id,
  up.pathway_name,
  up.assigned_at,
  admin.email as assigned_by_admin,
  up.last_accessed_at,
  up.is_current
FROM user_pathway up
LEFT JOIN profiles admin ON up.assigned_by = admin.user_id
LIMIT 5;
