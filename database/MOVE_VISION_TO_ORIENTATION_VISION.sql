-- Move Vision questions to ACTUAL Orientation-Vision level IDs

-- Update Single Tap Choice (Ease question) to Orientation-Vision Easy level
UPDATE questions
SET level_id = '8dd3422b-4714-428b-9a8b-bd05b6820683',
    dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
WHERE title = 'Single Tap Choice'
  AND description LIKE '%Ease%';

-- Update Card Match to Orientation-Vision Mid level
UPDATE questions
SET level_id = '760edfbb-949b-482f-b06d-1c606599a99a2',
    dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
WHERE title = 'Card Match'
  AND description LIKE '%Ease%';

-- Verify the updates
SELECT 
  'AFTER UPDATE - VISION QUESTIONS' as info,
  q.title,
  q.description,
  q.level_id,
  dl.title as level_name,
  d.title as department
FROM questions q
JOIN dept_levels dl ON dl.id = q.level_id
JOIN departments d ON d.id = dl.dept_id
WHERE q.title IN ('Single Tap Choice', 'Card Match')
  AND q.description LIKE '%Ease%'
ORDER BY dl.level_number;
