-- Update quest_types constraint to allow sequence_builder
-- Since sequence_builder already exists in the table, we just need to update the constraint

-- Drop the old constraint
ALTER TABLE quest_types DROP CONSTRAINT IF EXISTS quest_types_name_check;

-- Add the new constraint that includes sequence_builder
ALTER TABLE quest_types ADD CONSTRAINT quest_types_name_check 
  CHECK (name IN (
    'mcq', 
    'match_following', 
    'fill_blank', 
    'card_match', 
    'scenario_decision', 
    'memory_match', 
    'sequence_builder',
    'multi_select',
    'visual_builder',
    'fill',
    'simulation',
    'drag_drop',
    'stack_cards'
  ));

-- Verify the constraint was updated
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint
WHERE conrelid = 'quest_types'::regclass
AND conname = 'quest_types_name_check';

-- Verify sequence_builder exists
SELECT * FROM quest_types WHERE name = 'sequence_builder';
