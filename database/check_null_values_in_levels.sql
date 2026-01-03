-- Check for NULL values in dept_levels table for the Orientation pathway
SELECT 
  id,
  dept_id,
  level_id,
  title,
  category,
  level_number,
  created_at,
  CASE WHEN id IS NULL THEN 'NULL' ELSE 'OK' END as id_check,
  CASE WHEN dept_id IS NULL THEN 'NULL' ELSE 'OK' END as dept_id_check,
  CASE WHEN level_id IS NULL THEN 'NULL' ELSE 'OK' END as level_id_check,
  CASE WHEN title IS NULL THEN 'NULL' ELSE 'OK' END as title_check,
  CASE WHEN level_number IS NULL THEN 'NULL' ELSE 'OK' END as level_number_check
FROM dept_levels
WHERE dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY level_number;
