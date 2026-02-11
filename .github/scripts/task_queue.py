#!/usr/bin/env python3
"""Utilities for a JSONL-based daily task queue."""

import argparse
import json
import os
import sys
from typing import List, Dict, Any


def load_tasks(path: str) -> List[Dict[str, Any]]:
    if not os.path.exists(path):
        return []

    tasks: List[Dict[str, Any]] = []
    with open(path, "r", encoding="utf-8") as fh:
        for index, raw_line in enumerate(fh, start=1):
            line = raw_line.strip()
            if not line:
                continue
            try:
                task = json.loads(line)
            except json.JSONDecodeError as exc:
                raise ValueError(f"Invalid JSON on line {index}: {exc}") from exc

            if not isinstance(task, dict):
                raise ValueError(f"Line {index} must be a JSON object")

            for required in ("id", "file", "commit", "instruction"):
                if not task.get(required):
                    raise ValueError(f"Line {index} missing required field: {required}")

            tasks.append(task)
    return tasks


def write_tasks(path: str, tasks: List[Dict[str, Any]]) -> None:
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        for task in tasks:
            fh.write(json.dumps(task, ensure_ascii=False) + "\n")


def cmd_peek(path: str) -> int:
    tasks = load_tasks(path)
    if not tasks:
        print("{}")
        return 1
    print(json.dumps(tasks[0], ensure_ascii=False))
    return 0


def cmd_consume(path: str) -> int:
    tasks = load_tasks(path)
    if not tasks:
        return 1
    write_tasks(path, tasks[1:])
    return 0


def cmd_validate(path: str) -> int:
    tasks = load_tasks(path)
    print(f"ok: {len(tasks)} tasks")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["peek", "consume", "validate"])
    parser.add_argument("--file", required=True)
    args = parser.parse_args()

    try:
        if args.command == "peek":
            return cmd_peek(args.file)
        if args.command == "consume":
            return cmd_consume(args.file)
        return cmd_validate(args.file)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
