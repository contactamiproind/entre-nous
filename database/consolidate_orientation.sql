-- ============================================
-- Consolidate Orientation Departments
-- ============================================
-- This script consolidates all Orientation subcategories
-- into a single Orientation department

-- Step 1: Check current Orientation departments
SELECT 
  id,
  title,
  category,
  subcategory,
  description
FROM departments
WHERE category = 'Orientation'
ORDER BY subcategory;

-- Step 2: Count questions per Orientation department
SELECT 
  d.title,
  d.category,
  d.subcategory,
  COUNT(q.id) as question_count
FROM departments d
LEFT JOIN questions q ON q.dept_id = d.id
WHERE d.category = 'Orientation'
GROUP BY d.id, d.title, d.category, d.subcategory
ORDER BY d.subcategory;

-- Step 3: Consolidate all Orientation departments
DO $$
DECLARE
  orientation_dept_id uuid;
  old_dept_ids uuid[];
BEGIN
  -- Check if a main Orientation department already exists
  SELECT id INTO orientation_dept_id
  FROM departments
  WHERE title = 'Orientation' AND category = 'Orientation' AND subcategory IS NULL
  LIMIT 1;

  -- If it doesn't exist, create it
  IF orientation_dept_id IS NULL THEN
    INSERT INTO departments (title, category, subcategory, description, created_at, updated_at)
    VALUES (
      'Orientation',
      'Orientation',
      NULL,
      'Core company values and culture',
      NOW(),
      NOW()
    )
    RETURNING id INTO orientation_dept_id;
    
    RAISE NOTICE 'Created new Orientation department with ID: %', orientation_dept_id;
  ELSE
    RAISE NOTICE 'Using existing Orientation department with ID: %', orientation_dept_id;
  END IF;

  -- Get all old Orientation department IDs (excluding the main one)
  SELECT ARRAY_AGG(id) INTO old_dept_ids
  FROM departments
  WHERE category = 'Orientation' AND id != orientation_dept_id;

  -- Update all questions from old departments to the new one
  IF old_dept_ids IS NOT NULL THEN
    UPDATE questions
    SET 
      dept_id = orientation_dept_id,
      updated_at = NOW()
    WHERE dept_id = ANY(old_dept_ids);
    
    RAISE NOTICE 'Updated questions from % old departments', array_length(old_dept_ids, 1);
  END IF;

  -- Delete all other Orientation departments
  DELETE FROM departments
  WHERE category = 'Orientation' 
    AND id != orientation_dept_id;
    
  RAISE NOTICE 'Consolidation complete! Total questions under Orientation: %', 
    (SELECT COUNT(*) FROM questions WHERE dept_id = orientation_dept_id);
END $$;

-- Step 4: Verify the changes - should show only ONE Orientation department
SELECT 
  id,
  title,
  category,
  subcategory,
  description
FROM departments
WHERE category = 'Orientation';

-- Step 5: Verify questions - count how many questions are now under Orientation
SELECT 
  d.title as department,
  d.category,
  COUNT(q.id) as question_count
FROM departments d
LEFT JOIN questions q ON q.dept_id = d.id
WHERE d.category = 'Orientation'
GROUP BY d.id, d.title, d.category;

-- Step 6: Show sample questions
SELECT 
  q.id,
  q.title,
  q.description,
  d.title as department_title
FROM questions q
JOIN departments d ON q.dept_id = d.id
WHERE d.category = 'Orientation'
LIMIT 10;
