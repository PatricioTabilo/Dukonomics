#!/usr/bin/env python3
"""
Task Manager for Dukonomics AI Agent.
Provides utilities for managing, prioritizing, and analyzing tasks.

Usage:
  task_manager.py stats              # Show statistics about tasks
  task_manager.py prioritize         # Re-order tasks by priority
  task_manager.py generate           # Generate new tasks based on codebase analysis
  task_manager.py validate           # Validate task file format
"""

import argparse
import os
import re
import subprocess
import sys
from collections import Counter
from datetime import datetime


def parse_task_file(filepath='daily_tasks.sh'):
    """Parse the task file and return list of tasks."""
    if not os.path.exists(filepath):
        return []
    
    tasks = []
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if line.startswith('# task:'):
            # Parse task line
            match = re.match(r'^# task:\s+(.+?)\s+-\s+(.+)$', line)
            if match:
                file_path = match.group(1)
                commit_msg = match.group(2)
                description = ''
                
                # Get description from next line
                if i + 1 < len(lines):
                    description = lines[i + 1].strip()
                
                tasks.append({
                    'file': file_path,
                    'commit_msg': commit_msg,
                    'description': description,
                    'line_num': i + 1
                })
                i += 2  # Skip description line
            else:
                i += 1
        else:
            i += 1
    
    return tasks


def get_task_stats(tasks):
    """Get statistics about tasks."""
    if not tasks:
        return None
    
    # Parse commit messages to get type and scope
    types = []
    scopes = []
    files = []
    
    for task in tasks:
        match = re.match(r'^(\w+)\(([^)]+)\):', task['commit_msg'])
        if match:
            types.append(match.group(1))
            scopes.append(match.group(2))
        
        files.append(task['file'])
    
    return {
        'total_tasks': len(tasks),
        'types': Counter(types),
        'scopes': Counter(scopes),
        'files': Counter(files)
    }


def print_stats(filepath='daily_tasks.sh'):
    """Print statistics about tasks."""
    tasks = parse_task_file(filepath)
    
    if not tasks:
        print('No tasks found')
        return
    
    stats = get_task_stats(tasks)
    
    print(f'\n📊 Task Statistics')
    print(f'{"="*60}')
    print(f'Total tasks: {stats["total_tasks"]}')
    print()
    
    print('Types:')
    for task_type, count in stats['types'].most_common():
        print(f'  {task_type:15} {count:3} tasks')
    print()
    
    print('Top 10 scopes:')
    for scope, count in stats['scopes'].most_common(10):
        print(f'  {scope:20} {count:3} tasks')
    print()
    
    print('Top 10 files:')
    for file_path, count in stats['files'].most_common(10):
        print(f'  {file_path:40} {count:3} tasks')
    print()


