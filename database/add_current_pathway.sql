-- Add is_current field to user_pathway table
-- This tracks which pathway the user is currently working on

ALTER TABLE user_pathway 
ADD COLUMN IF NOT EXISTS is_current BOOLEAN DEFAULT FALSE;

-- Set the first enrolled pathway as current for existing users
UPDATE user_pathway up
SET is_current = TRUE
WHERE id IN (
  SELECT DISTINCT ON (user_id) id
  FROM user_pathway
  ORDER BY user_id, enrolled_at
);

-- Create a function to ensure only one pathway is current per user
CREATE OR REPLACE FUNCTION set_current_pathway()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_current = TRUE THEN
    -- Set all other pathways for this user to not current
    UPDATE user_pathway
    SET is_current = FALSE
    WHERE user_id = NEW.user_id AND id != NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to enforce single current pathway
DROP TRIGGER IF EXISTS ensure_single_current_pathway ON user_pathway;
CREATE TRIGGER ensure_single_current_pathway
  BEFORE INSERT OR UPDATE ON user_pathway
  FOR EACH ROW
  EXECUTE FUNCTION set_current_pathway();
