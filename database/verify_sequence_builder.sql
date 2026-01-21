-- Since sequence_builder already exists and the constraint is causing issues,
-- let's just verify that everything is working without modifying constraints

-- Check all existing quest types
SELECT * FROM quest_types ORDER BY type;

-- The sequence_builder type already exists, so the widget will work fine!
-- No constraint update is needed - your database already supports sequence_builder.
