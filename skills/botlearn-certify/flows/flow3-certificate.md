# Flow 3: Certificate Generation

## Purpose

Compare historical vs fresh assessment results, classify professional profile, and generate certificates in both HTML and MD formats.

## Prerequisites

- Flow 2 completed (FRESH_* variables available)
- HAS_HISTORY flag from Flow 1

## Steps

### 3.1 Compute Comparison Data

If `HAS_HISTORY = true`:

```
For each dimension in FRESH_DIMENSIONS:
  Find matching dimension in HIST_DIMENSIONS (by name, fuzzy match OK)
  DELTA = FRESH_SCORE - HIST_SCORE
  DIRECTION = "↑" if DELTA > 0, "↓" if DELTA < 0, "→" if DELTA = 0
  DELTA_PCT = round(DELTA, 1)

OVERALL_DELTA = FRESH_OVERALL_SCORE - HIST_OVERALL_SCORE
```

If `HAS_HISTORY = false`:

```
All DELTA values = N/A
Certificate type = "Baseline Certificate"
Comparison section shows a note: first assessment, future certifications will show growth trajectory.
```

See `knowledge/comparison-methodology.md` for detailed comparison rules.

### 3.2 Classify Professional Profile

Apply classification rules from `strategies/classification.md`:

1. **Overall Level**: Map FRESH_OVERALL_SCORE to 6-tier system
2. **Specialty**: Identify strongest dimension → assign specialty title
3. **Growth Badge**: If HAS_HISTORY, award growth badge based on improvement

### 3.3 Generate Timestamp and Filenames

```
TIMESTAMP = format(now(), "YYYYMMDD-HHmm")
HTML_FILE = results/certificate-{TIMESTAMP}.html
MD_FILE = results/certificate-{TIMESTAMP}.md
```

### 3.4 Generate HTML Certificate

Use template from `assets/certificate-html-template.md`.

Fill in all placeholders:
- `{{AGENT_NAME}}` — Agent name or session ID
- `{{DATE}}` — Certification date
- `{{OVERALL_SCORE}}` — Fresh overall score
- `{{LEVEL_TITLE}}` — Level title (e.g., "AI Architect")
- `{{LEVEL_BADGE}}` — Badge tier (Bronze/Silver/Gold/Platinum)
- `{{BADGE_COLOR}}` — Color based on tier
- `{{SPECIALTY}}` — Professional specialty
- `{{DIMENSION_ROWS}}` — Table rows for each dimension
- `{{RADAR_POINTS}}` — SVG polygon points for radar chart
- `{{COMPARISON_SECTION}}` — Growth comparison or baseline notice
- `{{EMOTIONAL_MESSAGE}}` — Celebratory message based on level

**Language note**: Adapt all user-visible text in the certificate (titles, messages, labels) to the user's detected native language. The template provides English defaults.

Save to `{HTML_FILE}`.

### 3.5 Generate MD Certificate

Use template from `assets/certificate-md-template.md`.

Fill in same placeholders in simplified format.

Save to `{MD_FILE}`.

### 3.6 Present Results

Display to user (in their native language):
- Level and badge
- Specialty
- Score
- Growth delta (if history available)
- File paths for HTML and MD certificates
- Emotional celebratory message

## Emotional Messages by Level

These are default English messages. Adapt to user's native language at runtime.

| Level | Message |
|-------|---------|
| AI Apprentice | "Every master was once an apprentice. Your AI journey has just begun — the future is bright!" |
| AI Assistant | "Steady progress! You've mastered the fundamentals. Keep that learning momentum going!" |
| AI Practitioner | "Practice makes perfect! Your skills already surpass most users. Keep deepening your expertise!" |
| AI Expert | "Professional caliber! Your understanding of AI is remarkably deep. Truly impressive!" |
| AI Architect | "Architect level! You don't just use AI — you know how to design AI workflows!" |
| AI Master | "Peak mastery! You stand at the pinnacle of AI capability. You are the benchmark!" |

## Error Handling

| Scenario | Action |
|----------|--------|
| Template file missing | Generate certificate inline with simplified format |
| Dimension name mismatch (historical vs fresh) | Use fuzzy matching, log unmatched dimensions |
| File write permission error | Output certificate content to stdout instead |
| Score out of range | Clamp to 0-100, add warning note |
