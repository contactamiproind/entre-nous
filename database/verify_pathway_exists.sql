-- Check if the pathway exists in departments table
SELECT id, title, description
FROM departments
WHERE id = '32d2764f-ed76-40db-8886-bcf5923f91a1';

-- If no results, the pathway was deleted but the assignment still references it
-- In that case, we need to either:
-- 1. Create the pathway again, OR
-- 2. Update the assignment to point to a different pathway

-- To see all available pathways:
-- SELECT id, title FROM departments ORDER BY title;
