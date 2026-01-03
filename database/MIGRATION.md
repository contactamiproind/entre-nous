# Database Migration Guide

## Overview

This guide will help you apply the new ENEPL App database schema to your Supabase project. The new schema includes:

- **User Roles**: User/Admin role system
- **Pathways**: 4 departments (Communication, Creative, Production, Ideation)
- **Pathway Levels**: Different level structures for each department
- **User Assignments**: Assignment tracking with orientation status
- **User Progress**: Aggregated progress tracking

## Prerequisites

- Access to your Supabase project dashboard
- SQL Editor access in Supabase

## Migration Steps

### Step 1: Backup Existing Data

> [!WARNING]
> Before proceeding, backup your existing data!

1. Go to Supabase Dashboard → SQL Editor
2. Run this query to export existing users and profiles:

```sql
-- Export existing data (copy the results)
SELECT * FROM users;
SELECT * FROM profiles;
SELECT * FROM quiz_progress;
```

3. Save the results to a safe location

### Step 2: Apply New Schema

1. Navigate to Supabase Dashboard → SQL Editor
2. Create a new query
3. Copy the entire contents of `database/schema.sql`
4. Paste into the SQL Editor
5. Click **Run** to execute

This will:
- Create the `user_role` enum type
- Add `role` field to `profiles` table
- Create `pathways` table
- Create `pathway_levels` table
- Create `user_assignments` table
- Create `user_progress` table
- Set up all indexes
- Configure RLS policies
- Create helper functions and triggers

### Step 3: Load Seed Data

1. In SQL Editor, create another new query
2. Copy the entire contents of `database/seed.sql`
3. Paste into the SQL Editor
4. Click **Run** to execute

This will populate:
- 4 test users (including 1 admin)
- 4 pathways (Communication, Creative, Production, Ideation)
- Pathway levels for each department:
  - **Communication**: 5 levels (Foundation → Master)
  - **Creative**: 6 levels (Explorer → Maestro)
  - **Production**: 4 levels (Coordinator → Executive Producer)
  - **Ideation**: 5 levels (Thinker → Thought Leader)
- Sample user assignments
- Sample user progress

### Step 4: Verify Tables

Run these verification queries:

```sql
-- Check all tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'profiles', 'pathways', 'pathway_levels', 'user_assignments', 'user_progress');

-- Verify pathways
SELECT id, name, description FROM pathways ORDER BY name;

-- Verify pathway levels count per department
SELECT p.name, COUNT(pl.id) as level_count
FROM pathways p
LEFT JOIN pathway_levels pl ON p.id = pl.pathway_id
GROUP BY p.name
ORDER BY p.name;

-- Check user roles
SELECT u.username, p.role 
FROM users u 
JOIN profiles p ON u.id = p.user_id;
```

Expected results:
- 6 tables should exist
- 4 pathways (Communication, Creative, Production, Ideation)
- Level counts: Communication=5, Creative=6, Production=4, Ideation=5
- Admin user should have role='admin'

### Step 5: Test RLS Policies

Test that Row Level Security is working correctly:

```sql
-- Test 1: Verify RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('pathways', 'pathway_levels', 'user_assignments', 'user_progress');

-- All should show rowsecurity = true

-- Test 2: Check policies exist
SELECT tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public';
```

### Step 6: Update Existing User Roles

If you have existing users, update their profiles with roles:

```sql
-- Set admin role for specific users (replace with actual user IDs)
UPDATE profiles 
SET role = 'admin' 
WHERE user_id = 'YOUR_ADMIN_USER_ID';

-- Set regular user role for all others
UPDATE profiles 
SET role = 'user' 
WHERE role IS NULL;
```

## Test Credentials

After migration, you can use these test accounts:

| Username | Password | Role | Orientation | Pathway |
|----------|----------|------|-------------|---------|
| admin | admin123 | Admin | N/A | N/A |
| user | user123 | User | Not completed | None |
| john | john123 | User | Completed | Communication (Level 2) |
| sarah | sarah123 | User | Completed | Creative (Level 2) |

## Troubleshooting

### Issue: "type user_role already exists"

This is normal if you run the schema multiple times. The script handles this gracefully.

### Issue: "duplicate key value violates unique constraint"

This happens if you run seed.sql multiple times. The script uses `ON CONFLICT` to handle this, so it's safe.

### Issue: RLS policies blocking queries

Make sure you're authenticated as a user when testing. Supabase RLS policies require authentication context.

## Next Steps

After successful migration:

1. **Test the Flutter App**: Run `flutter pub get` to update dependencies
2. **Verify Models**: Ensure all new models are imported correctly
3. **Test Services**: Verify pathway, assignment, and progress services work
4. **Update UI**: Implement admin and user dashboards with new features

## Rollback (If Needed)

If you need to rollback:

```sql
-- Drop new tables (WARNING: This deletes all data!)
DROP TABLE IF EXISTS user_progress CASCADE;
DROP TABLE IF EXISTS user_assignments CASCADE;
DROP TABLE IF EXISTS pathway_levels CASCADE;
DROP TABLE IF EXISTS pathways CASCADE;

-- Remove role from profiles
ALTER TABLE profiles DROP COLUMN IF EXISTS role;

-- Drop enum type
DROP TYPE IF EXISTS user_role;
```

Then restore from your backup.
