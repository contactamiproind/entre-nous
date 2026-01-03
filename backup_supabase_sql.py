#!/usr/bin/env python3
"""
Supabase SQL Backup Script
===========================
This script creates SQL backup files (schema.sql and seed.sql) using Supabase REST API.
It reads credentials from the .env file.

Usage: python backup_supabase_sql.py

Requirements:
- Python 3.6+
- requests package (install: pip install requests)
- python-dotenv package (install: pip install python-dotenv)
"""

import os
import sys
import json
from datetime import datetime
from pathlib import Path

try:
    from dotenv import load_dotenv
    import requests
except ImportError as e:
    print(f"Error: Missing required package - {e}")
    print("Install with: pip install python-dotenv requests")
    sys.exit(1)


class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    NC = '\033[0m'


def print_info(message):
    print(f"{Colors.GREEN}[INFO]{Colors.NC} {message}")


def print_error(message):
    print(f"{Colors.RED}[ERROR]{Colors.NC} {message}")


def print_warning(message):
    print(f"{Colors.YELLOW}[WARNING]{Colors.NC} {message}")


def load_env():
    """Load environment variables"""
    if not Path('.env').exists():
        print_error(".env file not found!")
        return None
    
    load_dotenv()
    
    url = os.getenv('SUPABASE_URL')
    key = os.getenv('SUPABASE_ANON_KEY')
    
    if not url or not key:
        print_error("SUPABASE_URL or SUPABASE_ANON_KEY not found in .env")
        return None
    
    return {'url': url, 'key': key}


def get_table_schema(supabase_url, api_key, table_name):
    """Get table schema information from Supabase"""
    # This is a simplified schema - in production you'd query information_schema
    # For now, we'll create basic schemas based on the data structure
    return None


def get_tables():
    """Get list of tables to backup"""
    tables = [
        'profiles',
        'departments',
        'dept_levels',
        'user_pathway',
        'usr_stat',
        'user_progress',
        'quest_types',
        'questions'
    ]
    return tables


def backup_table_data(supabase_url, api_key, table_name):
    """Backup a single table using Supabase REST API"""
    url = f"{supabase_url}/rest/v1/{table_name}"
    headers = {
        'apikey': api_key,
        'Authorization': f'Bearer {api_key}',
        'Content-Type': 'application/json'
    }
    
    try:
        all_records = []
        offset = 0
        limit = 1000
        
        while True:
            params = {
                'select': '*',
                'offset': offset,
                'limit': limit
            }
            
            response = requests.get(url, headers=headers, params=params)
            
            if response.status_code == 200:
                records = response.json()
                if not records:
                    break
                all_records.extend(records)
                offset += limit
                
                if len(records) < limit:
                    break
            elif response.status_code == 404:
                return None
            else:
                print_error(f"Failed to backup {table_name}: {response.status_code}")
                return None
        
        return all_records
    
    except Exception as e:
        print_error(f"Error backing up {table_name}: {str(e)}")
        return None


def sql_escape(value):
    """Escape SQL values"""
    if value is None:
        return 'NULL'
    elif isinstance(value, bool):
        return 'TRUE' if value else 'FALSE'
    elif isinstance(value, (int, float)):
        return str(value)
    elif isinstance(value, dict) or isinstance(value, list):
        # Convert JSON objects to PostgreSQL JSON
        return f"'{json.dumps(value)}'::jsonb"
    else:
        # Escape single quotes for strings
        escaped = str(value).replace("'", "''")
        return f"'{escaped}'"


def generate_insert_statements(table_name, records):
    """Generate SQL INSERT statements for records"""
    if not records:
        return f"-- No data for table: {table_name}\n"
    
    sql_lines = [f"\n-- Data for table: {table_name}"]
    sql_lines.append(f"-- {len(records)} records\n")
    
    # Get column names from first record
    columns = list(records[0].keys())
    columns_str = ', '.join(columns)
    
    # Generate INSERT statements
    for record in records:
        values = [sql_escape(record.get(col)) for col in columns]
        values_str = ', '.join(values)
        sql_lines.append(
            f"INSERT INTO {table_name} ({columns_str}) VALUES ({values_str});"
        )
    
    sql_lines.append("")  # Empty line after table
    return '\n'.join(sql_lines)


def get_table_schema(supabase_url, api_key, table_name):
    """Get actual table schema from database"""
    # Use PostgREST to get table structure
    # This queries information_schema through Supabase REST API
    url = f"{supabase_url}/rest/v1/rpc/get_table_columns"
    headers = {
        'apikey': api_key,
        'Authorization': f'Bearer {api_key}',
        'Content-Type': 'application/json'
    }
    
    try:
        response = requests.post(url, headers=headers, json={'table_name': table_name})
        if response.status_code == 200:
            return response.json()
    except:
        pass
    return None


