#!/usr/bin/env python3
"""
Dashboard for viewing AI Agent metrics and performance.
Analyzes the metrics.jsonl file to show insights about task execution.

Usage:
  metrics_dashboard.py               # Show overall dashboard
  metrics_dashboard.py --recent 10   # Show last 10 tasks
  metrics_dashboard.py --export      # Export to CSV
"""

import argparse
import json
import os
from datetime import datetime, timedelta
from collections import defaultdict


def load_metrics(filepath='.github/automation/metrics.jsonl'):
    """Load metrics from JSONL file."""
    if not os.path.exists(filepath):
        return []
    
    metrics = []
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    metrics.append(json.loads(line))
                except json.JSONDecodeError:
                    continue
    
    return metrics


def parse_timestamp(ts_str):
    """Parse ISO timestamp."""
    try:
        return datetime.fromisoformat(ts_str.replace('Z', '+00:00'))
    except:
        return None


def show_dashboard(metrics):
    """Show overall dashboard."""
    if not metrics:
        print('No metrics found')
        return
    
    # Filter by metric type
    api_calls = [m for m in metrics if m.get('type') == 'api_call']
    task_executions = [m for m in metrics if m.get('type') == 'task_execution']
    
    print('\n' + '='*70)
    print('🤖 AI AGENT DASHBOARD')
    print('='*70)
    
    # Overall stats
    print(f'\n📈 Overall Statistics')
    print(f'  Total API calls: {len(api_calls)}')
    print(f'  Total task executions: {len(task_executions)}')
    
    # API Call stats
    if api_calls:
        print(f'\n🔌 API Call Performance')
        
        successful_calls = [m for m in api_calls if m.get('status') == 'success']
        failed_calls = [m for m in api_calls if m.get('status') in ['error', 'timeout', 'network_error']]
        
        success_rate = len(successful_calls) / len(api_calls) * 100 if api_calls else 0
        print(f'  Success rate: {success_rate:.1f}% ({len(successful_calls)}/{len(api_calls)})')
        
        if successful_calls:
            avg_time = sum(m.get('elapsed_seconds', 0) for m in successful_calls) / len(successful_calls)
            print(f'  Average response time: {avg_time:.2f}s')
        
        # Retry analysis
        retry_counts = defaultdict(int)
        for call in api_calls:
            attempt = call.get('attempt', 1)
            retry_counts[attempt] += 1
        
        if len(retry_counts) > 1:
            print(f'  Retries needed:')
            for attempt, count in sorted(retry_counts.items()):
                print(f'    Attempt {attempt}: {count} calls')
        
        # Error breakdown
        if failed_calls:
            print(f'\n  ⚠️  Errors ({len(failed_calls)} total):')
            error_types = defaultdict(int)
            for call in failed_calls:
                status = call.get('status', 'unknown')
                error_types[status] += 1
            
            for error_type, count in error_types.items():
                print(f'    {error_type}: {count}')
    
    # Task execution stats
    if task_executions:
        print(f'\n✅ Task Execution Summary')
        
        status_counts = defaultdict(int)
        for task in task_executions:
            status = task.get('status', 'unknown')
            status_counts[status] += 1
        
        total = len(task_executions)
        for status, count in sorted(status_counts.items(), key=lambda x: x[1], reverse=True):
            percentage = count / total * 100
            print(f'  {status:20} {count:4} ({percentage:5.1f}%)')
        
        # Time statistics
        successful_tasks = [t for t in task_executions if t.get('status') == 'success']
        if successful_tasks:
            times = [t.get('elapsed_seconds', 0) for t in successful_tasks]
            avg_time = sum(times) / len(times)
            max_time = max(times)
            min_time = min(times)
            
            print(f'\n  ⏱️  Execution times (successful tasks):')
            print(f'    Average: {avg_time:.2f}s')
            print(f'    Min: {min_time:.2f}s')
            print(f'    Max: {max_time:.2f}s')
        
        # File statistics
        file_changes = defaultdict(int)
        for task in successful_tasks:
            file_path = task.get('file', 'unknown')
            file_changes[file_path] += 1
        
        if file_changes:
            print(f'\n  📁 Most modified files:')
            for file_path, count in sorted(file_changes.items(), key=lambda x: x[1], reverse=True)[:5]:
                print(f'    {file_path:40} {count} times')
    
    # Recent activity
    recent_tasks = sorted(task_executions, key=lambda t: t.get('timestamp', ''), reverse=True)[:5]
    if recent_tasks:
        print(f'\n🕒 Recent Tasks (last 5)')
        for task in recent_tasks:
            timestamp = parse_timestamp(task.get('timestamp', ''))
            status = task.get('status', 'unknown')
            file_path = task.get('file', 'unknown')
            elapsed = task.get('elapsed_seconds', 0)
            
            if timestamp:
                time_str = timestamp.strftime('%Y-%m-%d %H:%M')
            else:
                time_str = 'unknown'
            
            status_icon = '✅' if status == 'success' else '❌'
            print(f'  {status_icon} {time_str} | {status:15} | {elapsed:5.1f}s | {os.path.basename(file_path)}')
    
    print('\n' + '='*70)


