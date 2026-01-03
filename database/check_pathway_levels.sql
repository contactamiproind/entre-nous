-- Check what levels exist for the Orientation pathway
SELECT id, dept_id, level_number, level_name, required_score, description, created_at
FROM dept_levels
WHERE dept_id = '32d2764f-ed76-40db-8886-bcf5923f91a1'
ORDER BY level_number;

-- If no results, the pathway has no levels, which would cause the app to crash
-- In that case, we need to create at least one level
