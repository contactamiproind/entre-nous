-- Find what department 7670bb1f is
SELECT 
  id,
  title,
  description
FROM departments
WHERE id = '7670bb1f-0d90-47e6-8d52-ff141fb63f45';

-- This department's levels JSONB is what the app is loading
-- Update it to use Vision department's levels instead
UPDATE departments
SET levels = (
  SELECT levels
  FROM departments
  WHERE id = '0630caa4-3087-4192-a6b4-20053c74e8f3'
)
WHERE id = '7670bb1f-0d90-47e6-8d52-ff141fb63f45';

-- Verify
SELECT 
  id,
  title,
  levels
FROM departments
WHERE id = '7670bb1f-0d90-47e6-8d52-ff141fb63f45';
