-- Show complete diagnostic

-- 1. User's current department
SELECT 
  'USER DEPARTMENT' as info,
  d.id,
  d.title
FROM user_pathway upw
JOIN auth.users u ON u.id = upw.user_id
JOIN departments d ON d.id = upw.pathway_id
WHERE u.email = 'contactamiproind@gmail.com' AND upw.is_current = true;

-- 2. Where are the Single Tap Choice questions?
SELECT 
  'SINGLE TAP CHOICE LOCATION' as info,
  q.id,
  q.level_id,
  dl.level_number,
  dl.dept_id,
  d.title as department
FROM questions q
JOIN dept_levels dl ON dl.id = q.level_id
JOIN departments d ON d.id = dl.dept_id
WHERE q.title = 'Single Tap Choice'
LIMIT 1;

-- 3. Where is the Card Match question?
SELECT 
  'CARD MATCH LOCATION' as info,
  q.id,
  q.level_id,
  dl.level_number,
  dl.dept_id,
  d.title as department
FROM questions q
JOIN dept_levels dl ON dl.id = q.level_id
JOIN departments d ON d.id = dl.dept_id
WHERE q.title = 'Card Match';

-- 4. Reassign user to the department that has BOTH questions
UPDATE user_pathway
SET pathway_id = (
  SELECT DISTINCT dl.dept_id
  FROM questions q
  JOIN dept_levels dl ON dl.id = q.level_id
  WHERE q.title = 'Single Tap Choice'
  LIMIT 1
)
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'contactamiproind@gmail.com')
  AND is_current = true;

-- 5. Verify the fix
SELECT 
  'AFTER REASSIGNMENT' as info,
  u.email,
  d.title as department,
  COUNT(q.id) as question_count
FROM user_pathway upw
JOIN auth.users u ON u.id = upw.user_id
JOIN departments d ON d.id = upw.pathway_id
JOIN dept_levels dl ON dl.dept_id = d.id
JOIN questions q ON q.level_id = dl.id
WHERE u.email = 'contactamiproind@gmail.com' AND upw.is_current = true
GROUP BY u.email, d.title;
