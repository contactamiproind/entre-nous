-- STEP 2: Add constraints and triggers
-- Run this AFTER cleaning up duplicates

-- ============================================
-- 1. Add unique constraint (if not exists)
-- ============================================
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'unique_dept_level'
  ) THEN
    ALTER TABLE dept_levels 
    ADD CONSTRAINT unique_dept_level 
    UNIQUE (dept_id, level_number);
  END IF;
END $$;

-- ============================================
-- 2. Add check constraint for positive level numbers
-- ============================================
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'positive_level_number'
  ) THEN
    ALTER TABLE dept_levels 
    ADD CONSTRAINT positive_level_number 
    CHECK (level_number > 0);
  END IF;
END $$;

-- ============================================
-- 3. Create auto-sync trigger for JSONB
-- ============================================
CREATE OR REPLACE FUNCTION sync_department_levels()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE departments
  SET levels = (
    SELECT jsonb_agg(
      jsonb_build_object(
        'id', dl.id,
        'title', dl.title,
        'level_number', dl.level_number,
        'category', dl.category,
        'created_at', dl.created_at,
        'updated_at', dl.updated_at
      ) ORDER BY dl.level_number
    )
    FROM dept_levels dl
    WHERE dl.dept_id = COALESCE(NEW.dept_id, OLD.dept_id)
  )
  WHERE id = COALESCE(NEW.dept_id, OLD.dept_id);
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS sync_levels_after_change ON dept_levels;

CREATE TRIGGER sync_levels_after_change
AFTER INSERT OR UPDATE OR DELETE ON dept_levels
FOR EACH ROW
EXECUTE FUNCTION sync_department_levels();

-- ============================================
-- 4. Sync all departments' JSONB (one-time)
-- ============================================
UPDATE departments d
SET levels = (
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', dl.id,
      'title', dl.title,
      'level_number', dl.level_number,
      'category', dl.category,
      'created_at', dl.created_at,
      'updated_at', dl.updated_at
    ) ORDER BY dl.level_number
  )
  FROM dept_levels dl
  WHERE dl.dept_id = d.id
)
WHERE EXISTS (
  SELECT 1 FROM dept_levels WHERE dept_id = d.id
);

-- ============================================
-- 5. Verify everything is working
-- ============================================
SELECT 
  'FINAL VERIFICATION' as info,
  d.title as department,
  jsonb_array_length(d.levels) as jsonb_count,
  COUNT(dl.id) as actual_count,
  CASE 
    WHEN jsonb_array_length(d.levels) = COUNT(dl.id) THEN 'SYNCED ✓'
    ELSE 'MISMATCH ✗'
  END as status
FROM departments d
LEFT JOIN dept_levels dl ON dl.dept_id = d.id
GROUP BY d.id, d.title, d.levels
ORDER BY d.title;
