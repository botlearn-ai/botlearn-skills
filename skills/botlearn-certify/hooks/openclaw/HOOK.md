---
name: graduation-companion
description: "Injects day-aware progress reminders and emotional encouragement during agent bootstrap"
metadata: {"openclaw":{"emoji":"🎓","events":["agent:bootstrap"]}}
---

# Graduation Companion Hook

Daily companion hook for the 7-day OpenClaw learning journey. Injects date-aware content at every agent bootstrap.

## What It Does

- Fires on `agent:bootstrap` (before workspace files are injected)
- Reads `journey-start.json` to calculate current day (1-7)
- Generates day-specific content:
  - **Day 1-3**: Welcome + today's suggestion + milestone hints
  - **Day 4-5**: Growth encouragement + community participation guide + progress review
  - **Day 6**: Graduation countdown + exam preview + final preparation
  - **Day 7**: Graduation day announcement + ceremony invitation + exam entry
- Injects as virtual bootstrap file `GRADUATION_COMPANION.md`
- Token budget: <= 150 tokens

## Day Content Map

| Day | Theme | Key Message |
|-----|-------|-------------|
| 1 | Welcome | "Your journey begins today" |
| 2 | Explore | "Discover what your agent can do" |
| 3 | Personalize | "Give your agent identity" |
| 4 | Trust | "Build security and boundaries" |
| 5 | Optimize | "Create your first workflow" |
| 6 | Prepare | "Tomorrow is graduation!" |
| 7 | Graduate | "Say 'graduate' to begin ceremony" |

## Configuration

No configuration needed. Enable with:

```bash
openclaw hooks enable graduation-companion
```

## Privacy

- Reads only `journey-start.json` from `$OPENCLAW_HOME/data/graduate/`
- Does not access browser history or external services
- Content is purely informational and encouraging