def show_recent(metrics, count=10):
    """Show recent task executions."""
    task_executions = [m for m in metrics if m.get('type') == 'task_execution']
    recent = sorted(task_executions, key=lambda t: t.get('timestamp', ''), reverse=True)[:count]
    
    if not recent:
        print('No recent tasks found')
        return
    
    print(f'\n📋 Last {len(recent)} Tasks\n')
    print(f'{"Time":16} {"Status":15} {"Duration":8} {"File":40}')
    print('-' * 80)
    
    for task in recent:
        timestamp = parse_timestamp(task.get('timestamp', ''))
        status = task.get('status', 'unknown')
        file_path = task.get('file', 'unknown')
        elapsed = task.get('elapsed_seconds', 0)
        
        if timestamp:
            time_str = timestamp.strftime('%Y-%m-%d %H:%M')
        else:
            time_str = 'unknown'
        
        file_name = os.path.basename(file_path)
        print(f'{time_str:16} {status:15} {elapsed:7.2f}s {file_name:40}')
        
        # Show commit message if available
        commit_msg = task.get('commit_msg', '')
        if commit_msg:
            print(f'  └─ {commit_msg[:70]}')


def export_to_csv(metrics, output='metrics.csv'):
    """Export metrics to CSV."""
    import csv
    
    task_executions = [m for m in metrics if m.get('type') == 'task_execution']
    
    if not task_executions:
        print('No task executions to export')
        return
    
    with open(output, 'w', newline='', encoding='utf-8') as f:
        fieldnames = ['timestamp', 'status', 'file', 'commit_msg', 'elapsed_seconds', 
                      'orig_lines', 'new_lines']
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction='ignore')
        
        writer.writeheader()
        for task in task_executions:
            writer.writerow(task)
    
    print(f'✅ Exported {len(task_executions)} task executions to {output}')


def main():
    parser = argparse.ArgumentParser(
        description='AI Agent Metrics Dashboard',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument('--recent', type=int, metavar='N',
                        help='Show last N tasks')
    parser.add_argument('--export', action='store_true',
                        help='Export metrics to CSV')
    parser.add_argument('--output', default='metrics.csv',
                        help='Output file for export (default: metrics.csv)')
    parser.add_argument('--metrics-file', default='.github/automation/metrics.jsonl',
                        help='Path to metrics file')
    
    args = parser.parse_args()
    
    metrics = load_metrics(args.metrics_file)
    
    if args.export:
        export_to_csv(metrics, args.output)
    elif args.recent:
        show_recent(metrics, args.recent)
    else:
        show_dashboard(metrics)


if __name__ == '__main__':
    main()
