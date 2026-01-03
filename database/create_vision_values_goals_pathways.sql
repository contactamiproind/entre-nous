-- SIMPLIFIED VERSION: Update questions by description instead of ID
-- This avoids UUID typo issues

-- Step 1: Create departments (same as before)
INSERT INTO departments (id, title, description, created_at, updated_at)
SELECT gen_random_uuid(), 'Vision', 'Vision pathway - Creating ease for clients', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM departments WHERE title = 'Vision');

INSERT INTO departments (id, title, description, created_at, updated_at)
SELECT gen_random_uuid(), 'Values', 'Values pathway - Value-aligned actions', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM departments WHERE title = 'Values');

INSERT INTO departments (id, title, description, created_at, updated_at)
SELECT gen_random_uuid(), 'Goals', 'Goals pathway - Supporting our goals', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM departments WHERE title = 'Goals');

-- Step 2: Create levels for each department

-- Values: Easy
INSERT INTO dept_levels (id, dept_id, level_id, title, level_number, created_at, updated_at)
SELECT 
  gen_random_uuid(),
  (SELECT id FROM departments WHERE title = 'Values'),
  gen_random_uuid(),
  'Easy',
  1,
  NOW(),
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM dept_levels dl
  JOIN departments d ON dl.dept_id = d.id
  WHERE d.title = 'Values' AND dl.level_number = 1
);

-- Goals: Easy
INSERT INTO dept_levels (id, dept_id, level_id, title, level_number, created_at, updated_at)
SELECT 
  gen_random_uuid(),
  (SELECT id FROM departments WHERE title = 'Goals'),
  gen_random_uuid(),
  'Easy',
  1,
  NOW(),
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM dept_levels dl
  JOIN departments d ON dl.dept_id = d.id
  WHERE d.title = 'Goals' AND dl.level_number = 1
);

-- Vision: Easy
INSERT INTO dept_levels (id, dept_id, level_id, title, level_number, created_at, updated_at)
SELECT 
  gen_random_uuid(),
  (SELECT id FROM departments WHERE title = 'Vision'),
  gen_random_uuid(),
  'Easy',
  1,
  NOW(),
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM dept_levels dl
  JOIN departments d ON dl.dept_id = d.id
  WHERE d.title = 'Vision' AND dl.level_number = 1
);

-- Vision: Mid
INSERT INTO dept_levels (id, dept_id, level_id, title, level_number, created_at, updated_at)
SELECT 
  gen_random_uuid(),
  (SELECT id FROM departments WHERE title = 'Vision'),
  gen_random_uuid(),
  'Mid',
  2,
  NOW(),
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM dept_levels dl
  JOIN departments d ON dl.dept_id = d.id
  WHERE d.title = 'Vision' AND dl.level_number = 2
);

-- Step 3: Update questions by matching description text

-- Question: "Choose the most value-aligned action" → Values/Easy
UPDATE questions
SET level_id = (
  SELECT dl.id 
  FROM dept_levels dl 
  JOIN departments d ON dl.dept_id = d.id 
  WHERE d.title = 'Values' AND dl.level_number = 1
)
WHERE description LIKE '%value-aligned%';

-- Question: "Pick the action that supports our goals" → Goals/Easy
UPDATE questions
SET level_id = (
  SELECT dl.id 
  FROM dept_levels dl 
  JOIN departments d ON dl.dept_id = d.id 
  WHERE d.title = 'Goals' AND dl.level_number = 1
)
WHERE description LIKE '%supports our goals%';

-- Question: "Which action best creates Ease for a client" → Vision/Easy
UPDATE questions
SET level_id = (
  SELECT dl.id 
  FROM dept_levels dl 
  JOIN departments d ON dl.dept_id = d.id 
  WHERE d.title = 'Vision' AND dl.level_number = 1
)
WHERE description LIKE '%creates Ease%';

-- Question: "Ease vs Delight" → Vision/Mid
UPDATE questions
SET level_id = (
  SELECT dl.id 
  FROM dept_levels dl 
  JOIN departments d ON dl.dept_id = d.id 
  WHERE d.title = 'Vision' AND dl.level_number = 2
)
WHERE description LIKE '%Ease vs Delight%';

-- Step 4: Verify the distribution
SELECT 
  q.description as question,
  d.title as department,
  dl.title as level,
  dl.level_number,
  q.difficulty
FROM questions q
JOIN dept_levels dl ON q.level_id = dl.id
JOIN departments d ON dl.dept_id = d.id
WHERE d.title IN ('Vision', 'Values', 'Goals')
ORDER BY d.title, dl.level_number;
