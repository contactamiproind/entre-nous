# Database Setup Guide

## Overview
This directory contains the database schema and seed data for the Quiz App.

## Files
- **`schema.sql`** - Database structure (tables, indexes, RLS policies, triggers)
- **`seed.sql`** - Initial data for development and testing

## Setup Instructions

### First Time Setup
Run these SQL files in order in your Supabase SQL Editor:

1. **Create Schema** (Run `schema.sql`)
   ```sql
   -- Copy and paste the entire contents of schema.sql
   -- This creates all tables, indexes, and security policies
   ```

2. **Load Seed Data** (Run `seed.sql`)
   ```sql
   -- Copy and paste the entire contents of seed.sql
   -- This adds default users and sample data
   ```

### Development Workflow

Every time you want to reset your database to a clean state:

1. Run `seed.sql` - This will:
   - Clear existing data
   - Insert fresh default users
   - Create sample profiles
   - Add sample quiz progress

### Default Users (from seed.sql)

| Username | Password | Role | Level | Email |
|----------|----------|------|-------|-------|
| user | user123 | User | 1 | user@example.com |
| admin | admin123 | Admin | 1 | admin@example.com |
| john | john123 | User | 3 | john@example.com |
| sarah | sarah123 | User | 2 | sarah@example.com |

## Database Schema

### Tables

#### `users`
- Core user authentication and progress
- Fields: id, username, password, is_admin, current_level, created_at, updated_at

#### `profiles`
- Extended user information
- Fields: id, user_id, full_name, email, phone, avatar_url, bio, date_of_birth, created_at, updated_at

#### `quiz_progress`
- Quiz attempt history
- Fields: id, user_id, level, score, total_questions, completed_at

### Security
- Row Level Security (RLS) enabled on all tables
- Policies allow users to read/update their own data
- Admins can access all data

### Triggers
- Auto-update `updated_at` timestamp on record changes

## Quick Commands

### Reset Database
```sql
-- In Supabase SQL Editor, run seed.sql
-- This will truncate and repopulate all tables
```

### Verify Data
```sql
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM profiles;
SELECT COUNT(*) FROM quiz_progress;
```

### Check User Profiles
```sql
SELECT u.username, p.full_name, p.email, u.current_level
FROM users u
LEFT JOIN profiles p ON u.id = p.user_id;
```

## Notes
- The seed file uses fixed UUIDs for consistency
- `ON CONFLICT` clauses ensure idempotent execution
- TRUNCATE CASCADE clears all related data safely
