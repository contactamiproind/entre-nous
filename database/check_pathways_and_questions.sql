-- Check all available pathways/departments
SELECT id, name, description 
FROM departments 
ORDER BY name;

-- Check current question distribution
SELECT 
  q.id,
  q.description as question,
  q.difficulty,
  dl.title as level_title,
  d.name as department_name
FROM questions q
LEFT JOIN dept_levels dl ON q.level_id = dl.id
LEFT JOIN departments d ON dl.dept_id = d.id
ORDER BY q.created_at;

-- To redistribute questions, you'll need to:
-- 1. Identify the department IDs for Vision, Values, and Goals
-- 2. Update questions to link to the appropriate dept_levels

-- Example: If you want to move questions to different departments,
-- you'll need to update their level_id to point to dept_levels 
-- from the target department
