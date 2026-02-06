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
"""

import argparse
import os
import re
import subprocess
import sys
import json

import requests

GITHUB_MODELS_API_URL = "https://models.inference.ai.azure.com/chat/completions"
MODEL = "gpt-4o-mini"


def read_file(path: str) -> str:
    with open(path, 'r', encoding='utf-8') as fh:
        return fh.read()


def write_file(path: str, content: str):
    with open(path, 'w', encoding='utf-8') as fh:
        fh.write(content)


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

    resp = requests.post(GITHUB_MODELS_API_URL, headers=headers, json=body, timeout=120)
    if resp.status_code != 200:
        raise RuntimeError(f'GitHub Models API error {resp.status_code}: {resp.text}')

    data = resp.json()
    return data['choices'][0]['message']['content']


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
    args = parser.parse_args()

    commit_msg = args.commit
    task_desc = args.task
    file_path = args.file

    print(f'Task: {task_desc}')
    print(f'File: {file_path}')
    print(f'Commit: {commit_msg}')

    if not os.path.exists(file_path):
        print(f'ERROR: File not found: {file_path}')
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
        sys.exit(2)

    # Check for no-change response
    if '<NO_CHANGE>' in reply:
        print('Model says no changes needed:')
        print(reply)
        sys.exit(3)

    new_content = extract_file_content(reply)
    if not new_content:
        print('Could not extract file content from response:')
        print(reply[:2000])
        sys.exit(3)

    # Sanity checks
    if new_content.strip() == original_content.strip():
        print('WARNING: New content is identical to original. No changes made.')
        sys.exit(3)

    # Check the change isn't too destructive (>50% of lines removed)
    orig_lines = original_content.count('\n')
    new_lines = new_content.count('\n')
    if orig_lines > 5 and new_lines < orig_lines * 0.5:
        print(f'SAFETY: Too many lines removed ({orig_lines} -> {new_lines}). Aborting.')
        sys.exit(4)

    # Write the new content
    write_file(file_path, new_content)
    print(f'File updated: {file_path} ({orig_lines} -> {new_lines} lines)')

    # Stage the file
    subprocess.check_call(['git', 'add', file_path])
    print(f'Staged: {file_path}')

    # Show what changed
    try:
        diff = subprocess.check_output(['git', 'diff', '--cached', '--stat'], text=True)
        print(f'Changes:\n{diff}')
    except Exception:
        pass

    sys.exit(0)


if __name__ == '__main__':
    main()
