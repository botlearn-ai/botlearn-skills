---
domain: botlearn-certify
topic: graduation-ceremony-best-practices
priority: high
ttl: 90d
---

# Graduation Best Practices

## 1. Data Collection

### Complete Snapshot Comparison
```
Day 1: Baseline (saved or reconstructed)
Day 7: Current state (live collection)

Key: Skills, config, documents, tasks, workflows
```

Always show the math, explain the why. Every claim backed by evidence.

### Parallel Script Execution
Run all collection scripts in parallel for speed:
```
collect-journey.sh + collect-growth.sh + collect-activity.sh + track-browser.sh
```
Combine results after all complete. Handle individual script failures gracefully.

## 2. Growth Visualization

```
Use the 4C framework with consistent symbols:
✅ Achieved (80-100)  ⚠️ Developing (60-79)
🟡 Needs Work (40-59)  🔴 Critical (<40)
```

## 3. Achievement Identification

```
BEFORE: "I have this thing but don't know what to do"
AFTER:  "My agent can [X], [Y], and [Z]"

Make it tangible, specific, undeniable.
```

## 4. Archetype Detection

Present with evidence:
1. Clear name and definition
2. Why it fits THIS user (specific evidence)
3. Strengths + growth path
4. Community resources
5. Acknowledge hybrid archetypes when scores are close

## 5. Hook Content Best Practices

### Token Budget: ≤ 150 Tokens
Hook content must be concise. Every word counts.

```
✅ "Day 3 — Give your agent a personality. Create SOUL.md."
❌ "Day 3 — Today we recommend that you consider the possibility of perhaps creating..."
```

### Progressive Warmth (7-Day Arc)
| Day | Tone | Relationship |
|-----|------|-------------|
| 1-2 | Friendly guide | "Let me show you..." |
| 3-4 | Encouraging coach | "You're doing great..." |
| 5-6 | Proud mentor | "Look how far you've come..." |
| 7 | Celebratory host | "Welcome to your graduation!" |

### No Repetition
Each day's hook content MUST be different. Never repeat the same tip or message. If the user saw "try a new skill" on Day 2, don't say it again on Day 3.

### Graceful Absence
If `journey-start.json` doesn't exist, inject nothing. Don't error, don't inject placeholder content.

## 6. Emotional Value: 7-Day Warmth Curve

### Warmth Progression
```
Day 1: 🌟 Excitement (welcome, possibility)
Day 2: 🔍 Curiosity (explore, discover)
Day 3: 🌱 Growth (personalize, deepen)
Day 4: 🤝 Trust (boundaries, security)
Day 5: 🔄 Mastery (workflows, patterns)
Day 6: ⏰ Anticipation (countdown, reflection)
Day 7: 🎓 Celebration (ceremony, pride)
```

### Low Engagement Response
- Don't shame: "No pressure, your agent is waiting."
- Don't rush: "Even 5 minutes today builds on yesterday."
- Don't abandon: "Welcome back! Pick up right where you left off."

### High Achievement Response
- Don't overpromise: Be celebratory but realistic
- Do identify what worked: "Your consistent daily usage made the difference"
- Do suggest contribution: "Your workflow could help other operators"

## 7. Exam Management Best Practices

### Reflection Questions: No Standard Answer
Reflection questions (R1-R5) have no single correct answer. Score on:
- **Depth**: Goes beyond surface-level
- **Specificity**: References actual journey events
- **Self-awareness**: Honest about strengths and gaps
- **Forward-looking**: Connects reflection to future action

### Before Exam
- Set expectations: "This is for reflection, not perfection"
- Offer mode choice: full (15), quick (6), or practice (3)
- No time pressure: Unlimited time

### During Exam
- Encourage: "For reflection questions, there's no wrong answer"
- One question at a time: Don't overwhelm

### After Exam
- Celebrate attempt regardless of score
- Highlight strengths per category
- Frame growth areas as "next focus" not "failures"
- Below-threshold scores: "The exam is a mirror, not a gate"

## 8. Browser Tracking Best Practices

### Privacy First
- Only query `botlearn.ai` domain — never inspect other URLs
- Copy DB to `/tmp` — never lock the browser's database
- Optional feature — always degrade gracefully
- Never report specific pages visited beyond botlearn.ai

### Communication
```
✅ "We noticed you visited botlearn.ai 5 times this week — great engagement!"
❌ "We saw you browsed botlearn.ai/community/post/123 at 3:42 AM"
```

### Failure Mode
If browser tracking fails (no sqlite3, permission denied, no history):
- Mark as "unavailable"
- Don't mention the feature at all in the report
- Score community engagement from other sources (API, self-report)

## 9. Report Structure

```
Section Order:
1. Executive Summary (one-sentence + key metric + archetype)
2. Transformation Table (Day 1 vs Day 7)
3. Graduation Achievements (4 phases checklist)
4. Milestone Grade (Gold/Silver/Bronze/Participant)
5. Agent Archetype (detection + evidence)
6. 4C Analysis (detailed scores)
7. Exam Results (if taken)
8. Next Phase Planning (7/30/90 day paths)
9. Community Welcome (curated resources)
10. Graduation Certificate (ASCII diploma)
11. Graduation Message (inspiring farewell)
```

## 10. Follow-Up

### Save Graduation Data
```
~/.openclaw/data/graduate/
├── journey-start.json    # Journey metadata
├── day1-baseline.json    # Day 1 scores
├── graduation-report.json # Final report
├── exam-result.json      # Exam scores
└── ceremony-completed    # Completion marker
```

### Schedule Check-Ins
- 14 days: "How's your agent evolving?"
- 30 days: "Progress check"
- 90 days: "Major milestone review"

## Successful Graduation Checklist

- [ ] Day 1 baseline collected/reconstructed
- [ ] 4C analysis with scores and evidence
- [ ] Milestones tracked and graded
- [ ] Archetype identified with evidence
- [ ] Exam offered (optional)
- [ ] Ceremony personalized to archetype
- [ ] Browser engagement noted (if available)
- [ ] Community activity tracked (if available)
- [ ] Personalized next steps provided
- [ ] Certificate generated
- [ ] Graduation data saved
- [ ] Follow-up scheduled
