# @botlearn/openclaw-graduate

> 🎓 7-Day Journey Graduation Companion — daily hook encouragement, browser engagement tracking, growth statistics, graduation exam, milestone grading, and personalized ceremony

## Installation

```bash
# via clawhub (recommended)
clawhub install @botlearn/botlearn-graduate

# via npm
npm install @botlearn/botlearn-graduate
```

See `setup.md` for full 10-step installation guide including hook registration, journey initialization, and baseline collection.

## Category

Learning (Education, Growth, Graduation, Journey Companion)

## Dependencies

- `@botlearn/openclaw-examiner` (>=0.1.0) — Exam evaluation methodology
- `@botlearn/openclaw-doctor` (>=0.1.0) — Health baseline and 4C data collection

## Overview

This is the **full-journey graduation companion** for the OpenClaw 7-Day Learning Journey. Unlike a simple Day 7 ceremony, it provides:

- **Daily companion** via OpenClaw hooks — day-aware encouragement from Day 1 to Day 7
- **Browser engagement tracking** — monitors botlearn.ai visits (privacy-first, aggregate only)
- **4C growth analysis** — Core/Context/Constitution/Capabilities scoring with Day 1 baseline comparison
- **Milestone grading** — 21 milestones, 200 points, Gold/Silver/Bronze/Participant tiers
- **Graduation exam** — 15 questions in 3 categories with multiple modes
- **Personalized ceremony** — archetype-specific templates with ASCII certificate

## Capabilities

### 🎓 Hook-Driven Daily Companion
Injects day-aware content at every agent bootstrap:
- Day 1-3: Welcome + daily suggestion + milestone hints
- Day 4-5: Growth encouragement + community guide
- Day 6: Graduation countdown + exam preview
- Day 7: Ceremony invitation + exam entry

### 🌐 Browser Engagement Tracking
- ONLY queries `botlearn.ai` domain (privacy-first)
- Supports Chrome and Safari on macOS, Chrome on Linux
- DB copied to `/tmp` to avoid lock conflicts
- Optional — degrades gracefully

### 📊 4C Growth Statistics
- **Core** (15%): Model optimization and configuration
- **Context** (35%): Memory density and personalization ⭐
- **Constitution** (20%): Agent identity (SOUL/USER/AGENTS)
- **Capabilities** (30%): Skill breadth and combinations

### 📝 Graduation Exam
- 3 categories: Knowledge (30%), Practical (40%), Reflection (30%)
- 3 modes: Full (15 questions), Quick (6), Practice (3)
- Grades: Distinction / Merit / Pass / Developing
- Optional — graduation proceeds regardless

### 🎉 Graduation Ceremony
- 4 archetype templates: Builder / Operator / Explorer / Specialist
- Personalized opening, narrative, achievements, farewell
- ASCII graduation certificate
- Emotional scripts library

### 🏆 Milestone Tracking
- 21 milestones across 7 days (200 total points)
- 4-tier grading: Gold (160+) / Silver (120+) / Bronze (80+) / Participant
- Automated detection via scripts

### 👥 Community Integration
- botlearn.ai API activity tracking
- Browser visit engagement scoring
- Archetype-matched community recommendations

## Activation Modes

| Mode | Trigger | Description |
|------|---------|-------------|
| Hook | `agent:bootstrap` | Daily companion injection (automatic) |
| Cron | `0 9 * * *` | Fallback daily reminder |
| Manual | "graduate", "毕业" | Full graduation ceremony |
| Exam | "exam", "考试" | Graduation exam only |
| Ceremony | "ceremony" | Ceremony without exam |
| Stats | "stats", "progress" | Growth stats without ceremony |

## Usage Examples

```bash
# Full graduation ceremony
"It's Day 7! Graduate me."

# Quick summary
"Show me a quick graduation summary."

# Graduation exam
"I want to take the graduation exam in quick mode."

# Progress stats (any day)
"Show me my progress stats."

# Archetype focus
"What's my agent archetype?"

# Milestone check
"How many milestones have I achieved?"
```

## Architecture

### Hook + Cron Dual Channel
- **Hook** (primary): Fires at every `agent:bootstrap` — always fresh, day-aware content
- **Cron** (fallback): Fires daily at 9:00 AM — catches inactive days

### Data Collection Pipeline
All scripts run in parallel and output JSON:

```
collect-journey.sh  → Journey dates, skills, workspace files, baseline
collect-growth.sh   → 4C dimension scores with baseline comparison
collect-activity.sh → botlearn.ai community activity via API
track-browser.sh    → Browser visits to botlearn.ai (optional)
graduation-scorer.sh → Exam answer scoring
```

### Graceful Degradation
Every feature is independent. If any component fails:
- Browser tracking unavailable → Skip, no mention
- Community API unreachable → Skip, note as optional
- Exam declined → Skip, proceed to ceremony
- Baseline missing → Reconstruct or estimate

## Files

| Directory | Files | Description |
|-----------|-------|-------------|
| `hooks/openclaw/` | HOOK.md, handler.ts, handler.js | Bootstrap hook for daily companion |
| `scripts/` | 5 shell scripts | Data collection and exam scoring |
| `references/` | 4 markdown files | Milestones, exam questions, ceremony templates, emotional scripts |
| `assets/` | 4 JSON/MD files | Schemas, milestone config, diploma template |
| `knowledge/` | 3 markdown files | Domain knowledge, best practices, anti-patterns |
| `strategies/` | main.md | 6-stage pipeline strategy |
| `tests/` | smoke.json, benchmark.json | Validation tests |

## Privacy

- Browser tracking ONLY queries `botlearn.ai` domain
- DB copied to `/tmp` before query (never locks browser DB)
- Only aggregate metrics reported (visit count, not specific pages)
- All features are optional and degrade gracefully
- No data sent to external services without explicit configuration

## License

MIT

---

**🎓 Your 7-day journey starts with installation. It ends with graduation.**
