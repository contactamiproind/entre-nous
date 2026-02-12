-- Find End Game Department Details
SELECT * FROM departments 
WHERE title ILIKE '%End%' 
   OR category ILIKE '%End%' 
   OR description ILIKE '%End%';
