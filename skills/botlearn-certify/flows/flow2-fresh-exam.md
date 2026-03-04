# Flow 2: Fresh Assessment Execution

## Purpose

Invoke the botlearn-assessment skill to run a complete full-exam (all dimensions, 15 questions), producing a fresh score for certification comparison.

## Prerequisites

- Flow 1 completed (ASSESSMENT_DIR known)
- botlearn-assessment skill is available

## Steps

### 2.1 Announce Certification Exam

Inform the user (in their native language) that:
- A fresh full-dimension assessment is required for certification
- It will take approximately 30-45 minutes (15 questions across all dimensions)
- The exam is administered by botlearn-assessment
- Results will be used for certification comparison

### 2.2 Invoke Full Exam

Trigger the botlearn-assessment skill's full-exam flow:

```
Action: Invoke botlearn-assessment with trigger "full exam"
Flow: flows/full-exam.md in botlearn-assessment
```

**Important**: Let assessment handle the entire exam process. Do not interfere with question delivery, answer collection, or scoring. Wait for the full exam to complete.

### 2.3 Locate New Report

After exam completion, check for the new report:

```
NEW_INDEX = {ASSESSMENT_DIR}/results/INDEX.md
NEW_REPORT = latest entry in INDEX.md (should be the exam just completed)
REPORT_PATH = {ASSESSMENT_DIR}/results/{new_report_filename}
```

Verify the report timestamp is from the current session (within last 2 hours).

### 2.4 Parse Fresh Results

Run: `bash scripts/parse-results.sh {REPORT_PATH}`

Extract and store:
- `FRESH_OVERALL_SCORE`: Overall score (0-100)
- `FRESH_DIMENSIONS[]`: Array of { dimension_name, score }
- `FRESH_DATE`: Exam date
- `FRESH_SESSION`: Session ID

### 2.5 Quick Preview

Inform the user (in their native language) that the fresh assessment is complete, show the overall score, and indicate that certificate generation is starting.

## Error Handling

| Scenario | Action |
|----------|--------|
| assessment skill fails to start | Retry once, then abort with guidance |
| Exam interrupted mid-way | Check for partial report, ask user to retry |
| No new report after exam | Check INDEX.md manually, parse latest entry |
| Score parsing fails | Read report file directly, extract scores manually |

## Variables Passed to Next Flow

- All variables from Flow 1 (HAS_HISTORY, HIST_*)
- `FRESH_OVERALL_SCORE`: number
- `FRESH_DIMENSIONS`: array
- `FRESH_DATE`: string
- `FRESH_SESSION`: string
- `REPORT_PATH`: path to fresh report
