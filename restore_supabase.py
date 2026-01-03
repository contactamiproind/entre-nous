#!/usr/bin/env python3
"""
Supabase Restore Script
=======================
This script restores Supabase database backups created by backup_supabase.py

Usage: python restore_supabase.py <backup_directory>

Requirements:
- Python 3.6+
- psql (PostgreSQL client tools)
- Backup directory created by backup_supabase.py
"""

import os
import sys
import subprocess
from pathlib import Path
from getpass import getpass


class Colors:
    """ANSI color codes for terminal output"""
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


def check_psql():
    """Check if psql is installed"""
    try:
        result = subprocess.run(['psql', '--version'], 
                              capture_output=True, text=True)
        if result.returncode == 0:
            print_info(f"PostgreSQL tools found: {result.stdout.strip()}")
            return True
    except FileNotFoundError:
        pass
    
    print_error("psql not found!")
    print_error("Please install PostgreSQL client tools")
    return False


def get_db_credentials():
    """Prompt user for database credentials"""
    print()
    print_warning("Please provide database connection details for restore:")
    print()
    
    db_host = input("Database Host: ").strip()
    db_name = input("Database Name (default: postgres): ").strip() or "postgres"
    db_user = input("Database User (default: postgres): ").strip() or "postgres"
    db_port = input("Database Port (default: 5432): ").strip() or "5432"
    db_password = getpass("Database Password: ")
    
    if not db_host or not db_password:
        print_error("Host and password are required!")
        return None
    
    return {
        'host': db_host,
        'name': db_name,
        'user': db_user,
        'port': db_port,
        'password': db_password
    }


def run_psql(db_creds, sql_file):
    """Run psql to restore from SQL file"""
    cmd = [
        'psql',
        '-h', db_creds['host'],
        '-U', db_creds['user'],
        '-d', db_creds['name'],
        '-p', db_creds['port'],
        '-f', str(sql_file)
    ]
    
    env = os.environ.copy()
    env['PGPASSWORD'] = db_creds['password']
    
    try:
        result = subprocess.run(cmd, env=env, capture_output=True, text=True)
        if result.returncode == 0:
            return True
        else:
            print_error(f"Restore failed: {result.stderr}")
            return False
    except Exception as e:
        print_error(f"Error running psql: {str(e)}")
        return False


def main():
    """Main restore function"""
    print()
    print("=" * 50)
    print("Supabase Restore Script")
    print("=" * 50)
    print()
    
    if len(sys.argv) < 2:
        print_error("Usage: python restore_supabase.py <backup_directory>")
        print_info("Example: python restore_supabase.py backups/20260103_153000")
        sys.exit(1)
    
    backup_dir = Path(sys.argv[1])
    
    if not backup_dir.exists():
        print_error(f"Backup directory not found: {backup_dir}")
        sys.exit(1)
    
    if not check_psql():
        sys.exit(1)
    
    # Check available backup files
    schema_file = backup_dir / 'schema.sql'
    data_file = backup_dir / 'data.sql'
    complete_file = backup_dir / 'complete_backup.sql'
    
    available_files = []
    if complete_file.exists():
        available_files.append(('complete', complete_file, 'Complete backup (schema + data)'))
    if schema_file.exists():
        available_files.append(('schema', schema_file, 'Schema only'))
    if data_file.exists():
        available_files.append(('data', data_file, 'Data only'))
    
    if not available_files:
        print_error("No backup files found in directory!")
        sys.exit(1)
    
    print_info("Available backup files:")
    for i, (key, file, desc) in enumerate(available_files, 1):
        print(f"  {i}. {desc} - {file.name}")
    
    print()
    choice = input("Select file to restore (1-{}): ".format(len(available_files))).strip()
    
    try:
        choice_idx = int(choice) - 1
        if choice_idx < 0 or choice_idx >= len(available_files):
            raise ValueError()
        selected_key, selected_file, selected_desc = available_files[choice_idx]
    except (ValueError, IndexError):
        print_error("Invalid selection!")
        sys.exit(1)
    
    print()
    print_warning(f"You are about to restore: {selected_desc}")
    print_warning("This will modify your database!")
    confirm = input("Are you sure you want to continue? (yes/no): ").strip().lower()
    
    if confirm not in ['yes', 'y']:
        print_info("Restore cancelled")
        sys.exit(0)
    
    db_creds = get_db_credentials()
    if not db_creds:
        sys.exit(1)
    
    print()
    print_info(f"Restoring from: {selected_file}")
    
    success = run_psql(db_creds, selected_file)
    
    print()
    if success:
        print("=" * 50)
        print_info("Restore completed successfully!")
        print("=" * 50)
    else:
        print_error("Restore failed!")
        sys.exit(1)


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print()
        print_warning("Restore cancelled by user")
        sys.exit(1)
    except Exception as e:
        print_error(f"Unexpected error: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
