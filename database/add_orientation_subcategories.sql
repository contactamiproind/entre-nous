-- Add Orientation Subcategories
-- This script updates the Orientation department to include all 16 sub-topics as subcategories

-- First, let's update the subcategory field to store the topics as a JSONB array
-- The 16 sub-topics are:
-- 1. Vision
-- 2. Values  
-- 3. Goals
-- 4. Brand Guidelines
-- 5. Job Sheet
-- 6. Juice of the story
-- 7. How do you prioritize?
-- 8. Greetings
-- 9. Dress Code
-- 10. ATTENDANCE/LEAVES
-- 11. OFFICE DECORUM
-- 12. Master Class
-- 13. WORKING STYLE
-- 14. Vendor Interaction Guidelines
-- 15. Communication & Response Protocol
-- 16. Email Etiquette

-- Update the Orientation department with subcategories
UPDATE departments
SET 
  subcategory = 'Orientation Topics',
  tags = jsonb_build_object(
    'topics', jsonb_build_array(
      'Vision',
      'Values',
      'Goals',
      'Brand Guidelines',
      'Job Sheet',
      'Juice of the story',
      'How do you prioritize?',
      'Greetings',
      'Dress Code',
      'ATTENDANCE/LEAVES',
      'OFFICE DECORUM',
      'Master Class',
      'WORKING STYLE',
      'Vendor Interaction Guidelines',
      'Communication & Response Protocol',
      'Email Etiquette'
    )
  )
WHERE category = 'Orientation';

-- Verify the update
SELECT id, title, category, subcategory, tags
FROM departments
WHERE category = 'Orientation';
