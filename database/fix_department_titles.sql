-- ============================================
-- Fix Department Titles
-- ============================================
-- This script updates the titles of 'General' departments to be more specific:
-- 1. General (Orientation)
-- 2. General (Process)
-- 3. General (SOP)
-- 4. Production (removes 'General' if present)

-- Update Orientation
UPDATE departments 
SET title = 'General (Orientation)'
WHERE title = 'General' AND category = 'Orientation';

-- Update Process
UPDATE departments 
SET title = 'General (Process)'
WHERE title = 'General' AND category = 'Process';

-- Update SOP
UPDATE departments 
SET title = 'General (SOP)'
WHERE title = 'General' AND category = 'SOP';

-- Update Production (ensure it is just 'Production')
UPDATE departments 
SET title = 'Production'
WHERE (title = 'General' OR title = 'General (Production)') AND category = 'Production';

-- Verification
SELECT title, category, description FROM departments ORDER BY title;
