-- Step 1: Add new integer level column
ALTER TABLE questions 
ADD COLUMN level_new INTEGER DEFAULT 1;

-- Step 2: Migrate data from difficulty to level_new
UPDATE questions 
SET level_new = CASE 
  WHEN LOWER(difficulty) = 'easy' THEN 1
  WHEN LOWER(difficulty) = 'medium' OR LOWER(difficulty) = 'mid' THEN 2
  WHEN LOWER(difficulty) = 'hard' THEN 3
  ELSE 1
END;

-- Step 3: Drop old difficulty column
ALTER TABLE questions 
DROP COLUMN difficulty;

-- Step 4: Rename level_new to level
ALTER TABLE questions 
RENAME COLUMN level_new TO level;

-- Step 5: Add constraint to ensure level is between 1 and 4
ALTER TABLE questions 
ADD CONSTRAINT level_range CHECK (level >= 1 AND level <= 4);

-- Step 6: Add comment
COMMENT ON COLUMN questions.level IS 'Question difficulty level: 1 (Easy), 2 (Medium), 3 (Hard), 4 (Expert)';

-- Step 7: Set all existing users to level 1
UPDATE profiles 
SET level = 1 
WHERE level IS NULL OR level != 1;

-- Step 8: Add default constraint for new users
ALTER TABLE profiles 
ALTER COLUMN level SET DEFAULT 1;

-- Verification queries
SELECT 'Questions by level:' as info;
SELECT level, COUNT(*) as count FROM questions GROUP BY level ORDER BY level;

SELECT 'Users by level:' as info;
SELECT level, COUNT(*) as count FROM profiles GROUP BY level ORDER BY level;
