-- Check what tables reference the departments we want to delete

SELECT 
  'TABLES REFERENCING VISION DEPT' as info,
  tc.table_name,
  kcu.column_name,
  COUNT(*) as reference_count
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu 
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND ccu.table_name = 'departments'
  AND ccu.column_name = 'id'
GROUP BY tc.table_name, kcu.column_name
ORDER BY tc.table_name;
