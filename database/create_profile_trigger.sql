-- ============================================
-- TRIGGER: trigger_on_profile_created
-- ============================================
-- Automatically assigns General departments when a new user profile is created.
-- ============================================

-- Function to handle the trigger event
CREATE OR REPLACE FUNCTION handle_new_user_profile()
RETURNS TRIGGER AS $$
BEGIN
    -- Call the auto-assign function for the new user
    -- We use PERFORM to start it and ignore the void result
    PERFORM auto_assign_general_departments(NEW.user_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists to avoid conflicts
DROP TRIGGER IF EXISTS on_profile_created ON profiles;

-- Create the trigger
CREATE TRIGGER on_profile_created
    AFTER INSERT ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user_profile();

SELECT 'Trigger on_profile_created created successfully!' as status;
