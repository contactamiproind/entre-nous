-- Comprehensive cleanup: Move all references from standalone to Orientation versions

-- Get the department IDs we'll be working with
WITH dept_mapping AS (
  SELECT 
    d_standalone.id as standalone_id,
    d_standalone.title as standalone_title,
    d_orientation.id as orientation_id,
    d_orientation.title as orientation_title
  FROM departments d_standalone
  JOIN departments d_orientation ON d_orientation.title = 'Orientation - ' || d_standalone.title
  WHERE d_standalone.title IN ('Vision', 'Goals', 'Values')
)
SELECT * FROM dept_mapping;

-- STEP 1: Update user_pathway references
UPDATE user_pathway
SET pathway_id = (SELECT id FROM departments WHERE title = 'Orientation - Vision')
WHERE pathway_id = (SELECT id FROM departments WHERE title = 'Vision');

UPDATE user_pathway
SET pathway_id = (SELECT id FROM departments WHERE title = 'Orientation - Goals')
WHERE pathway_id = (SELECT id FROM departments WHERE title = 'Goals');

UPDATE user_pathway
SET pathway_id = (SELECT id FROM departments WHERE title = 'Orientation - Values')
WHERE pathway_id = (SELECT id FROM departments WHERE title = 'Values');

-- STEP 2: Update usr_stat references
UPDATE usr_stat
SET department_id = (SELECT id FROM departments WHERE title = 'Orientation - Vision')
WHERE department_id = (SELECT id FROM departments WHERE title = 'Vision');

UPDATE usr_stat
SET department_id = (SELECT id FROM departments WHERE title = 'Orientation - Goals')
WHERE department_id = (SELECT id FROM departments WHERE title = 'Goals');

UPDATE usr_stat
SET department_id = (SELECT id FROM departments WHERE title = 'Orientation - Values')
WHERE department_id = (SELECT id FROM departments WHERE title = 'Values');

-- STEP 3: Update questions dept_id references
UPDATE questions
SET dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Vision')
WHERE dept_id = (SELECT id FROM departments WHERE title = 'Vision');

UPDATE questions
SET dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Goals')
WHERE dept_id = (SELECT id FROM departments WHERE title = 'Goals');

UPDATE questions
SET dept_id = (SELECT id FROM departments WHERE title = 'Orientation - Values')
WHERE dept_id = (SELECT id FROM departments WHERE title = 'Values');

-- STEP 4: Update questions orientation_id references (if any)
UPDATE questions
SET orientation_id = (SELECT id FROM departments WHERE title = 'Orientation - Vision')
WHERE orientation_id = (SELECT id FROM departments WHERE title = 'Vision');

UPDATE questions
SET orientation_id = (SELECT id FROM departments WHERE title = 'Orientation - Goals')
WHERE orientation_id = (SELECT id FROM departments WHERE title = 'Goals');

UPDATE questions
SET orientation_id = (SELECT id FROM departments WHERE title = 'Orientation - Values')
WHERE orientation_id = (SELECT id FROM departments WHERE title = 'Values');

-- STEP 5: Delete dept_levels for standalone departments
DELETE FROM dept_levels
WHERE dept_id IN (SELECT id FROM departments WHERE title IN ('Vision', 'Goals', 'Values'));

-- STEP 6: Finally, delete standalone duplicate departments
DELETE FROM departments
WHERE title IN ('Vision', 'Goals', 'Values');

-- STEP 7: Verify cleanup
SELECT 
  'REMAINING DEPARTMENTS' as info,
  title,
  (SELECT COUNT(*) FROM user_pathway WHERE pathway_id = departments.id) as user_pathway_count,
  (SELECT COUNT(*) FROM usr_stat WHERE department_id = departments.id) as usr_stat_count,
  (SELECT COUNT(*) FROM dept_levels WHERE dept_id = departments.id) as level_count,
  (SELECT COUNT(*) FROM questions WHERE dept_id = departments.id) as question_count
FROM departments
WHERE title LIKE '%Vision%' OR title LIKE '%Goals%' OR title LIKE '%Values%'
ORDER BY title;
