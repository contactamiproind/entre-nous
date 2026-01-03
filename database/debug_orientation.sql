-- Check for NULL values in pathway_levels that might cause the error
SELECT 
    id,
    pathway_id,
    level_number,
    level_name,
    description,
    required_score
FROM pathway_levels 
WHERE pathway_id = '20000000-0000-0000-0000-000000000001';

-- Also check if pathway exists
SELECT id, name, description 
FROM pathways 
WHERE id = '20000000-0000-0000-0000-000000000001';

-- Check a sample question
SELECT 
    id,
    level_id,
    question_text,
    question_type,
    correct_answer,
    correct_answer_index
FROM question_bank 
WHERE level_id = '21000000-0000-0000-0000-000000000001'
LIMIT 3;
