-- Create a view to see user_pathway with pathway names
-- This makes it easier to see which pathways users are enrolled in

CREATE OR REPLACE VIEW user_pathway_with_names AS
SELECT 
  up.id,
  up.user_id,
  up.pathway_id,
  p.name as pathway_name,
  up.enrolled_at,
  up.is_current,
  up.completed,
  up.completed_at
FROM user_pathway up
LEFT JOIN pathways p ON up.pathway_id = p.id
ORDER BY up.enrolled_at DESC;

-- Grant access to authenticated users
GRANT SELECT ON user_pathway_with_names TO authenticated;

-- Now you can query this view in Supabase Table Editor
-- It will show pathway names instead of just IDs
