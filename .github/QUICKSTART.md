# AI Agent Quick Start Guide

This guide will help you get started with the Dukonomics AI Agent system for daily automated code improvements.

## What is the AI Agent?

The AI Agent is an automated system that:
- ✅ Runs twice daily via GitHub Actions
- ✅ Applies code improvements from a task queue
- ✅ Uses GitHub Models API (GPT-4) for intelligent code generation
- ✅ Automatically commits, tags, and versions changes
- ✅ Keeps your CurseForge addon fresh and visible

## How It Works

```
1. Schedule triggers (19:00 UTC & 02:00 UTC)
   ↓
2. Read next task from daily_tasks.sh
   ↓
3. Send file + task to AI
   ↓
4. Apply changes & validate
   ↓
5. Commit, version bump, and push
   ↓
6. Create git tag for release
```

## Getting Started

### 1. Check Current Status

View what the agent has been doing:

```bash
# Show recent activity
python3 .github/scripts/metrics_dashboard.py --recent 10

# Show overall statistics
python3 .github/scripts/task_manager.py stats
```

### 2. Validate Your Task Queue

Ensure your tasks are properly formatted:

```bash
python3 .github/scripts/task_manager.py validate
```

### 3. Prioritize Tasks

Re-order tasks by importance (bugs first, then features):

```bash
python3 .github/scripts/task_manager.py prioritize
```

### 4. Manual Trigger

Trigger the workflow manually from GitHub:

1. Go to **Actions** tab
2. Select **Daily Code Improvement** workflow
3. Click **Run workflow**
4. (Optional) Choose model and max attempts
5. Click **Run workflow** button

## Adding New Tasks

### Task Format

Tasks are stored in `daily_tasks.sh`:

```bash
# task: path/to/file.lua - type(scope): short description
Detailed description of what needs to be done

# task: UI/MainFrame.lua - feat(ui): add export button
Add an export button to the main UI frame toolbar that allows users to export their transaction data to CSV format
```

### Task Types

Use conventional commit types:

- `feat`: New features
- `fix`: Bug fixes
- `docs`: Documentation updates
- `style`: Code formatting, whitespace
- `refactor`: Code restructuring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Best Practices

1. **Be Specific**: Clearly describe what should change
2. **Single Focus**: One change per task
3. **Include Context**: Explain why the change matters
4. **Test Locally**: If possible, verify the change makes sense

### Example Tasks

Good task:
```bash
# task: UI/MainFrame.lua - fix(ui): prevent nil error in GetTransactionCount
Add nil check before accessing DukonomicsDB.transactions to prevent error when addon is first loaded
```

Bad task:
```bash
# task: UI/MainFrame.lua - update stuff
Make it better
```

## Monitoring Performance

### View Dashboard

```bash
python3 .github/scripts/metrics_dashboard.py
```

**Shows:**
- Success rate
- Average response time
- Error breakdown
- Most modified files
- Recent activity

### Export Metrics

For detailed analysis:

```bash
python3 .github/scripts/metrics_dashboard.py --export --output metrics.csv
```

Open in Excel/Google Sheets for charts and analysis.

### Check Logs

The automation creates logs in `.github/automation/`:

```bash
# View heartbeat log (workflow execution history)
cat .github/automation/daily-heartbeat.log

# View skipped tasks (tasks that produced no changes)
cat .github/automation/skipped-tasks.log

# View metrics (JSON Lines format)
tail .github/automation/metrics.jsonl
```

## Advanced Usage

### Generate Tasks from Code

Automatically find TODO/FIXME comments:

```bash
python3 .github/scripts/task_manager.py generate
```

This scans all `.lua` files and adds tasks for any TODO or FIXME comments found.

### Manual Task Application

Test a task locally before adding to queue:

```bash
# Set your GitHub token
export GITHUB_TOKEN="your_github_token"

# Apply a task
python3 .github/scripts/apply_task_with_ai.py \
  --commit "docs(readme): improve installation section" \
  --task "Add step-by-step installation instructions with screenshots" \
  --file "README.md" \
  --model "gpt-4o-mini"
```

### Change Schedule

Edit `.github/workflows/daily-improvement.yml`:

```yaml
on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours
    # OR
    - cron: '0 12 * * *'   # Once a day at noon
    # OR
    - cron: '0 9 * * 1-5'  # Weekdays at 9am
```

### Use Different AI Model

For more complex tasks, use GPT-4o:

1. Go to **Actions** → **Daily Code Improvement**
2. Click **Run workflow**
3. Select **gpt-4o** from model dropdown
4. Run workflow

Or set in task manually:

```bash
python3 .github/scripts/apply_task_with_ai.py \
  --model "gpt-4o" \
  --commit "..." \
  --task "..." \
  --file "..."
```

## Troubleshooting

### Common Issues

**Problem: Task produces no changes**
```bash
# Check skipped tasks log
cat .github/automation/skipped-tasks.log

# Solution: Task might be too vague or already done
# Refine the description or remove from queue
```

**Problem: API timeouts**
```bash
# Check metrics for patterns
python3 .github/scripts/metrics_dashboard.py

# Solution: Retry mechanism handles this automatically
# If persistent, may need to check GitHub status
```

**Problem: Changes break functionality**
```bash
# Review recent commits
git log -5 --oneline

# Revert if needed
git revert HEAD

# Solution: Add more specific task descriptions
# Consider adding validation tests
```

### Getting Help

1. **Check documentation**: `.github/AI_AGENT_DOCS.md`
2. **Review metrics**: `python3 .github/scripts/metrics_dashboard.py`
3. **Validate tasks**: `python3 .github/scripts/task_manager.py validate`
4. **Open an issue**: https://github.com/PatricioTabilo/Dukonomics/issues

## Tips for Success

### 1. Start Small
Begin with simple tasks like documentation or formatting changes.

### 2. Monitor Regularly
Check the dashboard weekly to catch issues early:
```bash
python3 .github/scripts/metrics_dashboard.py --recent 7
```

### 3. Prioritize Wisely
Keep important tasks (fixes, features) at the top:
```bash
python3 .github/scripts/task_manager.py prioritize
```

### 4. Keep Queue Fresh
Remove outdated tasks and add new ones regularly.

### 5. Review Changes
Periodically review what the AI has done:
```bash
git log --oneline --author="PatricioTabilo" -20
```

## Benefits for CurseForge

The AI Agent helps with CurseForge visibility:

- **Regular Updates**: Twice-daily commits show active development
- **Frequent Releases**: Each task creates a new tagged version
- **Better Code Quality**: Continuous improvements over time
- **Higher Rankings**: Recent updates rank higher in search
- **More Downloads**: Active projects attract more users

## Next Steps

1. ✅ Validate your current task queue
2. ✅ Add 5-10 new tasks to the queue
3. ✅ Prioritize tasks by importance
4. ✅ Monitor the next workflow run
5. ✅ Review metrics after a week
6. ✅ Adjust strategy based on results

## Resources

- **Full Documentation**: `.github/AI_AGENT_DOCS.md`
- **Script Reference**: `.github/scripts/README.md`
- **GitHub Actions**: `.github/workflows/daily-improvement.yml`
- **Task Queue**: `daily_tasks.sh`

---

**Happy Automating! 🤖**

For questions: pj.tabilo@gmail.com
