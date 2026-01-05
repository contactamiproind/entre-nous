-- Fix is_correct flags in questions.options JSON
-- This script updates the options JSON to mark the correct answer

-- Step 1: First, let's check the current format of options
SELECT 
    id,
    title,
    correct_answer,
    options,
    jsonb_typeof(options) as options_type,
    jsonb_typeof(options->0) as first_option_type
FROM questions
WHERE id = '28c7f67c-5f45-49a2-8636-23291204e039';

-- Step 2: Update questions where options are already objects with text/is_correct
UPDATE questions q
SET options = (
    SELECT jsonb_agg(
        CASE 
            WHEN elem->>'text' = q.correct_answer 
            THEN jsonb_set(elem, '{is_correct}', 'true'::jsonb)
            ELSE jsonb_set(elem, '{is_correct}', 'false'::jsonb)
        END
    )
    FROM jsonb_array_elements(q.options) elem
    WHERE jsonb_typeof(elem) = 'object'
)
WHERE correct_answer IS NOT NULL
  AND options IS NOT NULL
  AND jsonb_typeof(options->0) = 'object';

-- Step 3: For questions where options are simple strings, convert them to objects
UPDATE questions q
SET options = (
    SELECT jsonb_agg(
        jsonb_build_object(
            'text', elem::text,
            'is_correct', (elem::text = q.correct_answer)
        )
    )
    FROM jsonb_array_elements_text(q.options) elem
)
WHERE correct_answer IS NOT NULL
  AND options IS NOT NULL
  AND jsonb_typeof(options->0) = 'string';

-- Step 4: Verify the update for the specific question
SELECT 
    id,
    title,
    correct_answer,
    jsonb_pretty(options) as formatted_options
FROM questions
WHERE id = '28c7f67c-5f45-49a2-8636-23291204e039';

-- Step 5: Verify all questions have proper format
SELECT 
    COUNT(*) as total_questions,
    COUNT(CASE WHEN jsonb_typeof(options->0) = 'object' THEN 1 END) as object_format,
    COUNT(CASE WHEN jsonb_typeof(options->0) = 'string' THEN 1 END) as string_format
FROM questions
WHERE options IS NOT NULL;
