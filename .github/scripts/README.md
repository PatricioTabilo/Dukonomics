# AI Agent Scripts

This directory contains the scripts that power the Dukonomics AI Agent automation system.

## Scripts

### 🤖 apply_task_with_ai.py

Main script that applies AI-generated code improvements.

**Features:**
- Sends file + task to GitHub Models API
- Receives complete modified file (not diffs)
- Validates changes before applying
- Logs metrics for monitoring
- Retry logic with exponential backoff

**Usage:**
```bash
python3 apply_task_with_ai.py \
  --commit "feat(ui): add export button" \
  --task "Add an export button to the main UI frame" \
  --file "UI/MainFrame.lua" \
  --model "gpt-4o-mini" \
  --validate
```

**Exit Codes:**
- `0`: Success
- `1`: File not found
- `2`: API failure
- `3`: No changes
- `4`: Safety check failed
- `5`: Validation failed

### ✏️ create_task.py

Interactive tool for creating new tasks.

**Usage:**
```bash
# Interactive mode (recommended)
python3 create_task.py

# Command line mode
python3 create_task.py \
  --file "UI/MainFrame.lua" \
  --type feat \
  --scope ui \
  --desc "add export button to toolbar" \
  --detailed "Add an export button that allows users to export data" \
  --priority high
```

**Task Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### 📋 task_manager.py

Task queue management utilities.

**Commands:**
```bash
# Show task statistics
python3 task_manager.py stats

# Re-prioritize tasks (bugs first)
python3 task_manager.py prioritize

# Generate tasks from TODO comments
python3 task_manager.py generate

# Validate task file format
python3 task_manager.py validate
```

### 📊 metrics_dashboard.py

View AI agent performance metrics.

**Commands:**
```bash
# Show overall dashboard
python3 metrics_dashboard.py

# Show recent tasks
python3 metrics_dashboard.py --recent 10

# Export to CSV
python3 metrics_dashboard.py --export
```

## Quick Start

### View Current Status
```bash
# Show recent activity
python3 .github/scripts/metrics_dashboard.py --recent 5

# Check task queue
python3 .github/scripts/task_manager.py stats
```

### Manage Tasks
```bash
# Validate task file
python3 .github/scripts/task_manager.py validate

# Prioritize by importance
python3 .github/scripts/task_manager.py prioritize

# Find new tasks in code
python3 .github/scripts/task_manager.py generate
```

### Manual Task Application
```bash
# Apply a specific task manually
python3 .github/scripts/apply_task_with_ai.py \
  --commit "docs(readme): improve installation section" \
  --task "Add detailed installation instructions with screenshots" \
  --file "README.md" \
  --validate
```

## Metrics Files

The scripts generate and consume these files:

- `.github/automation/metrics.jsonl` - Performance metrics
- `.github/automation/daily-heartbeat.log` - Workflow execution log
- `.github/automation/skipped-tasks.log` - Tasks that produced no changes

## Documentation

See [AI_AGENT_DOCS.md](../AI_AGENT_DOCS.md) for complete documentation.

## Requirements

- Python 3.11+
- `requests` package
- `GITHUB_TOKEN` environment variable (for API access)

## Testing

Test the AI script locally:

```bash
# Set your GitHub token
export GITHUB_TOKEN="your_token_here"

# Test on a file
python3 .github/scripts/apply_task_with_ai.py \
  --commit "test: validation" \
  --task "Add a comment at the top of the file" \
  --file "test.lua" \
  --model "gpt-4o-mini"
```

## Support

For issues or questions about these scripts:
- Open an issue: https://github.com/PatricioTabilo/Dukonomics/issues
- Email: pj.tabilo@gmail.com
