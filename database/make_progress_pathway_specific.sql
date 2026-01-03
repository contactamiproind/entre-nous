-- Make user_progress pathway-specific
-- This allows users to have different progress in different pathways

-- Step 1: Add pathway_id column to user_progress
ALTER TABLE user_progress 
ADD COLUMN IF NOT EXISTS pathway_id UUID REFERENCES pathways(id);

-- Step 2: Populate pathway_id for existing records
-- Link existing user_progress to their current pathway from user_pathway
UPDATE user_progress up
SET pathway_id = (
  SELECT pathway_id 
  FROM user_pathway 
  WHERE user_id = up.user_id 
  AND is_current = true 
  LIMIT 1
)
WHERE pathway_id IS NULL;

-- Step 3: Make pathway_id NOT NULL (after populating)
ALTER TABLE user_progress 
ALTER COLUMN pathway_id SET NOT NULL;

-- Step 4: Drop old unique constraint (if exists)
ALTER TABLE user_progress 
DROP CONSTRAINT IF EXISTS user_progress_user_id_key;

-- Step 5: Add new unique constraint for user_id + pathway_id
ALTER TABLE user_progress 
ADD CONSTRAINT user_progress_user_pathway_unique 
UNIQUE (user_id, pathway_id);

-- Step 6: Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_user_progress_pathway 
ON user_progress(user_id, pathway_id);

-- Step 7: Update RLS policies to include pathway_id
DROP POLICY IF EXISTS "Users can view own progress" ON user_progress;
CREATE POLICY "Users can view own progress"
  ON user_progress FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own progress" ON user_progress;
CREATE POLICY "Users can update own progress"
  ON user_progress FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own progress" ON user_progress;
CREATE POLICY "Users can insert own progress"
  ON user_progress FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Verification query
SELECT 
  up.user_id,
  up.pathway_id,
  p.name as pathway_name,
  up.current_level,
  up.current_score
FROM user_progress up
JOIN pathways p ON up.pathway_id = p.id
LIMIT 5;