def get_file_change_frequency():
    """Get how often each file has been changed recently."""
    try:
        # Get commits from last 30 days
        result = subprocess.run(
            ['git', 'log', '--since=30.days.ago', '--name-only', '--pretty=format:', '--'],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode == 0:
            files = [f for f in result.stdout.split('\n') if f.strip()]
            return Counter(files)
    except Exception as e:
        print(f'Warning: Could not get file change frequency: {e}')
    
    return Counter()


def prioritize_tasks(filepath='daily_tasks.sh', output_file=None):
    """Re-order tasks by priority."""
    tasks = parse_task_file(filepath)
    
    if not tasks:
        print('No tasks found')
        return
    
    # Priority scoring
    priority_map = {
        'fix': 100,    # Bugs first
        'feat': 80,    # Features next
        'refactor': 60,  # Then refactoring
        'docs': 40,    # Documentation
        'style': 20,   # Style last
        'chore': 10    # Chores last
    }
    
    file_frequency = get_file_change_frequency()
    
    # Score each task
    for task in tasks:
        score = 0
        
        # Type-based priority
        match = re.match(r'^(\w+)\(', task['commit_msg'])
        if match:
            task_type = match.group(1)
            score += priority_map.get(task_type, 50)
        
        # Boost recently changed files (they're active)
        file_changes = file_frequency.get(task['file'], 0)
        score += file_changes * 5
        
        task['priority_score'] = score
    
    # Sort by priority
    tasks_sorted = sorted(tasks, key=lambda t: t['priority_score'], reverse=True)
    
    # Write back to file
    output = output_file or filepath
    with open(output, 'w', encoding='utf-8') as f:
        for task in tasks_sorted:
            f.write(f"# task: {task['file']} - {task['commit_msg']}\n")
            f.write(f"{task['description']}\n")
            f.write('\n')
    
    print(f'✅ Prioritized {len(tasks)} tasks in {output}')
    print(f'Top 5 priorities:')
    for i, task in enumerate(tasks_sorted[:5], 1):
        print(f'  {i}. [{task["priority_score"]:3}] {task["commit_msg"][:60]}')


def validate_tasks(filepath='daily_tasks.sh'):
    """Validate task file format."""
    print(f'Validating {filepath}...')
    
    tasks = parse_task_file(filepath)
    errors = []
    
    for task in tasks:
        # Check file exists
        if not os.path.exists(task['file']):
            errors.append(f"Line {task['line_num']}: File not found: {task['file']}")
        
        # Check commit message format
        if not re.match(r'^\w+\([^)]+\):', task['commit_msg']):
            errors.append(f"Line {task['line_num']}: Invalid commit format: {task['commit_msg']}")
        
        # Check description is not empty
        if not task['description']:
            errors.append(f"Line {task['line_num']}: Empty description for task")
    
    if errors:
        print(f'\n❌ Found {len(errors)} errors:')
        for error in errors:
            print(f'  {error}')
        return False
    else:
        print(f'\n✅ All {len(tasks)} tasks are valid')
        return True


def generate_tasks_from_todos(filepath='daily_tasks.sh'):
    """Generate tasks from TODO/FIXME comments in code."""
    print('Scanning codebase for TODO/FIXME comments...')
    
    try:
        # Find all Lua files
        result = subprocess.run(
            ['git', 'ls-files', '*.lua'],
            capture_output=True,
            text=True,
            timeout=10
        )
        
        if result.returncode != 0:
            print('Error: Could not list files')
            return
        
        lua_files = result.stdout.strip().split('\n')
        new_tasks = []
        
        for file_path in lua_files:
            if not os.path.exists(file_path):
                continue
            
            with open(file_path, 'r', encoding='utf-8') as f:
                for line_num, line in enumerate(f, 1):
                    # Look for TODO or FIXME comments
                    if 'TODO:' in line or 'FIXME:' in line:
                        comment = line.strip().lstrip('-').strip()
                        
                        # Determine type
                        task_type = 'fix' if 'FIXME' in comment else 'feat'
                        
                        # Get scope from file path
                        scope = os.path.dirname(file_path).replace('/', '-') or 'core'
                        
                        # Create task
                        new_tasks.append({
                            'file': file_path,
                            'commit_msg': f'{task_type}({scope}): {comment[:60]}',
                            'description': comment
                        })
        
        if new_tasks:
            print(f'\nFound {len(new_tasks)} TODO/FIXME comments')
            
            # Append to task file
            with open(filepath, 'a', encoding='utf-8') as f:
                f.write('\n# Generated from TODO/FIXME comments\n')
                for task in new_tasks:
                    f.write(f"# task: {task['file']} - {task['commit_msg']}\n")
                    f.write(f"{task['description']}\n")
                    f.write('\n')
            
            print(f'✅ Added {len(new_tasks)} tasks to {filepath}')
        else:
            print('No TODO/FIXME comments found')
    
    except Exception as e:
        print(f'Error: {e}')


def main():
    parser = argparse.ArgumentParser(
        description='Task Manager for Dukonomics AI Agent',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument('command', choices=['stats', 'prioritize', 'generate', 'validate'],
                        help='Command to run')
    parser.add_argument('--file', default='daily_tasks.sh',
                        help='Path to task file (default: daily_tasks.sh)')
    parser.add_argument('--output', help='Output file for prioritize command')
    
    args = parser.parse_args()
    
    if args.command == 'stats':
        print_stats(args.file)
    elif args.command == 'prioritize':
        prioritize_tasks(args.file, args.output)
    elif args.command == 'generate':
        generate_tasks_from_todos(args.file)
    elif args.command == 'validate':
        if not validate_tasks(args.file):
            sys.exit(1)


if __name__ == '__main__':
    main()
