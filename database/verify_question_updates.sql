-- Check if the updates actually happened
SELECT id, title, level_id
FROM questions
WHERE id IN (
  '9ba72b33-ce81-44d9-8a93-c4ec2cdd25a7',
  '28c7f67c-5f45-49a2-8636-2329120e4039',
  'a815eee1-c8e9-4571-8596-7580cc75d4e0',
  '55ac757a-a395-454e-b0b3-d04325eafae7'
);

-- Check what level_ids these questions now have
-- They should match the Orientation level_ids:
-- 96deb175-cd50-49bb-a1ba-9e8bc5d8415e (Level 1)
-- 26441bc8-e436-46d1-9588-2b9dd4aff8e2 (Level 2)
-- bc61ee98-1541-41f9-ab87-eb8718b454e5 (Level 3)
-- 9119b3f5-e1cb-4d84-ac77-27c65630bc14 (Level 4)
