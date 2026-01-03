# Supabase Backup & Restore Guide

This guide explains how to backup and restore your Supabase database.

## Prerequisites

### 1. PostgreSQL Client Tools

You need `pg_dump` and `psql` installed on your system.

**macOS:**
```bash
brew install postgresql
```

**Ubuntu/Debian:**
```bash
sudo apt-get install postgresql-client
```

**Windows:**
Download from [PostgreSQL Downloads](https://www.postgresql.org/download/)

### 2. Python Dependencies (for Python scripts)

```bash
pip install python-dotenv
```

### 3. Database Credentials

You need your Supabase database connection credentials:

1. Go to your Supabase Dashboard
2. Navigate to: **Project Settings** → **Database**
3. Find the **Connection String** section
4. Note down:
   - Host (e.g., `db.xxxxx.supabase.co`)
   - Database name (usually `postgres`)
   - User (usually `postgres`)
   - Password
   - Port (usually `5432`)

## Backup Scripts

Two backup scripts are provided:

### Option 1: Bash Script (Linux/macOS)

```bash
chmod +x backup_supabase.sh
./backup_supabase.sh
```

### Option 2: Python Script (Cross-platform)

```bash
python backup_supabase.py
```

## What Gets Backed Up

The backup scripts create three files:

1. **`schema.sql`** - Database structure only (tables, indexes, functions, etc.)
2. **`data.sql`** - Data only (INSERT statements)
3. **`complete_backup.sql`** - Complete backup (schema + data)

Plus:
- **`backup_info.txt`** - Metadata and restore instructions
- **`supabase_backup_TIMESTAMP.tar.gz`** - Compressed archive of all files

## Backup Process

1. The script reads `SUPABASE_URL` from your `.env` file
2. You'll be prompted for database credentials
3. Three backup files are created
4. Files are compressed into a `.tar.gz` archive
5. Backup is saved in `backups/TIMESTAMP/` directory

## Restore

### Using Python Script

```bash
python restore_supabase.py backups/20260103_153000
```

The script will:
1. Show available backup files
2. Let you choose which to restore
3. Prompt for database credentials
4. Restore the selected backup

### Manual Restore

**Restore complete backup:**
```bash
psql -h db.xxxxx.supabase.co -U postgres -d postgres -p 5432 -f complete_backup.sql
```

**Restore schema only:**
```bash
psql -h db.xxxxx.supabase.co -U postgres -d postgres -p 5432 -f schema.sql
```

**Restore data only:**
```bash
psql -h db.xxxxx.supabase.co -U postgres -d postgres -p 5432 -f data.sql
```

You'll be prompted for the database password.

## Best Practices

### 1. Regular Backups

Schedule regular backups using cron (Linux/macOS) or Task Scheduler (Windows):

**Cron example (daily at 2 AM):**
```bash
0 2 * * * cd /path/to/project && python backup_supabase.py
```

### 2. Backup Storage

- Store backups in multiple locations
- Use cloud storage (AWS S3, Google Drive, Dropbox)
- Keep at least 7 days of backups
- Test restore process regularly

### 3. Security

- **Never commit backup files to Git** (they contain sensitive data)
- Encrypt backups before uploading to cloud storage
- Restrict access to backup files
- Rotate database passwords periodically

### 4. Before Major Changes

Always create a backup before:
- Schema migrations
- Major data updates
- Deploying new features
- Database maintenance

## Backup Retention Strategy

Recommended retention policy:

- **Daily backups**: Keep for 7 days
- **Weekly backups**: Keep for 4 weeks
- **Monthly backups**: Keep for 12 months
- **Yearly backups**: Keep indefinitely

## Automated Cleanup Script

Create a script to remove old backups:

```bash
# Remove backups older than 7 days
find backups/ -type d -mtime +7 -exec rm -rf {} +
```

## Troubleshooting

### "pg_dump: command not found"

Install PostgreSQL client tools (see Prerequisites).

### "Connection refused"

- Check if database host is correct
- Verify firewall settings
- Ensure your IP is whitelisted in Supabase

### "Authentication failed"

- Verify database password
- Check if user has correct permissions
- Try resetting database password in Supabase dashboard

### "Permission denied"

- Ensure database user has sufficient privileges
- For Supabase, use the `postgres` user provided in dashboard

## Environment-Specific Backups

For different environments (dev, staging, prod):

1. Create separate `.env` files:
   - `.env.development`
   - `.env.staging`
   - `.env.production`

2. Modify backup script to accept environment parameter:
   ```bash
   python backup_supabase.py --env production
   ```

## Backup File Structure

```
backups/
├── 20260103_153000/
│   ├── schema.sql
│   ├── data.sql
│   ├── complete_backup.sql
│   └── backup_info.txt
├── 20260103_153000.tar.gz
└── 20260104_020000/
    ├── schema.sql
    ├── data.sql
    ├── complete_backup.sql
    └── backup_info.txt
```

## Monitoring Backups

Create a monitoring script to verify backups:

```python
import os
from datetime import datetime, timedelta
from pathlib import Path

def check_recent_backup():
    backup_dir = Path('backups')
    if not backup_dir.exists():
        return False
    
    # Check if backup exists from last 24 hours
    yesterday = datetime.now() - timedelta(days=1)
    
    for backup in backup_dir.iterdir():
        if backup.is_dir():
            backup_time = datetime.strptime(backup.name, '%Y%m%d_%H%M%S')
            if backup_time > yesterday:
                return True
    
    return False

if not check_recent_backup():
    print("WARNING: No recent backup found!")
```

## Cloud Backup Integration

### Upload to AWS S3

```bash
aws s3 cp supabase_backup_*.tar.gz s3://your-bucket/backups/
```

### Upload to Google Cloud Storage

```bash
gsutil cp supabase_backup_*.tar.gz gs://your-bucket/backups/
```

## Recovery Testing

Regularly test your backups:

1. Create a test database
2. Restore backup to test database
3. Verify data integrity
4. Document any issues

## Support

For issues or questions:
- Check Supabase documentation
- Review PostgreSQL backup documentation
- Verify database connection settings
- Check backup file permissions

## Important Notes

- Backups include all data, including user passwords (hashed)
- RLS policies are included in schema backup
- Triggers and functions are preserved
- Indexes are recreated during restore
- Large databases may take time to backup/restore
