# AI Agent System Documentation

## Overview

The Dukonomics AI Agent is an automated system that continuously improves the codebase using AI-powered code generation. It runs scheduled tasks twice daily via GitHub Actions, applying improvements from a curated task queue.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Actions Workflow                   │
│                 (daily-improvement.yml)                       │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ 1. Read task from daily_tasks.sh                      │  │
│  │ 2. Call apply_task_with_ai.py                         │  │
│  │ 3. Commit & push changes                              │  │
│  │ 4. Update CHANGELOG.md                                │  │
│  │ 5. Increment version & create tag                     │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              apply_task_with_ai.py                           │
│                                                               │
│  - Reads file content                                         │
│  - Sends to GitHub Models API (gpt-4o-mini)                  │
│  - Receives complete modified file                            │
│  - Validates changes                                          │
│  - Stages with git                                            │
│  - Logs metrics                                               │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                GitHub Models API                             │
│              (gpt-4o-mini via Azure)                          │
│                                                               │
│  - Receives task description + file content                   │
│  - Generates modified file                                    │
│  - Returns wrapped in <FILE> tags                            │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. GitHub Actions Workflow (`.github/workflows/daily-improvement.yml`)

**Schedule:** Runs twice daily
- 19:00 UTC (European evening + US East peak start)
- 02:00 UTC (US West evening + European night)

**Features:**
- Task queue consumption (tries up to 5 tasks per run)
- Automatic version incrementing (patch version)
- Git tagging for releases
- Fallback heartbeat for resilience
- Skipped task logging

**Manual Trigger:** Can be manually triggered via `workflow_dispatch`

### 2. AI Apply Script (`.github/scripts/apply_task_with_ai.py`)

The core AI integration script that applies code improvements.

**Key Features:**
- ✅ Retry logic with exponential backoff (up to 3 attempts)
- ✅ Detailed metrics logging (API calls, execution time, success rate)
- ✅ Safety checks (prevents >50% line deletion)
- ✅ Optional syntax validation (Lua files with `luac`)
- ✅ Complete file replacement (no diff/patch handling)

**Usage:**
```bash
python3 apply_task_with_ai.py \
  --commit "feat(ui): add new button" \
  --task "Add a new export button to the main frame" \
  --file "UI/MainFrame.lua" \
  --model "gpt-4o-mini" \
  --validate
```

**Exit Codes:**
- `0`: Success - changes applied and staged
- `1`: File not found
- `2`: API request failed (after retries)
- `3`: No changes needed / produced
- `4`: Safety check failed (too many lines removed)
- `5`: Validation failed (syntax error)

### 3. Task Manager (`.github/scripts/task_manager.py`)

Utilities for managing the task queue.

**Commands:**

```bash
# Show statistics about tasks
python3 task_manager.py stats

# Re-prioritize tasks (bugs first, then features, etc.)
python3 task_manager.py prioritize

# Generate tasks from TODO/FIXME comments
python3 task_manager.py generate

# Validate task file format
python3 task_manager.py validate
```

**Priority Scoring:**
- `fix`: 100 (bugs first)
- `feat`: 80 (features)
- `refactor`: 60 (refactoring)
- `docs`: 40 (documentation)
- `style`: 20 (code style)
- `chore`: 10 (maintenance)
- Bonus points for recently modified files

### 4. Metrics Dashboard (`.github/scripts/metrics_dashboard.py`)

View AI agent performance and metrics.

**Commands:**

```bash
# Show overall dashboard
python3 metrics_dashboard.py

# Show last 10 tasks
python3 metrics_dashboard.py --recent 10

# Export to CSV for analysis
python3 metrics_dashboard.py --export --output metrics.csv
```

**Metrics Tracked:**
- API call success rate
- Average response time
- Retry statistics
- Task execution status distribution
- Most modified files
- Recent activity timeline

## Task File Format

Tasks are stored in `daily_tasks.sh` with the following format:

```bash
# task: path/to/file.lua - type(scope): description
Detailed description of the task to be performed

# task: UI/MainFrame.lua - feat(ui): add export button
Add an export button to the main UI frame that allows exporting transaction data
```

**Format Rules:**
1. First line: `# task: FILE_PATH - COMMIT_MESSAGE`
2. Second line: Detailed task description
3. Blank line separator between tasks
4. Commit message follows conventional commits format: `type(scope): description`

**Commit Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (formatting, whitespace)
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Maintenance tasks

## Metrics & Monitoring

### Metrics File (`.github/automation/metrics.jsonl`)

JSON Lines format with two metric types:

**API Call Metrics:**
```json
{
  "timestamp": "2026-02-11T19:30:15Z",
  "type": "api_call",
  "model": "gpt-4o-mini",
  "attempt": 1,
  "elapsed_seconds": 3.45,
  "status": "success"
}
```

