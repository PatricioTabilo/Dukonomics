#!/usr/bin/env python3
"""
Simple Copilot-like helper to apply the next task using an AI model.
- Reads commit message and command from args
- Attempts to infer affected files, includes their content in the prompt
- Calls OpenAI Chat Completions API (requires OPENAI_API_KEY env var)
- Expects model to return a unified diff between <PATCH> and </PATCH>
- Applies the patch with `git apply` if present

This script is intentionally conservative: on failure it returns non-zero and leaves
the repository untouched so the workflow can fall back to direct execution.
"""

import argparse
import os
import re
import subprocess
import sys
import json
from typing import List

import requests

# GitHub Models API (available in GitHub Actions with GITHUB_TOKEN)
GITHUB_MODELS_API_URL = "https://models.inference.ai.azure.com/chat/completions"
MODEL = "claude-4.5-sonnet"  # GitHub Models default; also: gpt-4o, claude-3.5-sonnet

# Helpful heuristics to find file paths in a shell command
PATH_REGEX = re.compile(r"(?:\s|\'|\")([\w\.\-/]+\.(?:lua|md|yml|yaml|xml|txt|json|sh))")


def find_paths_in_cmd(cmd: str) -> List[str]:
    matches = PATH_REGEX.findall(cmd)
    # Only return unique, existing paths
    result = []
    for m in matches:
        if m not in result and os.path.exists(m):
            result.append(m)
    return result


def read_files(paths: List[str]) -> str:
    parts = []
    for p in paths:
        try:
            with open(p, 'r', encoding='utf-8') as fh:
                parts.append(f"--- BEGIN FILE: {p} ---\n" + fh.read() + f"\n--- END FILE: {p} ---\n")
        except Exception as e:
            parts.append(f"--- BEGIN FILE: {p} ---\n<UNREADABLE: {e}>\n--- END FILE: {p} ---\n")
    return '\n'.join(parts)


def ask_github_models(prompt: str, model: str = MODEL) -> str:
    """Use GitHub Models API (available in GitHub Actions with GITHUB_TOKEN)"""
    github_token = os.environ.get('GITHUB_TOKEN')
    if not github_token:
        raise RuntimeError('GITHUB_TOKEN not set (should be automatic in GitHub Actions)')

    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {github_token}'
    }

    body = {
        'model': model,
        'messages': [
            { 'role': 'system', 'content': 'You are GitHub Copilot: produce minimal, safe, reviewable patches in unified diff format. Always wrap the patch between <PATCH> and </PATCH> tags. If no patch is needed, respond with <NO_PATCH> and a short explanation.'},
            { 'role': 'user', 'content': prompt }
        ],
        'temperature': 0.0,
        'max_tokens': 2000
    }

    resp = requests.post(GITHUB_MODELS_API_URL, headers=headers, json=body, timeout=90)
    if resp.status_code != 200:
        raise RuntimeError(f'GitHub Models API error {resp.status_code}: {resp.text}')

    data = resp.json()
    # Extract the assistant message
    try:
        msg = data['choices'][0]['message']['content']
        return msg
    except Exception as e:
        raise RuntimeError('Unexpected API response: ' + json.dumps(data))


def extract_patch(text: str) -> str:
    m = re.search(r"<PATCH>(.*?)</PATCH>", text, flags=re.S)
    if m:
        return m.group(1).strip()
    # Some models may return diffs without tags; try to find unified diff header
    m2 = re.search(r"(^---\s+a/.*?\n\+\+\+\s+b/.*?\n(?:[\s\S]*))", text, flags=re.M)
    if m2:
        return m2.group(1).strip()
    return ''


def apply_patch(patch: str) -> bool:
    # write patch to temp file
    import tempfile
    fd, path = tempfile.mkstemp(prefix='copilot_patch_', suffix='.diff')
    os.write(fd, patch.encode('utf-8'))
    os.close(fd)

    try:
        # Try git apply (doesn't commit)
        subprocess.check_call(['git', 'apply', '--index', path])
        print('Patch applied (git apply --index)')
        return True
    except subprocess.CalledProcessError as e:
        print(f'git apply failed: {e}')
        # Show unified diff attempt for debugging
        try:
            print(subprocess.check_output(['git', 'apply', '--check', path], stderr=subprocess.STDOUT).decode())
        except Exception:
            pass
        return False
    finally:
        try:
            os.remove(path)
        except Exception:
            pass


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--commit', required=True)
    parser.add_argument('--cmd', required=True)
    parser.add_argument('--model', default=os.environ.get('COPILOT_MODEL', MODEL))
    args = parser.parse_args()

    commit_msg = args.commit
    cmd = args.cmd

    print('AI-Assisted Apply: commit=', commit_msg)
    print('Command: ', cmd)

    paths = find_paths_in_cmd(cmd)
    print('Detected paths:', paths)

    file_contents = read_files(paths) if paths else ''

    prompt = f"Commit message: {commit_msg}\nShell command: {cmd}\n"
    if file_contents:
        prompt += "\nRepository files provided:\n" + file_contents

    prompt += "\n\nGoal: Produce a minimal unified diff patch that implements the change described by the shell command, or, if appropriate, output a short shell snippet to run instead. ALWAYS wrap the patch between <PATCH> and </PATCH> tags. If no patch is needed, respond with <NO_PATCH> and a short explanation. Do not modify unrelated files. Keep changes minimal and safe."

    print('Calling GitHub Models API...')
    try:
        reply = ask_github_models(prompt, model=args.model)
    except Exception as e:
        print('GitHub Models API request failed:', e)
        sys.exit(2)

    print('Model reply (truncated):\n', reply[:1000])

    patch = extract_patch(reply)
    if not patch:
        print('No patch extracted from AI response. Response was:')
        print(reply)
        sys.exit(3)

    print('Applying patch...')
    ok = apply_patch(patch)
    if not ok:
        print('Failed to apply patch')
        sys.exit(4)

    print('Patch applied successfully. You can inspect changes with `git diff`.')
    sys.exit(0)


if __name__ == '__main__':
    main()
