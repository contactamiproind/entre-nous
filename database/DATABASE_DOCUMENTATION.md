# ENEPL App - Supabase Database Documentation

## Overview
This document provides complete documentation of all Supabase tables, their columns, relationships, and properties.

---

## Tables Summary

| Table Name | Purpose | Row Count (Seed) | Primary Key |
|------------|---------|------------------|-------------|
| users | User authentication and basic info | 2 | id (UUID) |
| profiles | Extended user profile information | 2 | id (UUID) |
| quiz_progress | Quiz attempt history | 0 | id (UUID) |
| pathways | Department/pathway definitions | 4 | id (UUID) |
| pathway_levels | Levels within each pathway | 20 | id (UUID) |
| user_assignments | User assignments with marks | 1 | id (UUID) |
| user_progress | Aggregated user progress | 1 | id (UUID) |

---

## Table Details

### 1. users
**Purpose:** Core user authentication and account management

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| id | UUID | PRIMARY KEY | gen_random_uuid() | Unique user identifier |
| username | TEXT | UNIQUE NOT NULL | - | Login username |
| password | TEXT | NOT NULL | - | Hashed password |
| is_admin | BOOLEAN | - | FALSE | Legacy admin flag |
| current_level | INTEGER | - | 1 | Legacy level tracking |
| created_at | TIMESTAMPTZ | - | NOW() | Account creation time |
| updated_at | TIMESTAMPTZ | - | NOW() | Last update time |

**Indexes:**
- `idx_users_username` on username
- `idx_users_created_at` on created_at

**RLS Policies:**
- Allow read access to all users
- Allow users to update own data
- Allow insert for new users

---

### 2. profiles
**Purpose:** Extended user profile with role management

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| id | UUID | PRIMARY KEY | gen_random_uuid() | Unique profile ID |
| user_id | UUID | UNIQUE, FK → users(id) | - | Links to user |
| full_name | TEXT | - | - | User's full name |
| email | TEXT | UNIQUE | - | Email address |
| phone | TEXT | - | - | Phone number |
| avatar_url | TEXT | - | - | Avatar image URL |
| bio | TEXT | - | - | User biography |
| date_of_birth | DATE | - | - | Date of birth |
| **role** | **user_role** | - | **'user'** | **User/Admin role** |
| created_at | TIMESTAMPTZ | - | NOW() | Creation time |
| updated_at | TIMESTAMPTZ | - | NOW() | Last update time |

**Indexes:**
- `idx_profiles_user_id` on user_id
- `idx_profiles_email` on email
- `idx_profiles_role` on role

**RLS Policies:**
- Users can read own profile
- Users can update own profile
- Users can insert own profile

---

### 3. quiz_progress
**Purpose:** Track quiz attempts and scores

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| id | UUID | PRIMARY KEY | gen_random_uuid() | Unique record ID |
| user_id | UUID | FK → users(id) | - | User who took quiz |
| level | INTEGER | NOT NULL | - | Quiz level |
| score | INTEGER | NOT NULL | - | Score achieved |
| total_questions | INTEGER | NOT NULL | - | Total questions |
| completed_at | TIMESTAMPTZ | - | NOW() | Completion time |

**Indexes:**
- `idx_quiz_progress_user_id` on user_id
- `idx_quiz_progress_level` on level
- `idx_quiz_progress_completed_at` on completed_at

---

### 4. pathways
**Purpose:** Define the 4 department pathways

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| id | UUID | PRIMARY KEY | gen_random_uuid() | Unique pathway ID |
| name | TEXT | UNIQUE NOT NULL | - | Pathway name |
| description | TEXT | - | - | Pathway description |
| created_at | TIMESTAMPTZ | - | NOW() | Creation time |
| updated_at | TIMESTAMPTZ | - | NOW() | Last update time |

**Seed Data:**
1. Communication - 5 levels
2. Creative - 6 levels
3. Production - 4 levels
4. Ideation - 5 levels

**Indexes:**
- `idx_pathways_name` on name

**RLS Policies:**
- All users can read pathways
- Only admins can insert/update/delete

---

### 5. pathway_levels
**Purpose:** Define levels within each pathway

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| id | UUID | PRIMARY KEY | gen_random_uuid() | Unique level ID |
| pathway_id | UUID | FK → pathways(id) | - | Parent pathway |
| level_number | INTEGER | NOT NULL | - | Level number (1, 2, 3...) |
| level_name | TEXT | NOT NULL | - | Level name |
| required_score | INTEGER | NOT NULL | 0 | Score needed to unlock |
| description | TEXT | - | - | Level description |
| created_at | TIMESTAMPTZ | - | NOW() | Creation time |
| updated_at | TIMESTAMPTZ | - | NOW() | Last update time |

