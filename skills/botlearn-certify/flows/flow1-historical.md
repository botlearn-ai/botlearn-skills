# Flow 1: Historical Assessment Retrieval

## Purpose

Locate and parse the most recent full-exam assessment report to establish baseline scores for comparison.

## Prerequisites

- botlearn-assessment skill must be installed (run `bash scripts/check-assessment.sh` first)

## Steps

### 1.1 Locate Assessment Skill

```
ASSESSMENT_DIR = find botlearn-assessment in:
  1. ../botlearn-assessment (sibling directory)
  2. ~/.openclaw/skills/botlearn-assessment
  3. ~/.clawhub/skills/botlearn-assessment
```

If not found → abort and instruct the user to install botlearn-assessment via `clawhub install botlearn-assessment`. Adapt the message to user's native language.

### 1.2 Read INDEX.md

```
INDEX_FILE = {ASSESSMENT_DIR}/results/INDEX.md
```

Parse the INDEX.md table. Each row contains:
- Date/time
- Exam type (full / dimension)
- Score
- Report file path

**Filter for `full` exam type only** — dimension-only exams are incomplete for certification.

### 1.3 Find Most Recent Full-Exam Report

```
LATEST_REPORT = most recent row where type = "full"
REPORT_PATH = {ASSESSMENT_DIR}/results/{report_filename}
```

If no full exam found:
- Set `HAS_HISTORY = false`
- Inform the user this will be a baseline certification (no prior data for comparison)
- Skip to Flow 2

### 1.4 Parse Historical Report

Run: `bash scripts/parse-results.sh {REPORT_PATH}`

Extract and store:
- `HIST_OVERALL_SCORE`: Overall score (0-100)
- `HIST_DIMENSIONS[]`: Array of { dimension_name, score } — **dynamically parsed, no hardcoded dimension list**
- `HIST_DATE`: Exam date
- `HIST_SESSION`: Session ID

### 1.5 Output Summary

Display a summary to user (in their native language) showing:
- Historical assessment date
- Overall score
- Per-dimension scores
- A note that the fresh assessment will begin next

## Error Handling

| Scenario | Action |
|----------|--------|
| assessment not installed | Run check-assessment.sh, follow its guidance |
| INDEX.md doesn't exist | Set HAS_HISTORY=false, proceed |
| INDEX.md exists but empty | Set HAS_HISTORY=false, proceed |
| Report file referenced in INDEX.md missing | Warn user, set HAS_HISTORY=false |
| Parse failure | Warn user, set HAS_HISTORY=false |

## Variables Passed to Next Flow

- `HAS_HISTORY`: boolean
- `HIST_OVERALL_SCORE`: number or null
- `HIST_DIMENSIONS`: array or empty
- `HIST_DATE`: string or null
- `ASSESSMENT_DIR`: path to botlearn-assessment
