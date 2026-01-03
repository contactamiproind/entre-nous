-- Manually confirm the existing user
-- Run this to confirm amit@andorbitsolutions.com

UPDATE auth.users
SET email_confirmed_at = NOW(),
    confirmed_at = NOW()
WHERE email = 'amit@andorbitsolutions.com'
AND email_confirmed_at IS NULL;

-- Verify the user is confirmed
SELECT email, email_confirmed_at, confirmed_at
FROM auth.users
WHERE email = 'amit@andorbitsolutions.com';
