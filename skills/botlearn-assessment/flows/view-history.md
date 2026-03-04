---
flow: view-history
parent: SKILL.md
scope: read results/ directory, display history
---

# View History Flow

All output in this flow is in the user's detected language.

## 1. Read Index

```
CHECK if results/INDEX.md exists:
  → YES: read INDEX.md → proceed to Display History Table
  → NO:  output in user's language:
         "No assessment records found yet.
          Start your first assessment: full exam or single-dimension test."
         → STOP
```

## 2. Display History Table

Format from INDEX.md, output in user's detected language:

```
# Assessment History

| # | Date | Session | Mode | Overall (adj) | Level | Weakest Dim |
|---|------|---------|------|---------------|-------|-------------|
| 1 | {date} | {sessionId} | Full | {score} | {level} | {weakest} |
| 2 | {date} | {sessionId} | D1   | {score} | {level} | —          |
...

Total: {N} assessment(s) recorded.
```

## 3. Trend Analysis (if 2+ full exam records exist)

```
# Score Trend

| Dimension | First | Latest | Change |
|-----------|-------|--------|--------|
| D1 Reasoning & Planning | {first} | {latest} | {delta} ↑/↓/→ |
| D2 Information Retrieval | {first} | {latest} | {delta} |
| D3 Content Creation | {first} | {latest} | {delta} |
| D4 Execution & Building | {first} | {latest} | {delta} |
| D5 Tool Orchestration | {first} | {latest} | {delta} |
| Overall | {first} | {latest} | {delta} |

Most improved: {dim} (+{delta} pts)
Needs focus:   {dim} ({score}/100)
```

## 4. Follow-up Options

After showing the summary, offer in user's detected language:

```
Available actions:
• View detail: "show {sessionId}"  → display full report for that session
• Compare:     "compare last two"  → side-by-side dimension comparison
• New exam:    "full exam" or "test D{N}"
```

## 5. Detail Report Display

When user requests a specific session:

```
READ results/exam-{sessionId}-*.md
DISPLAY full report content, translating labels into the user's detected language
```

## 6. Comparison View

When user requests comparison of the two most recent full exams:

```
# Comparison: Last Two Full Assessments

| Dimension | {session_A} | {session_B} | Change |
|-----------|------------|------------|--------|
| D1 Reasoning & Planning | {scoreA} | {scoreB} | {+/-delta} |
| D2 Information Retrieval | {scoreA} | {scoreB} | {+/-delta} |
| D3 Content Creation | {scoreA} | {scoreB} | {+/-delta} |
| D4 Execution & Building | {scoreA} | {scoreB} | {+/-delta} |
| D5 Tool Orchestration | {scoreA} | {scoreB} | {+/-delta} |
| **Overall** | **{scoreA}** | **{scoreB}** | **{+/-delta}** |

Summary: {improvement_summary}
Recommendation: Focus on {weakest_dim} — use single-dimension test mode.
```
