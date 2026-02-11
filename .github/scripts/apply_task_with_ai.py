#!/usr/bin/env python3
"""
AI-assisted code improvement script for Dukonomics.
- Reads commit message, task description, and target file from args
- Sends file content + task to GitHub Models API
- Receives back new file content (NOT a diff/patch)
- Writes the new content directly to the file
- Stages the change with git add

This approach avoids all patch/diff formatting issues by having the AI
return the complete modified file instead of a diff.

Enhanced features:
- Retry logic with exponential backoff
- Detailed logging and metrics
- Validation of changes before applying
- Support for multiple AI models
"""

import argparse
import os
import re
import subprocess
import sys
import json
import time
from datetime import datetime

import requests

GITHUB_MODELS_API_URL = "https://models.inference.ai.azure.com/chat/completions"
MODEL = "gpt-4o-mini"
MAX_RETRIES = 3
RETRY_DELAY = 5  # seconds


def read_file(path: str) -> str:
    with open(path, 'r', encoding='utf-8') as fh:
        return fh.read()


def write_file(path: str, content: str):
    with open(path, 'w', encoding='utf-8') as fh:
        fh.write(content)


def log_metric(metric_type: str, data: dict):
    """Log metrics to a JSON file for monitoring."""
    metrics_dir = '.github/automation'
    os.makedirs(metrics_dir, exist_ok=True)
    metrics_file = os.path.join(metrics_dir, 'metrics.jsonl')
    
    metric_entry = {
        'timestamp': datetime.utcnow().isoformat() + 'Z',
        'type': metric_type,
        **data
    }
    
    with open(metrics_file, 'a', encoding='utf-8') as f:
        f.write(json.dumps(metric_entry) + '\n')


