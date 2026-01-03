-- Check all 16 pathways and their question distribution

-- Step 1: List all pathways
SELECT 
  id,
  title,
  description,
  created_at
FROM departments
ORDER BY title;

-- Step 2: Check question count for each pathway
SELECT 
  d.title as pathway_name,
  COUNT(DISTINCT dl.id) as total_levels,
  COUNT(q.id) as total_questions,
  STRING_AGG(DISTINCT dl.title, ', ' ORDER BY dl.title) as level_names
FROM departments d
LEFT JOIN dept_levels dl ON dl.dept_id = d.id
LEFT JOIN questions q ON q.level_id = dl.id
GROUP BY d.id, d.title
ORDER BY d.title;

-- Step 3: Detailed breakdown - questions per level for each pathway
SELECT 
  d.title as pathway_name,
  dl.level_number,
  dl.title as level_name,
  COUNT(q.id) as question_count
FROM departments d
LEFT JOIN dept_levels dl ON dl.dept_id = d.id
LEFT JOIN questions q ON q.level_id = dl.id
GROUP BY d.id, d.title, dl.level_number, dl.title
ORDER BY d.title, dl.level_number;
