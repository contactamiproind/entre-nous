-- Check what 3 pathways are assigned to user fe3c162a-0b43-4a79-bdff-d32234429781

SELECT 
  up.id,
  up.pathway_id,
  d.title as pathway_name,
  d.description,
  up.assigned_at
FROM user_pathway up
LEFT JOIN departments d ON up.pathway_id = d.id
WHERE up.user_id = 'fe3c162a-0b43-4a79-bdff-d32234429781'
ORDER BY d.title;
