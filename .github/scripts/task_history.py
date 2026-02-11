#!/usr/bin/env python3
"""Append structured task execution history entries as JSONL."""

import argparse
import json
import os
from datetime import datetime, timezone


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--file", required=True, help="JSONL history path")
    parser.add_argument("--status", required=True)
    parser.add_argument("--task-id", default="n/a")
    parser.add_argument("--task-file", default="n/a")
    parser.add_argument("--commit-msg", default="n/a")
    parser.add_argument("--instruction", default="n/a")
    parser.add_argument("--attempt", type=int, default=0)
    parser.add_argument("--ai-exit-code", default="n/a")
    parser.add_argument("--run-id", default=os.environ.get("GITHUB_RUN_ID", "local"))
    parser.add_argument("--run-attempt", default=os.environ.get("GITHUB_RUN_ATTEMPT", "1"))
    args = parser.parse_args()

    os.makedirs(os.path.dirname(args.file) or ".", exist_ok=True)

    entry = {
        "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "status": args.status,
        "task_id": args.task_id,
        "task_file": args.task_file,
        "commit": args.commit_msg,
        "instruction": args.instruction,
        "attempt": args.attempt,
        "ai_exit_code": str(args.ai_exit_code),
        "run_id": str(args.run_id),
        "run_attempt": str(args.run_attempt),
    }

    with open(args.file, "a", encoding="utf-8") as fh:
        fh.write(json.dumps(entry, ensure_ascii=False) + "\n")

    print(f"history appended: {entry['status']} {entry['task_id']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
