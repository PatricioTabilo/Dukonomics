#!/usr/bin/env python3
"""
Interactive task creator for Dukonomics AI Agent.
Makes it easy to add new tasks to the queue.

Usage:
  create_task.py                    # Interactive mode
  create_task.py --file UI/MainFrame.lua --type feat --scope ui --desc "Add export button"
"""

import argparse
import os
import sys
import re


TASK_TYPES = {
    'feat': 'New feature',
    'fix': 'Bug fix',
    'docs': 'Documentation',
    'style': 'Code style/formatting',
    'refactor': 'Code refactoring',
    'test': 'Tests',
    'chore': 'Maintenance'
}


def validate_file_exists(filepath):
    """Check if file exists in repository."""
    if not os.path.exists(filepath):
        print(f'⚠️  Warning: File {filepath} does not exist')
        response = input('Continue anyway? (y/n): ')
        return response.lower() == 'y'
    return True


def get_scope_from_file(filepath):
    """Suggest a scope based on file path."""
    parts = filepath.split('/')
    if len(parts) > 1:
        scope = parts[0].lower()
        if scope in ['ui', 'core', 'data', 'handlers', 'services']:
            return scope
    return 'core'


def interactive_mode():
    """Interactive task creation."""
    print('\n🤖 AI Agent Task Creator\n')
    print('This will help you create a new task for the AI agent.\n')
    
    # Get file path
    while True:
        file_path = input('File path (e.g., UI/MainFrame.lua): ').strip()
        if not file_path:
            print('❌ File path is required')
            continue
        if validate_file_exists(file_path):
            break
    
    # Get task type
    print('\nTask type:')
    for i, (key, desc) in enumerate(TASK_TYPES.items(), 1):
        print(f'  {i}. {key:10} - {desc}')
    
    while True:
        type_choice = input('\nSelect type (1-7): ').strip()
        try:
            type_idx = int(type_choice) - 1
            if 0 <= type_idx < len(TASK_TYPES):
                task_type = list(TASK_TYPES.keys())[type_idx]
                break
        except ValueError:
            pass
        print('❌ Invalid choice')
    
    # Get scope
    suggested_scope = get_scope_from_file(file_path)
    scope = input(f'\nScope [{suggested_scope}]: ').strip() or suggested_scope
    
    # Get short description
    print('\nShort description (for commit message):')
    print('Example: "add export button to toolbar"')
    short_desc = input('> ').strip()
    while not short_desc:
        print('❌ Description is required')
        short_desc = input('> ').strip()
    
    # Get detailed description
    print('\nDetailed description (what should the AI do?):')
    print('Example: "Add an export button to the main UI frame toolbar that allows users to export transaction data to CSV format"')
    detailed_desc = input('> ').strip()
    while not detailed_desc:
        print('❌ Detailed description is required')
        detailed_desc = input('> ').strip()
    
    # Generate task
    commit_msg = f'{task_type}({scope}): {short_desc}'
    
    print('\n' + '='*60)
    print('Task Preview:')
    print('='*60)
    print(f'File: {file_path}')
    print(f'Commit: {commit_msg}')
    print(f'Description: {detailed_desc}')
    print('='*60)
    
    # Confirm
    confirm = input('\nAdd this task? (y/n): ').strip().lower()
    if confirm != 'y':
        print('❌ Task creation cancelled')
        return
    
    # Add to queue
    add_task_to_queue(file_path, commit_msg, detailed_desc)


def add_task_to_queue(file_path, commit_msg, detailed_desc, prepend=False, task_file='daily_tasks.sh'):
    """Add a task to the queue file."""
    task_entry = f'# task: {file_path} - {commit_msg}\n{detailed_desc}\n\n'
    
    if not os.path.exists(task_file):
        # Create new file
        with open(task_file, 'w', encoding='utf-8') as f:
            f.write(task_entry)
        print(f'✅ Created {task_file} with new task')
        return
    
    if prepend:
        # Add to beginning (high priority)
        with open(task_file, 'r', encoding='utf-8') as f:
            existing = f.read()
        with open(task_file, 'w', encoding='utf-8') as f:
            f.write(task_entry + existing)
        print(f'✅ Added task to beginning of {task_file} (high priority)')
    else:
        # Append to end (normal priority)
        with open(task_file, 'a', encoding='utf-8') as f:
            f.write(task_entry)
        print(f'✅ Added task to {task_file}')


def command_line_mode(args):
    """Create task from command line arguments."""
    if not args.file:
        print('❌ --file is required')
        sys.exit(1)
    
    if not args.type:
        print('❌ --type is required')
        sys.exit(1)
    
    if args.type not in TASK_TYPES:
        print(f'❌ Invalid type. Must be one of: {", ".join(TASK_TYPES.keys())}')
        sys.exit(1)
    
    if not args.desc:
        print('❌ --desc is required')
        sys.exit(1)
    
    # Validate file
    if not validate_file_exists(args.file):
        sys.exit(1)
    
    # Get scope
    scope = args.scope or get_scope_from_file(args.file)
    
    # Get detailed description
    detailed = args.detailed or args.desc
    
    # Generate commit message
    commit_msg = f'{args.type}({scope}): {args.desc}'
    
    # Add to queue
    add_task_to_queue(args.file, commit_msg, detailed, args.priority == 'high', args.task_file)
    
    print(f'\n📝 Task created:')
    print(f'   File: {args.file}')
    print(f'   Commit: {commit_msg}')


def main():
    parser = argparse.ArgumentParser(
        description='Create tasks for the AI agent',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument('--file', help='File path to modify')
    parser.add_argument('--type', choices=list(TASK_TYPES.keys()), help='Task type')
    parser.add_argument('--scope', help='Task scope (e.g., ui, core, data)')
    parser.add_argument('--desc', help='Short description for commit message')
    parser.add_argument('--detailed', help='Detailed description (defaults to --desc)')
    parser.add_argument('--priority', choices=['normal', 'high'], default='normal',
                        help='Priority (high=prepend to queue)')
    parser.add_argument('--task-file', default='daily_tasks.sh',
                        help='Task file path (default: daily_tasks.sh)')
    
    args = parser.parse_args()
    
    # If any required args are missing, use interactive mode
    if not all([args.file, args.type, args.desc]):
        interactive_mode()
    else:
        command_line_mode(args)


if __name__ == '__main__':
    main()
