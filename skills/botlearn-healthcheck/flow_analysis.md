# Phase 4 — Report Analysis

After report generation, present the analysis to the user and provide actionable insights.

## 4.1 — Output Layers

Present results in sequence. All labels, summaries, and descriptions in REPORT_LANG.
Commands, paths, field names, and error codes stay in English.

### L0 — One-line Status (always show)

```
OpenClaw Health: [X] pass [X] warn [X] error — [summary in REPORT_LANG]
```

### L1 — Domain Grid (always show, domain names in REPORT_LANG)

```
[Hardware]  [STATUS] [XX]  |  [Config]    [STATUS] [XX]  |  [Security] [STATUS] [XX]
[Skills]    [STATUS] [XX]  |  [Autonomy]  [STATUS] [XX]
```

### L2 — Issue Table (only when any warnings or errors exist)

```
| # | Domain | Status | Issue | Fix Hint |
|---|--------|--------|-------|----------|
| 1 | [domain name] | [status] | [issue description] | [fix command] |
```

### L3 — Deep Analysis (only on `--full` flag or explicit user request)

Per flagged domain: Findings → Root Cause → Fix Steps (with rollback) → Prevention.
Load `check_<domain>.md` for comprehensive scoring details and edge case handling.
Load **`fix_cases.md`** for real-world diagnosis patterns and proven solutions.
Load **`openclaw_knowledge.md`** for platform defaults, CLI commands, and version-specific changes.

## 4.2 — Historical Trend Comparison

On subsequent health checks, if previous reports exist in `$OPENCLAW_HOME/memory/health-reports/`,
append a brief **trend comparison** at the end of the MD report:

```markdown
## Historical Trend

| Date | Overall | Hardware | Config | Security | Skills | Autonomy |
|------|---------|----------|--------|----------|--------|----------|
| [previous date] | [status] | [score] | [score] | [score] | [score] | [score] |
| [current date]  | [status] | [score] | [score] | [score] | [score] | [score] |

Change: [+X improved / -X degraded / = unchanged]
```

Only include the most recent 5 historical entries. Read previous `.md` reports to extract scores.

## 4.3 — Follow-up Prompt

After presenting the analysis, ask the user (in REPORT_LANG):

- If issues found: "Found [X] issues. Fix now, or review findings first?"
- If all pass: "All checks passed. View detailed report or archive?"

Wait for user response before proceeding to Phase 5.