def create_schema_sql(backup_dir):
    """Create schema.sql with table definitions"""
    schema_content = """-- ============================================
-- Supabase Schema Backup
-- ============================================
-- Generated: {timestamp}
-- This file contains table structure definitions
-- ============================================

-- WARNING: This is a SIMPLIFIED schema reconstruction from API data
-- For production use, use pg_dump for complete schema with:
--   - Constraints, indexes, triggers
--   - Row Level Security policies
--   - Functions and procedures
--
-- Command: pg_dump -h <host> -U postgres -d postgres --schema-only -f schema.sql

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLES
-- ============================================

-- Profiles table
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE,
    full_name TEXT,
    email TEXT UNIQUE,
    phone TEXT,
    avatar_url TEXT,
    bio TEXT,
    date_of_birth DATE,
    role TEXT DEFAULT 'user',
    orientation_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Departments table
CREATE TABLE IF NOT EXISTS departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT,
    title TEXT,
    description TEXT,
    icon TEXT,
    color TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Department levels table
CREATE TABLE IF NOT EXISTS dept_levels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dept_id UUID REFERENCES departments(id) ON DELETE CASCADE,
    level_number INTEGER,
    level_name TEXT,
    description TEXT,
    required_score INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User pathway assignments
CREATE TABLE IF NOT EXISTS user_pathway (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    pathway_id UUID REFERENCES departments(id) ON DELETE CASCADE,
    pathway_name TEXT,
    is_current BOOLEAN DEFAULT TRUE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User statistics
CREATE TABLE IF NOT EXISTS usr_stat (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    total_assignments INTEGER DEFAULT 0,
    completed_assignments INTEGER DEFAULT 0,
    total_marks INTEGER DEFAULT 0,
    orientation_completed BOOLEAN DEFAULT FALSE,
    current_pathway_id UUID,
    current_level INTEGER DEFAULT 1,
    current_score INTEGER DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User progress summary (view or table)
CREATE TABLE IF NOT EXISTS user_progress_summary (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    department_id UUID,
    progress_percentage NUMERIC,
    completed_levels INTEGER DEFAULT 0,
    total_levels INTEGER DEFAULT 0,
    last_activity TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Quiz progress
CREATE TABLE IF NOT EXISTS quiz_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    level INTEGER,
    score INTEGER,
    total_questions INTEGER,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Questions table
CREATE TABLE IF NOT EXISTS questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_text TEXT,
    question_type TEXT,
    difficulty TEXT,
    category TEXT,
    subcategory TEXT,
    correct_answer TEXT,
    explanation TEXT,
    points INTEGER DEFAULT 1,
    time_limit INTEGER,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Question options
CREATE TABLE IF NOT EXISTS question_options (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID REFERENCES questions(id) ON DELETE CASCADE,
    option_text TEXT,
    is_correct BOOLEAN DEFAULT FALSE,
    order_index INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Question level mapping
CREATE TABLE IF NOT EXISTS question_level (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    question_id UUID REFERENCES questions(id) ON DELETE CASCADE,
    dept_level_id UUID REFERENCES dept_levels(id) ON DELETE CASCADE,
    order_index INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON profiles(email);
CREATE INDEX IF NOT EXISTS idx_dept_levels_dept_id ON dept_levels(dept_id);
CREATE INDEX IF NOT EXISTS idx_user_pathway_user_id ON user_pathway(user_id);
CREATE INDEX IF NOT EXISTS idx_user_pathway_pathway_id ON user_pathway(pathway_id);
CREATE INDEX IF NOT EXISTS idx_usr_stat_user_id ON usr_stat(user_id);
CREATE INDEX IF NOT EXISTS idx_quiz_progress_user_id ON quiz_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_question_options_question_id ON question_options(question_id);
CREATE INDEX IF NOT EXISTS idx_question_level_question_id ON question_level(question_id);
CREATE INDEX IF NOT EXISTS idx_question_level_dept_level_id ON question_level(dept_level_id);

-- ============================================
-- End of schema
-- ============================================
""".format(timestamp=datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    
    schema_file = backup_dir / 'schema.sql'
    schema_file.write_text(schema_content)
    print_info(f"Schema file created: {schema_file}")
    return schema_file


def create_seed_sql(backup_dir, table_data):
    """Create seed.sql with all data INSERT statements"""
    seed_lines = [
        "-- ============================================",
        "-- Supabase Data Backup (Seed File)",
        "-- ============================================",
        f"-- Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        "-- This file contains all data as INSERT statements",
        "-- ============================================",
        "",
        "-- Disable triggers during import for faster loading",
        "SET session_replication_role = 'replica';",
        ""
    ]
    
    total_records = 0
    
    # Generate INSERT statements for each table
    for table_name, records in table_data.items():
        if records:
            seed_lines.append(generate_insert_statements(table_name, records))
            total_records += len(records)
            print_info(f"✓ {table_name}: {len(records)} records")
    
    seed_lines.extend([
        "",
        "-- Re-enable triggers",
        "SET session_replication_role = 'origin';",
        "",
        "-- ============================================",
        f"-- Total records: {total_records}",
        "-- ============================================"
    ])
    
    seed_file = backup_dir / 'seed.sql'
    seed_file.write_text('\n'.join(seed_lines))
    print_info(f"Seed file created: {seed_file}")
    return seed_file, total_records


def create_backup_directory():
    """Create timestamped backup directory"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_dir = Path('backups') / f'sql_backup_{timestamp}'
    backup_dir.mkdir(parents=True, exist_ok=True)
    return backup_dir, timestamp


def create_readme(backup_dir, total_records, tables_count):
    """Create README with instructions"""
    readme_content = f"""# Supabase SQL Backup

Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## Files

- **schema.sql** - Database structure (tables, indexes)
- **seed.sql** - All data as INSERT statements ({total_records} records from {tables_count} tables)

## Restore Instructions

### Full Restore (Schema + Data)

```bash
# Using psql
psql -h db.xxxxx.supabase.co -U postgres -d postgres -f schema.sql
psql -h db.xxxxx.supabase.co -U postgres -d postgres -f seed.sql
```

### Schema Only

```bash
psql -h db.xxxxx.supabase.co -U postgres -d postgres -f schema.sql
```

### Data Only

```bash
psql -h db.xxxxx.supabase.co -U postgres -d postgres -f seed.sql
```

## Using Supabase SQL Editor

1. Go to Supabase Dashboard → SQL Editor
2. Copy contents of `schema.sql` and run
3. Copy contents of `seed.sql` and run

## Notes

- The schema.sql is a simplified version based on data structure
- For production, consider using pg_dump for complete schema with RLS policies
- Backup includes {total_records} total records
- Tables backed up: {tables_count}

## Security

⚠️ These files contain sensitive data. Keep them secure and never commit to version control.
"""
    
    readme_file = backup_dir / 'README.md'
    readme_file.write_text(readme_content)
    print_info(f"README created: {readme_file}")


def main():
    """Main backup function"""
    print()
    print("=" * 50)
    print("Supabase SQL Backup Script")
    print("=" * 50)
    print()
    
    # Load environment
    env = load_env()
    if not env:
        sys.exit(1)
    
    print_info(f"Supabase URL: {env['url']}")
    
    # Create backup directory
    backup_dir, timestamp = create_backup_directory()
    print_info(f"Backup directory: {backup_dir}")
    print()
    
    # Get tables
    tables = get_tables()
    print_info(f"Backing up {len(tables)} tables...")
    print()
    
    # Backup all table data
    table_data = {}
    for table in tables:
        records = backup_table_data(env['url'], env['key'], table)
        if records is not None:
            table_data[table] = records
        else:
            print_warning(f"Table '{table}' not found or empty, skipping...")
    
    print()
    
    if not table_data:
        print_error("No tables were backed up!")
        sys.exit(1)
    
    # Create schema.sql
    print_info("Creating schema.sql...")
    create_schema_sql(backup_dir)
    
    # Create seed.sql
    print_info("Creating seed.sql...")
    seed_file, total_records = create_seed_sql(backup_dir, table_data)
    
    # Create README
    create_readme(backup_dir, total_records, len(table_data))
    
    # Summary
    print()
    print("=" * 50)
    print_info("SQL Backup completed successfully!")
    print("=" * 50)
    print_info(f"Location: {backup_dir}")
    print_info(f"Files created:")
    print(f"  - schema.sql (table definitions)")
    print(f"  - seed.sql ({total_records} records)")
    print(f"  - README.md (restore instructions)")
    print()
    print_info("To restore:")
    print(f"  psql -h <host> -U postgres -d postgres -f {backup_dir}/schema.sql")
    print(f"  psql -h <host> -U postgres -d postgres -f {backup_dir}/seed.sql")
    print("=" * 50)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print()
        print_warning("Backup cancelled by user")
        sys.exit(1)
    except Exception as e:
        print_error(f"Unexpected error: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