**Unique Constraint:**
- (pathway_id, level_number) - Ensures unique level numbers per pathway

**Indexes:**
- `idx_pathway_levels_pathway_id` on pathway_id
- `idx_pathway_levels_level_number` on level_number

**RLS Policies:**
- All users can read levels
- Only admins can insert/update/delete

---

### 6. user_assignments
**Purpose:** Track user assignments with orientation

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| id | UUID | PRIMARY KEY | gen_random_uuid() | Unique assignment ID |
| user_id | UUID | FK → users(id) | - | Assigned user |
| assignment_name | TEXT | NOT NULL | - | Assignment name |
| orientation_completed | BOOLEAN | - | FALSE | Is orientation assignment |
| marks | INTEGER | - | 0 | Marks obtained |
| max_marks | INTEGER | - | 100 | Maximum marks |
| completed_at | TIMESTAMPTZ | - | NULL | Completion time |
| created_at | TIMESTAMPTZ | - | NOW() | Creation time |
| updated_at | TIMESTAMPTZ | - | NOW() | Last update time |

**Indexes:**
- `idx_user_assignments_user_id` on user_id
- `idx_user_assignments_completed_at` on completed_at

**RLS Policies:**
- Users can read own assignments
- Only admins can insert/update/delete

**Triggers:**
- Auto-updates user_progress when assignments change

---

### 7. user_progress
**Purpose:** Aggregated user progress tracking

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| id | UUID | PRIMARY KEY | gen_random_uuid() | Unique progress ID |
| user_id | UUID | UNIQUE, FK → users(id) | - | User reference |
| total_assignments | INTEGER | - | 0 | Total assignments |
| completed_assignments | INTEGER | - | 0 | Completed count |
| total_marks | INTEGER | - | 0 | Sum of all marks |
| **orientation_completed** | **BOOLEAN** | - | **FALSE** | **Orientation status** |
| **current_pathway_id** | **UUID** | **FK → pathways(id)** | **NULL** | **Selected pathway** |
| current_level | INTEGER | - | 1 | Current level |
| current_score | INTEGER | - | 0 | Current score |
| updated_at | TIMESTAMPTZ | - | NOW() | Last update time |

**Indexes:**
- `idx_user_progress_user_id` on user_id
- `idx_user_progress_pathway_id` on current_pathway_id

**RLS Policies:**
- Users can read/update own progress
- Admins can read all progress

**Auto-Updated By:**
- Trigger on user_assignments table

---

## Enums

### user_role
**Values:**
- `user` - Regular user (default)
- `admin` - Administrator with full access

**Used In:**
- profiles.role

---

## Relationships

```
users (1) ──→ (1) profiles
users (1) ──→ (N) quiz_progress
users (1) ──→ (N) user_assignments
users (1) ──→ (1) user_progress

pathways (1) ──→ (N) pathway_levels
pathways (1) ──→ (N) user_progress

user_progress (N) ──→ (1) pathways
```

---

## Key Business Rules

1. **Orientation Required:** Users must complete orientation before selecting a pathway
2. **One Pathway:** Users can only select one pathway at a time
3. **Level Unlocking:** Levels unlock based on score requirements
4. **Auto-Progress:** user_progress updates automatically when assignments change
5. **Role-Based Access:** Admins have full CRUD, users have limited access

---

## Helper Functions

### is_admin(user_uuid UUID)
**Returns:** BOOLEAN  
**Purpose:** Check if user has admin role

### update_user_progress_from_assignments()
**Type:** Trigger Function  
**Purpose:** Auto-update user_progress when assignments change

---

## Sample Queries

### Get user with profile and role
```sql
SELECT u.username, p.full_name, p.role
FROM users u
JOIN profiles p ON u.id = p.user_id;
```

### Get pathway with level count
```sql
SELECT p.name, COUNT(pl.id) as level_count
FROM pathways p
LEFT JOIN pathway_levels pl ON p.id = pl.pathway_id
GROUP BY p.name;
```

### Get user progress with pathway name
```sql
SELECT u.username, up.orientation_completed, 
       p.name as pathway, up.current_level, up.current_score
FROM users u
JOIN user_progress up ON u.id = up.user_id
LEFT JOIN pathways p ON up.current_pathway_id = p.id;
```

---

## File Locations

- **Schema:** `database/schema.sql`
- **Seed Data:** `database/seed.sql`
- **Migration Guide:** `database/MIGRATION.md`
- **CSV Export:** `database/supabase_tables_documentation.csv`
