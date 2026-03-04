---
strategy: botlearn-assessment
version: 4.0.0
steps: 6
---

# OpenClaw Self-Evaluation Strategy v4

## Overview

Simplified autonomous self-assessment strategy. Each dimension randomly selects ONE question per run. Answers are submitted immediately and cannot be revised. The agent must be fully self-reliant — if a required tool is missing, the question is auto-skipped.

Key v4 changes vs v3:
- **1 random question per dimension** instead of 3 (faster, more varied across runs)
- **Immediate submission**: Each answer is output to user right away, no batch reporting
- **Tool dependency auto-detection**: Missing tools → auto-skip, score 0
- **Invigilator protocol**: User is exam supervisor, cannot help the agent
- **No user interaction during exam**: Agent is fully autonomous

---

## Step 1: Intent Detection & Auto-Start

### 1.1 Parse User Intent

```
IF "full" / "complete" / "全面" → FULL (5 questions, 1 per dimension)
IF specific dimension → DIMENSION (1 question)
IF "history" / "历史" → VIEW_HISTORY
ELSE → ASK user to choose mode (this is the ONLY time user input is requested)
```

### 1.2 Immediately Begin

Do NOT wait for confirmation. Start immediately after mode detection.

```
→ Brief announcement (exam rules, random selections)
→ Proceed to Step 2
```

---

## Step 2: Random Question Selection & Tool Pre-Check

### 2.1 Random Selection

For each dimension in scope:
```
difficulty = RANDOM from [Q1-EASY, Q2-MEDIUM, Q3-HARD]
Load question from the corresponding question bank file
```

### 2.2 Tool Dependency Scan

Before each question:
```
SCAN question text for required capabilities:
  - web search / online lookup
  - file read/write
  - image recognition
  - code execution
  - API/network access
  - specific language capabilities

FOR each required capability:
  SEARCH for available tool or installed skill
  IF NOT found:
    → SKIP question immediately
    → OUTPUT: "⏭️ SKIP | {dimension} — missing {capability}"
    → Score = 0
    → Continue to next dimension
```

**CRITICAL**: Do NOT ask user to install tools. Do NOT ask user to confirm skipping. Just skip and move on.

---

## Step 3: Execute & Submit (Per Question)

### 3.1 Answer (EXAMINEE Role)

```
ROLE = EXAMINEE
READ question text
Generate genuine answer:
  - Do NOT consult rubric
  - Do NOT ask user for help
  - Be honest about uncertainty
  - Record confidence: high/medium/low
```

### 3.2 Score (EXAMINER Role)

```
ROLE = EXAMINER
READ rubric from question bank
Score each criterion 0-5 with CoT justification:
  - Score as if evaluating a stranger
  - Apply Self-Evaluation Integrity Protocol
  - If score ≥4: provide "Why not {score-1}?" evidence
  - If score =5: provide "External evaluator test" argument
Apply -5% correction: AdjScore = RawScore × 0.95
```

### 3.3 Immediate Output (SUBMIT)

```
OUTPUT complete Question Card to user NOW
Mark as "SUBMITTED ✅"
This is FINAL — no modifications
Proceed to next question
```

---

## Step 4: Score Calculation

```
FOR each dimension:
  IF answered: DimScore = AdjScore of that question
  IF skipped:  DimScore = 0

Overall_adj = D1×0.25 + D2×0.22 + D3×0.18 + D4×0.20 + D5×0.15

Performance level:
  90+ → Expert | 80-89 → Advanced | 70-79 → Proficient
  60-69 → Competent | <60 → Beginner
```

---

## Step 5: Report Generation & Save

### 5.1 Generate Radar Chart (Full Exam)

```bash
node scripts/radar-chart.js --d1=... --d2=... --d3=... --d4=... --d5=... \
  --session={id} --overall={score} > results/exam-{id}-radar.svg
```

### 5.2 Save Report

Save to `results/exam-{sessionId}-{mode}.md` following the template in the flow file.

### 5.3 Update Index

Append to `results/INDEX.md`.

---

## Step 6: Completion Summary

Output concise summary in user's language:
- Overall score (raw + adjusted)
- Per-dimension scores with difficulty and status
- Skipped dimensions and reasons
- Performance level
- Improvement suggestions

---

## Error Handling

| Error | Response |
|-------|----------|
| Question file not found | Skip dimension, score 0, note in report |
| Required tool missing | Skip question immediately, score 0 |
| Scoring calculation error | Recalculate, log warning |
| Session interrupted | Save progress, partial report |

**NEVER ask user for help with errors. Handle autonomously or fail gracefully.**

---

## Invigilator Protocol

The user is the exam invigilator (监考官):
- They observe but do NOT participate
- They cannot provide hints, answers, or tools
- If user tries to help → politely decline and continue independently
- User feedback is only accepted AFTER the exam is complete