def ask_github_models(prompt: str, system_prompt: str, model: str = MODEL) -> str:
    github_token = os.environ.get('GITHUB_TOKEN')
    if not github_token:
        raise RuntimeError('GITHUB_TOKEN not set')

    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {github_token}'
    }

    body = {
        'model': model,
        'messages': [
            {'role': 'system', 'content': system_prompt},
            {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.0,
        'max_tokens': 4000
    }

    # Retry logic with exponential backoff
    last_error = None
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            start_time = time.time()
            resp = requests.post(GITHUB_MODELS_API_URL, headers=headers, json=body, timeout=120)
            elapsed_time = time.time() - start_time
            
            if resp.status_code == 200:
                data = resp.json()
                log_metric('api_call', {
                    'model': model,
                    'attempt': attempt,
                    'elapsed_seconds': round(elapsed_time, 2),
                    'status': 'success'
                })
                return data['choices'][0]['message']['content']
            
            # Log failed attempt
            log_metric('api_call', {
                'model': model,
                'attempt': attempt,
                'elapsed_seconds': round(elapsed_time, 2),
                'status': 'error',
                'status_code': resp.status_code,
                'error': resp.text[:500]
            })
            last_error = RuntimeError(f'GitHub Models API error {resp.status_code}: {resp.text}')
            
            # Retry on server errors (5xx) or rate limiting (429)
            if resp.status_code >= 500 or resp.status_code == 429:
                if attempt < MAX_RETRIES:
                    retry_delay = RETRY_DELAY * (2 ** (attempt - 1))
                    print(f'Attempt {attempt} failed with {resp.status_code}. Retrying in {retry_delay}s...')
                    time.sleep(retry_delay)
                    continue
            
            # Don't retry on client errors (4xx except 429)
            raise last_error
            
        except requests.exceptions.Timeout as e:
            log_metric('api_call', {
                'model': model,
                'attempt': attempt,
                'status': 'timeout'
            })
            last_error = e
            if attempt < MAX_RETRIES:
                retry_delay = RETRY_DELAY * (2 ** (attempt - 1))
                print(f'Attempt {attempt} timed out. Retrying in {retry_delay}s...')
                time.sleep(retry_delay)
                continue
            raise RuntimeError(f'API request timed out after {MAX_RETRIES} attempts')
        except requests.exceptions.RequestException as e:
            log_metric('api_call', {
                'model': model,
                'attempt': attempt,
                'status': 'network_error',
                'error': str(e)[:500]
            })
            last_error = e
            if attempt < MAX_RETRIES:
                retry_delay = RETRY_DELAY * (2 ** (attempt - 1))
                print(f'Attempt {attempt} failed with network error. Retrying in {retry_delay}s...')
                time.sleep(retry_delay)
                continue
            raise RuntimeError(f'Network error after {MAX_RETRIES} attempts: {e}')
    
    # If we get here, all retries failed
    raise last_error


def extract_file_content(reply: str) -> str:
    """Extract the file content from between <FILE> tags."""
    m = re.search(r"<FILE>(.*?)</FILE>", reply, flags=re.S)
    if m:
        content = m.group(1)
        # Strip leading/trailing newline only (preserve internal whitespace)
        if content.startswith('\n'):
            content = content[1:]
        if content.endswith('\n\n'):
            content = content[:-1]
        return content

    # Fallback: look for code block
    m2 = re.search(r"```\w*\n(.*?)```", reply, flags=re.S)
    if m2:
        return m2.group(1)

    return ''


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--commit', required=True)
    parser.add_argument('--task', required=True)
    parser.add_argument('--file', required=True)
    parser.add_argument('--model', default=os.environ.get('COPILOT_MODEL', MODEL))
    parser.add_argument('--validate', action='store_true', help='Validate syntax after changes')
    args = parser.parse_args()

    commit_msg = args.commit
    task_desc = args.task
    file_path = args.file

    print(f'Task: {task_desc}')
    print(f'File: {file_path}')
    print(f'Commit: {commit_msg}')
    print(f'Model: {args.model}')

    start_time = time.time()

    if not os.path.exists(file_path):
        print(f'ERROR: File not found: {file_path}')
        log_metric('task_execution', {
            'file': file_path,
            'commit_msg': commit_msg,
            'status': 'file_not_found',
            'elapsed_seconds': round(time.time() - start_time, 2)
        })
        sys.exit(1)

    original_content = read_file(file_path)
    print(f'File size: {len(original_content)} bytes, {original_content.count(chr(10))} lines')

    system_prompt = (
        "You are a code improvement assistant. You receive a file and a task description. "
        "Return the COMPLETE modified file wrapped in <FILE> and </FILE> tags. "
        "Rules:\n"
        "- Return the ENTIRE file content, not just the changed parts\n"
        "- Make ONLY the changes described in the task\n"
        "- Do NOT add, remove, or modify anything else\n"
        "- Preserve all existing whitespace, indentation, and formatting exactly\n"
        "- Do NOT wrap the output in markdown code blocks\n"
        "- If no changes are needed, return <NO_CHANGE> with explanation\n"
    )

    prompt = (
        f"Task: {task_desc}\n"
        f"Commit message: {commit_msg}\n"
        f"File path: {file_path}\n\n"
        f"Current file content:\n"
        f"<FILE>\n{original_content}</FILE>\n\n"
        f"Return the complete modified file wrapped in <FILE></FILE> tags."
    )

    print('Calling GitHub Models API...')
    try:
        reply = ask_github_models(prompt, system_prompt, model=args.model)
    except Exception as e:
        print(f'API request failed: {e}')
        log_metric('task_execution', {
            'file': file_path,
            'commit_msg': commit_msg,
            'status': 'api_failure',
            'error': str(e)[:500],
            'elapsed_seconds': round(time.time() - start_time, 2)
        })
        sys.exit(2)

    # Check for no-change response
    if '<NO_CHANGE>' in reply:
        print('Model says no changes needed:')
        print(reply)
        log_metric('task_execution', {
            'file': file_path,
            'commit_msg': commit_msg,
            'status': 'no_change',
            'elapsed_seconds': round(time.time() - start_time, 2)
        })
        sys.exit(3)

    new_content = extract_file_content(reply)
    if not new_content:
        print('Could not extract file content from response:')
        print(reply[:2000])
        log_metric('task_execution', {
            'file': file_path,
            'commit_msg': commit_msg,
            'status': 'extraction_failed',
            'elapsed_seconds': round(time.time() - start_time, 2)
        })
        sys.exit(3)

    # Sanity checks
    if new_content.strip() == original_content.strip():
        print('WARNING: New content is identical to original. No changes made.')
        log_metric('task_execution', {
            'file': file_path,
            'commit_msg': commit_msg,
            'status': 'no_change',
            'elapsed_seconds': round(time.time() - start_time, 2)
        })
        sys.exit(3)

    # Check the change isn't too destructive (>50% of lines removed)
    orig_lines = original_content.count('\n')
    new_lines = new_content.count('\n')
    if orig_lines > 5 and new_lines < orig_lines * 0.5:
        print(f'SAFETY: Too many lines removed ({orig_lines} -> {new_lines}). Aborting.')
        log_metric('task_execution', {
            'file': file_path,
            'commit_msg': commit_msg,
            'status': 'safety_check_failed',
            'orig_lines': orig_lines,
            'new_lines': new_lines,
            'elapsed_seconds': round(time.time() - start_time, 2)
        })
        sys.exit(4)

    # Write the new content
    write_file(file_path, new_content)
    print(f'File updated: {file_path} ({orig_lines} -> {new_lines} lines)')

    # Validate syntax if requested (for Lua files)
    if args.validate and file_path.endswith('.lua'):
        try:
            result = subprocess.run(['luac', '-p', file_path], 
                                    capture_output=True, text=True, timeout=10)
            if result.returncode != 0:
                print(f'VALIDATION FAILED: {result.stderr}')
                # Restore original content
                write_file(file_path, original_content)
                log_metric('task_execution', {
                    'file': file_path,
                    'commit_msg': commit_msg,
                    'status': 'validation_failed',
                    'error': result.stderr,
                    'elapsed_seconds': round(time.time() - start_time, 2)
                })
                sys.exit(5)
            print('✓ Lua syntax validation passed')
        except FileNotFoundError:
            print('Warning: luac not found, skipping validation')
        except Exception as e:
            print(f'Warning: Validation error: {e}')

    # Stage the file
    subprocess.check_call(['git', 'add', file_path])
    print(f'Staged: {file_path}')

    # Show what changed
    try:
        diff = subprocess.check_output(['git', 'diff', '--cached', '--stat'], text=True)
        print(f'Changes:\n{diff}')
    except Exception:
        pass

    elapsed = round(time.time() - start_time, 2)
    log_metric('task_execution', {
        'file': file_path,
        'commit_msg': commit_msg,
        'status': 'success',
        'orig_lines': orig_lines,
        'new_lines': new_lines,
        'elapsed_seconds': elapsed
    })
    
    print(f'✅ Task completed successfully in {elapsed}s')
    sys.exit(0)


if __name__ == '__main__':
    main()
