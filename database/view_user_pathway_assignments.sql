-- Comprehensive query to see all user pathway assignments

-- Option 1: Simple view - who has what assigned
SELECT 
  u.email,
  d.title as pathway_name,
  up.assigned_at
FROM user_pathway up
JOIN auth.users u ON up.user_id = u.id
LEFT JOIN departments d ON up.pathway_id = d.id
ORDER BY u.email, d.title;

-- Option 2: Grouped by user - count per pathway
SELECT 
  u.email,
  STRING_AGG(d.title, ', ' ORDER BY d.title) as assigned_pathways,
  COUNT(*) as total_pathways
FROM user_pathway up
JOIN auth.users u ON up.user_id = u.id
LEFT JOIN departments d ON up.pathway_id = d.id
GROUP BY u.email
ORDER BY u.email;

-- Option 3: Pivot view - show which users have each pathway
SELECT 
  d.title as pathway_name,
  COUNT(*) as users_assigned,
  STRING_AGG(u.email, ', ') as user_emails
FROM user_pathway up
JOIN auth.users u ON up.user_id = u.id
LEFT JOIN departments d ON up.pathway_id = d.id
GROUP BY d.title
ORDER BY d.title;

-- Option 4: Detailed view with user IDs
SELECT 
  u.id as user_id,
  u.email,
  d.id as pathway_id,
  d.title as pathway_name,
  d.description as pathway_description,
  up.assigned_at
FROM user_pathway up
JOIN auth.users u ON up.user_id = u.id
LEFT JOIN departments d ON up.pathway_id = d.id
ORDER BY u.email, d.title;

-- Option 5: Check for specific pathways (Vision, Values, Goals)
SELECT 
  u.email,
  MAX(CASE WHEN d.title = 'Vision' THEN '✓' ELSE '' END) as has_vision,
  MAX(CASE WHEN d.title = 'Values' THEN '✓' ELSE '' END) as has_values,
  MAX(CASE WHEN d.title = 'Goals' THEN '✓' ELSE '' END) as has_goals,
  COUNT(*) as total_assigned
FROM user_pathway up
JOIN auth.users u ON up.user_id = u.id
LEFT JOIN departments d ON up.pathway_id = d.id
GROUP BY u.email
ORDER BY u.email;
