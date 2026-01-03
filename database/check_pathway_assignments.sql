-- Check what was inserted into user_pathway
SELECT 
    up.user_id,
    up.pathway_id,
    up.pathway_name,
    up.is_current,
    d.title as department_title
FROM user_pathway up
LEFT JOIN departments d ON up.pathway_id = d.id
ORDER BY up.assigned_at DESC
LIMIT 5;
