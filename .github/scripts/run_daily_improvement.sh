#!/usr/bin/env bash
set -euo pipefail

TASK_QUEUE_FILE="${TASK_QUEUE_FILE:-.github/automation/daily_tasks.jsonl}"
HISTORY_FILE="${HISTORY_FILE:-.github/automation/task_history.jsonl}"
COPILOT_MODEL="${COPILOT_MODEL:-gpt-4o-mini}"

if [ ! -f "$TASK_QUEUE_FILE" ]; then
  echo "No task queue found: $TASK_QUEUE_FILE"
  exit 1
fi

python3 .github/scripts/task_queue.py validate --file "$TASK_QUEUE_FILE"
python3 -m pip install --upgrade pip requests >/dev/null

selected_commit_msg=""
selected_file_path=""
selected_task_desc=""
selected_status=""
selected_task_id=""

for attempt in 1 2 3 4 5; do
  set +e
  task_json=$(python3 .github/scripts/task_queue.py peek --file "$TASK_QUEUE_FILE")
  task_peek_code=$?
  set -e

  if [ "$task_peek_code" -ne 0 ] || [ "$task_json" = "{}" ]; then
    echo "No pending tasks left in $TASK_QUEUE_FILE"
    break
  fi

  task_id=$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["id"])' "$task_json")
  file_path=$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["file"])' "$task_json")
  commit_msg=$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["commit"])' "$task_json")
  task_desc=$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["instruction"])' "$task_json")

  echo "Attempt $attempt"
  echo "Task ID: $task_id"
  echo "File to modify: $file_path"
  echo "Applying task with commit message: $commit_msg"
  echo "Task description: $task_desc"

  set +e
  python3 .github/scripts/apply_task_with_ai.py --commit "$commit_msg" --task "$task_desc" --file "$file_path" --model "$COPILOT_MODEL"
  ai_exit_code=$?
  set -e

  if [ "$ai_exit_code" -eq 0 ]; then
    echo "✅ GitHub Copilot applied changes successfully"
    selected_commit_msg="$commit_msg"
    selected_file_path="$file_path"
    selected_task_desc="$task_desc"
    selected_status="ai_success"
    selected_task_id="$task_id"
    python3 .github/scripts/task_history.py --file "$HISTORY_FILE" --status "completed" --task-id "$task_id" --task-file "$file_path" --commit-msg "$commit_msg" --instruction "$task_desc" --attempt "$attempt" --ai-exit-code "$ai_exit_code"
    python3 .github/scripts/task_queue.py consume --file "$TASK_QUEUE_FILE" || true
    break
  fi

  if [ "$ai_exit_code" -eq 3 ]; then
    echo "⚠️ No changes were produced for this task. Skipping it and trying the next task."
    mkdir -p .github/automation
    {
      echo "- $(date -u +'%Y-%m-%dT%H:%M:%SZ') | skipped-no-change | ${task_id} | ${commit_msg} | ${file_path}"
    } >> .github/automation/skipped-tasks.log
    python3 .github/scripts/task_history.py --file "$HISTORY_FILE" --status "skipped_no_change" --task-id "$task_id" --task-file "$file_path" --commit-msg "$commit_msg" --instruction "$task_desc" --attempt "$attempt" --ai-exit-code "$ai_exit_code"
    python3 .github/scripts/task_queue.py consume --file "$TASK_QUEUE_FILE" || true
    continue
  fi

  echo "⚠️ Copilot/Models step failed with code $ai_exit_code. Applying fallback heartbeat so automation keeps running."
  mkdir -p .github/automation
  {
    echo "- $(date -u +'%Y-%m-%dT%H:%M:%SZ') | fallback | ${task_id} | ${commit_msg} | ${file_path}"
  } >> .github/automation/daily-heartbeat.log
  selected_commit_msg="chore(automation): fallback heartbeat - ${commit_msg}"
  selected_file_path="$file_path"
  selected_task_desc="$task_desc"
  selected_status="fallback"
  selected_task_id="$task_id"
  python3 .github/scripts/task_history.py --file "$HISTORY_FILE" --status "fallback" --task-id "$task_id" --task-file "$file_path" --commit-msg "$commit_msg" --instruction "$task_desc" --attempt "$attempt" --ai-exit-code "$ai_exit_code"
  python3 .github/scripts/task_queue.py consume --file "$TASK_QUEUE_FILE" || true
  break
done

if [ -z "$selected_status" ]; then
  mkdir -p .github/automation
  {
    echo "- $(date -u +'%Y-%m-%dT%H:%M:%SZ') | no-applicable-task"
  } >> .github/automation/daily-heartbeat.log
  selected_commit_msg="chore(automation): heartbeat (no applicable AI task)"
  selected_file_path="n/a"
  selected_task_desc="n/a"
  selected_status="heartbeat"
  selected_task_id="n/a"
  python3 .github/scripts/task_history.py --file "$HISTORY_FILE" --status "heartbeat_no_applicable_task" --task-id "n/a" --task-file "n/a" --commit-msg "$selected_commit_msg" --instruction "n/a" --attempt 0 --ai-exit-code "n/a"
fi

echo "Selected status: $selected_status"
echo "Selected task id: $selected_task_id"
echo "Selected file: $selected_file_path"
echo "Selected task: $selected_task_desc"
echo "COMMIT_MSG=$selected_commit_msg" >> "$GITHUB_ENV"
