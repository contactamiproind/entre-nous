-- Link the 4 existing questions to Orientation pathway levels
-- Based on the question data shown

-- Question 1: "Single Tap Choice" → Level 1 (Easy)
UPDATE questions
SET level_id = '96deb175-cd50-49bb-a1ba-9e8bc5d8415e'
WHERE id = '9ba72b33-ce81-44d9-8a93-c4ec2cdd25a7';

-- Question 2: "Single Tap Choice" → Level 2 (Mid)
UPDATE questions
SET level_id = '26441bc8-e436-46d1-9588-2b9dd4aff8e2'
WHERE id = '28c7f67c-5f45-49a2-8636-2329120e4039';

-- Question 3: "Card Match" → Level 3 (Hard)
UPDATE questions
SET level_id = 'bc61ee98-1541-41f9-ab87-eb8718b454e5'
WHERE id = 'a815eee1-c8e9-4571-8596-7580cc75d4e0';

-- Question 4: "Single Tap Choice" → Level 4 (Extreme)
UPDATE questions
SET level_id = '9119b3f5-e1cb-4d84-ac77-27c65630bc14'
WHERE id = '55ac757a-a395-454e-b0b3-d04325eafae7';

-- Verify the links were created
SELECT 
  q.id,
  q.title as question_title,
  dl.level_number,
  dl.title as level_title
FROM questions q
JOIN dept_levels dl ON q.level_id = dl.level_id
WHERE dl.dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY dl.level_number;