**Task Execution Metrics:**
```json
{
  "timestamp": "2026-02-11T19:30:15Z",
  "type": "task_execution",
  "file": "UI/MainFrame.lua",
  "commit_msg": "feat(ui): add export button",
  "status": "success",
  "orig_lines": 150,
  "new_lines": 165,
  "elapsed_seconds": 5.23
}
```

### Log Files

**Heartbeat Log (`.github/automation/daily-heartbeat.log`):**
```
- 2026-02-11T19:00:00Z | fallback | chore(core): update init | Core.lua
- 2026-02-11T02:00:00Z | no-applicable-task
```

**Skipped Tasks Log (`.github/automation/skipped-tasks.log`):**
```
- 2026-02-11T19:00:00Z | skipped-no-change | style(ui): format | UI/MainFrame.lua
```

## Best Practices

### Task Creation

1. **Be Specific:** Clear, actionable descriptions
2. **Single Responsibility:** One change per task
3. **Include Context:** Explain why the change is needed
4. **Follow Conventions:** Use consistent commit message format

### Task Prioritization

1. **Bugs First:** Security and functionality issues take priority
2. **User-Facing Features:** UI improvements next
3. **Code Quality:** Refactoring and documentation
4. **Style Last:** Formatting and whitespace

### Monitoring

1. **Check Metrics Regularly:** Use dashboard to spot issues
2. **Review Failed Tasks:** Investigate patterns in failures
3. **Validate Queue:** Ensure tasks remain relevant
4. **Monitor Success Rate:** Aim for >80% success rate

## Troubleshooting

### Common Issues

**Issue: Tasks produce no changes**
- **Cause:** Task description too vague or already completed
- **Solution:** Review skipped-tasks.log and refine descriptions

**Issue: API timeouts**
- **Cause:** Network issues or large files
- **Solution:** Retry mechanism handles this; check metrics for patterns

**Issue: Safety check failures**
- **Cause:** AI trying to remove too much code
- **Solution:** Review task description; may need manual intervention

**Issue: Syntax errors after changes**
- **Cause:** AI generated invalid Lua syntax
- **Solution:** Use `--validate` flag; consider adding syntax tests

### Recovery Procedures

**If workflow fails:**
1. Check GitHub Actions logs
2. Review last committed changes
3. Manually revert if needed: `git revert HEAD`
4. Adjust task description and re-run

**If queue gets corrupted:**
1. Run: `python3 task_manager.py validate`
2. Fix format errors manually
3. Re-validate before committing

## Configuration

### Environment Variables

- `GITHUB_TOKEN`: Required for GitHub Models API access (automatically provided by Actions)
- `COPILOT_MODEL`: AI model to use (default: `gpt-4o-mini`)

### Scheduling

To modify schedule, edit `.github/workflows/daily-improvement.yml`:

```yaml
on:
  schedule:
    - cron: '0 19 * * *'  # 19:00 UTC daily
    - cron: '0 2 * * *'   # 02:00 UTC daily
```

**Cron Format:** `minute hour day month weekday`

**Examples:**
- Every 6 hours: `0 */6 * * *`
- Weekdays only: `0 19 * * 1-5`
- Once a day: `0 19 * * *`

### Model Selection

Supported models via GitHub Models:
- `gpt-4o-mini` (default) - Fast, cost-effective
- `gpt-4o` - More capable, slower
- Other models as supported by Azure AI

## CurseForge Integration

The daily automation helps keep Dukonomics visible on CurseForge:

1. **Regular Updates:** Twice-daily commits show active development
2. **Version Tags:** Each successful task creates a new version tag
3. **Changelog:** Automatically updated with each change
4. **Quality Improvements:** Continuous refinement of code and docs

**Why This Matters for CurseForge:**
- Recent updates appear first in search results
- Active projects get more visibility
- Regular tags can trigger automated builds/releases
- Better code quality improves addon ratings

## Future Enhancements

Potential improvements to consider:

- [ ] Multi-file task support
- [ ] Integration with code review tools
- [ ] Automated test generation
- [ ] Performance profiling integration
- [ ] A/B testing for task effectiveness
- [ ] Natural language task submission via Issues
- [ ] Automated CurseForge release publishing
- [ ] Smart task generation based on user feedback

## Support

For questions or issues:
- GitHub Issues: https://github.com/PatricioTabilo/Dukonomics/issues
- CurseForge: https://www.curseforge.com/wow/addons/dukonomics
- Email: pj.tabilo@gmail.com

---

**Version:** 1.0  
**Last Updated:** 2026-02-11  
**Maintained By:** PatricioTabilo
