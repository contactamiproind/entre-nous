-- Simple query to check all questions (no filtering)
SELECT COUNT(*) as total_questions FROM questions;

-- Check questions with the NEW Orientation level_ids
SELECT id, title, level_id
FROM questions
WHERE level_id IN (
  '96deb175-cd50-49bb-a1ba-9e8bc5d8415e',
  '26441bc8-e436-46d1-9588-2b9dd4aff8e2',
  'bc61ee98-1541-41f9-ab87-eb8718b454e5',
  '9119b3f5-e1cb-4d84-ac77-27c65630bc14'
);

-- If this returns 4 rows, the UPDATEs worked!
