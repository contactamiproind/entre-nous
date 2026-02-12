-- Check User Assignments and Progress for 'Abhi'

SELECT 
    p.full_name,
    p.level,
    d.title as dept_title,
    d.category,
    ud.current_level as user_dept_level,
    ud.is_current,
    (SELECT COUNT(*) FROM usr_progress up WHERE up.usr_dept_id = ud.id) as progress_count
FROM profiles p
JOIN usr_dept ud ON p.user_id = ud.user_id
JOIN departments d ON ud.dept_id = d.id
WHERE p.full_name = 'Abhi';
