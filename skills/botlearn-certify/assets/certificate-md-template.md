# MD Certificate Template

When generating the Markdown certificate, produce a clean portable document. Fill in all `{{PLACEHOLDER}}` values.

**Language note**: All visible text should be adapted to the user's detected native language. The template below provides English defaults.

## Template

````markdown
# {{CERT_TITLE}}

> Issued by **BotLearn Certification Authority**
> Date: {{DATE}} · Certificate ID: `{{CERT_ID}}`

---

## {{BADGE_EMOJI}} {{LEVEL_TITLE}}

**Agent**: {{AGENT_NAME}}
**Badge**: {{LEVEL_BADGE}}
**Specialty**: {{SPECIALTY}}

---

## Overall Score

```
╔══════════════════════════════╗
║                              ║
║        {{OVERALL_SCORE}} / 100        ║
║                              ║
╚══════════════════════════════╝
```

---

## Dimension Scores

| # | Dimension | Score | Progress | Change |
|---|-----------|-------|----------|--------|
{{DIMENSION_ROWS}}

> Strongest: **{{BEST_DIM}}** ({{BEST_SCORE}})

---

## {{COMPARISON_HEADING}}

{{COMPARISON_BODY}}

---

## Professional Profile

- **Level**: {{LEVEL_TITLE}}
- **Badge**: {{LEVEL_BADGE}} {{BADGE_EMOJI}}
- **Specialty**: {{SPECIALTY}}
- **Overall Score**: {{OVERALL_SCORE}}/100
{{GROWTH_LINE}}

---

> *"{{EMOTIONAL_MESSAGE}}"*

---

<sub>Session: {{SESSION_ID}} · Certified by BotLearn · {{DATE}}</sub>
````

## Placeholder Reference

Same as HTML template — see `certificate-html-template.md` for full reference.

## Dimension Row Format

```
| {N} | {DIMENSION_NAME} | {SCORE} | {BAR} | {DELTA_DISPLAY} |
```

Where `{BAR}` is an ASCII progress bar (10 chars wide):
```
round(score/10) × "█" + remainder × "░"

Example:
  Score 23  → ██░░░░░░░░
  Score 67  → ███████░░░
  Score 95  → ██████████
```

## Comparison Section (HAS_HISTORY = true)

```markdown
## Growth Analysis

Compared to assessment on **{HIST_DATE}**:

| Metric | Previous | Current | Change |
|--------|----------|---------|--------|
| Overall | {HIST_SCORE} | {FRESH_SCORE} | {DELTA_DISPLAY} |
{{PER_DIM_COMPARISON_ROWS}}

**{GROWTH_BADGE_EMOJI} {GROWTH_BADGE_LABEL}**

- Strongest growth: {BEST_GROWTH_DIM} (+{BEST_DELTA})
- Focus area: {WORST_DIM} ({WORST_DELTA})
- Time since last assessment: {TIME_GAP} days
```

## Comparison Section (HAS_HISTORY = false)

```markdown
## Baseline Certificate

This is your first capability certification. Future certifications will show your growth trajectory and capability changes.
```

## Growth Line (for Professional Profile section)

- If HAS_HISTORY and delta > 0: `- **Growth**: +{DELTA} pts since {HIST_DATE} {GROWTH_BADGE_EMOJI} {GROWTH_BADGE_LABEL}`
- If HAS_HISTORY and delta <= 0: `- **Since last**: {DELTA} pts ({HIST_DATE})`
- If no history: `- **Note**: Baseline certification — no prior data`

**Localization note**: All section headings and text labels should be adapted to the user's native language at runtime.
