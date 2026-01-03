-- Add pathway_name column to user_pathway table
-- This makes it easier to see pathway names in Supabase Table Editor

-- Step 1: Add the column
ALTER TABLE user_pathway 
ADD COLUMN IF NOT EXISTS pathway_name TEXT;

-- Step 2: Populate existing records with pathway names
UPDATE user_pathway up
SET pathway_name = p.name
FROM pathways p
WHERE up.pathway_id = p.id;

-- Step 3: Create function to auto-populate pathway_name on insert/update
CREATE OR REPLACE FUNCTION set_pathway_name()
RETURNS TRIGGER AS $$
BEGIN
  -- Get the pathway name from pathways table
  SELECT name INTO NEW.pathway_name
  FROM pathways
  WHERE id = NEW.pathway_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 4: Create trigger to automatically set pathway_name
DROP TRIGGER IF EXISTS auto_set_pathway_name ON user_pathway;
CREATE TRIGGER auto_set_pathway_name
  BEFORE INSERT OR UPDATE ON user_pathway
  FOR EACH ROW
  EXECUTE FUNCTION set_pathway_name();

-- Step 5: Create trigger to update pathway_name when pathway name changes
CREATE OR REPLACE FUNCTION update_user_pathway_names()
RETURNS TRIGGER AS $$
BEGIN
  -- Update all user_pathway records when pathway name changes
  UPDATE user_pathway
  SET pathway_name = NEW.name
  WHERE pathway_id = NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS sync_pathway_names ON pathways;
CREATE TRIGGER sync_pathway_names
  AFTER UPDATE ON pathways
  FOR EACH ROW
  WHEN (OLD.name IS DISTINCT FROM NEW.name)
  EXECUTE FUNCTION update_user_pathway_names();
