SELECT title, category, count(*) 
FROM departments 
WHERE title = 'General' 
GROUP BY title, category;
