-- Check all assigned pathways for the user
SELECT 
  d.title as pathway_name,
  d.id as pathway_id,
  up.assigned_at
FROM user_pathway up
JOIN departments d ON up.pathway_id = d.id
WHERE up.user_id = 'fe3c162a-0b43-4a79-bdff-d32234429781'
ORDER BY up.assigned_at;

-- Count total assigned pathways
SELECT COUNT(*) as total_assigned
FROM user_pathway
WHERE user_id = 'fe3c162a-0b43-4a79-bdff-d32234429781';
