-- Create a function that runs with SECURITY DEFINER to bypass RLS
CREATE OR REPLACE FUNCTION update_question_levels()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Link 3 Easy questions to Level 1
  UPDATE questions
  SET level_id = '96deb175-cd50-49bb-a1ba-9e8bc5d8415e'
  WHERE id IN (
    '28c7f67c-5f45-49a2-8636-2329120e4039',
    '9ba72b33-ce81-44d9-8a93-c4ec2cdd25a7',
    '55ac757a-a395-454e-b0b3-d04325eafae7'
  );
  
  -- Link 1 Mid question to Level 2
  UPDATE questions
  SET level_id = '26441bc8-e436-46d1-9588-2b9dd4aff8e2'
  WHERE id = 'a815eee1-c8e9-4571-8596-7580cc75d4e0';
  
  RAISE NOTICE 'Updated % questions', (SELECT COUNT(*) FROM questions WHERE level_id IN ('96deb175-cd50-49bb-a1ba-9e8bc5d8415e', '26441bc8-e436-46d1-9588-2b9dd4aff8e2'));
END;
$$;

-- Run the function
SELECT update_question_levels();

-- Verify the updates
SELECT id, title, level_id
FROM questions
WHERE level_id IN (
  '96deb175-cd50-49bb-a1ba-9e8bc5d8415e',
  '26441bc8-e436-46d1-9588-2b9dd4aff8e2'
);
