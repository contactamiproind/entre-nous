-- COMPREHENSIVE DATABASE FIX
-- This script fixes all data inconsistencies in one go

-- ============================================
-- STEP 1: Sync all departments' JSONB with dept_levels
-- ============================================

-- Update each department's levels JSONB to match dept_levels table
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
-- STEP 2: Verify all questions have valid level_id
-- ============================================

-- Show questions with invalid level_id (orphaned questions)
SELECT 
  'ORPHANED QUESTIONS' as issue,
  q.id,
  q.title,
  q.level_id as invalid_level_id
FROM questions q
LEFT JOIN dept_levels dl ON q.level_id = dl.id
WHERE dl.id IS NULL;

-- ============================================
-- STEP 3: Show summary of all departments and their questions
-- ============================================

SELECT 
  'DEPARTMENT SUMMARY' as info,
  d.title as department,
  COUNT(DISTINCT dl.id) as level_count,
  COUNT(q.id) as question_count
FROM departments d
LEFT JOIN dept_levels dl ON dl.dept_id = d.id
LEFT JOIN questions q ON q.level_id = dl.id
GROUP BY d.id, d.title
ORDER BY d.title;

-- ============================================
-- STEP 4: Verify JSONB matches dept_levels
-- ============================================

SELECT 
  'JSONB SYNC CHECK' as info,
  d.title as department,
  jsonb_array_length(d.levels) as jsonb_level_count,
  COUNT(dl.id) as actual_level_count,
  CASE 
    WHEN jsonb_array_length(d.levels) = COUNT(dl.id) THEN 'SYNCED ✓'
    ELSE 'MISMATCH ✗'
  END as status
FROM departments d
LEFT JOIN dept_levels dl ON dl.dept_id = d.id
GROUP BY d.id, d.title, d.levels
ORDER BY d.title;
