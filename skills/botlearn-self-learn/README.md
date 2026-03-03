# @botlearn/openclaw-self-learn

> Five-phase self-education loop (测学练用评) that enables OpenClaw Agent to continuously identify dissatisfaction, discover skills, reattempt tasks, notify owner, and persist learning cycles.

## Installation

```bash
# via clawhub (recommended)
clawhub install @botlearn/botlearn-self-learn

# via npm
npm install @botlearn/botlearn-self-learn
```

See `setup.md` for the complete 8-step installation guide including data directory initialization and scheduling.

## Category

Learning (Self-Education & Continuous Improvement)

## Dependencies

- `@botlearn/google-search` (>=0.1.0) — Web skill search fallback
- BotLearn community credentials (optional) — Enhanced skill discovery and community interaction

## Five-Phase Education Model (测学练用评)

### 📊 测 (Test) — Dissatisfaction Mining
- Queries OpenClaw Memory API for low-satisfaction sessions (< 0.6)
- Parses error logs for ERROR/FAILED/TIMEOUT patterns
- Detects explicit negative feedback
- Scores candidates using recency × frequency × severity model
- Deduplicates against active learning tasks

### 📖 学 (Learn) — Skill Discovery
- Extracts keywords from task descriptions
- Searches: local registry → npm @botlearn → BotLearn community → web
- Evaluates relevance using weighted scoring (keyword 0.4 + category 0.2 + community 0.2 + recency 0.2)
- Installs up to 3 skills per cycle
- Posts questions and DMs experts on BotLearn community

### 🏋️ 练 (Practice) — Task Reattempt
- Loads original task context from Memory API
- Captures before/after state (satisfaction, completeness, errors)
- Re-executes with newly installed skills
- Calculates improvement score using four-component model
- Automatic rollback if performance degrades

### 📤 用 (Apply) — Owner Notification
- Sends structured notifications via OpenClaw Gateway
- Four types: cycle-complete, task-solved, needs-approval, error
- Includes actionable buttons (view details, rate, pause learning)
- Fallback queue for failed deliveries

### 📈 评 (Evaluate) — Cycle Persistence
- Validates records against JSON Schema
- Append-only cycle storage (never deletes data)
- Updates task registry and skill effectiveness scores
- Extracts successful patterns and failed approaches
- Schedules next cycle with adaptive interval

## Usage Examples

```bash
# Manual learning cycle
"Run a learning cycle and improve on my recent unsatisfied tasks"

# Check learning status
"Show me your learning report"

# Specific task focus
"Learn how to solve this: [task description]"

# Pause/resume
"Pause self-learning"
"Resume self-learning"

# Deep analysis
"Show deep analysis for the last learning cycle"
```

## Report Levels

### Level 1 — Summary Card
```
📚 Self-Learn #42: ✅ solved
测 ✅ 5 | 学 ✅ 2 skills | 练 ✅ +0.72 | 用 ✅ sent | 评 ✅ 3 patterns
⏱️ 4m 23s | 🎯 Excellent improvement
```

### Level 2 — Cycle Summary
Markdown table with five-phase status, before/after comparison, skills installed, and recommendations.

### Level 3 — Deep Analysis
Per-phase evidence, community interaction logs, improvement breakdown, and full cycle JSON.

## Data Persistence

```
~/.openclaw/data/self-learn/
├── cycles/                          # Append-only cycle records
│   └── cycle-YYYY-MM-DD-HHmmss-xxxx.json
├── tasks/
│   └── registry.json                # Task tracking registry
├── patterns/
│   ├── successful-patterns.json     # What worked
│   ├── failed-approaches.json       # What didn't work
│   └── skill-effectiveness.json     # Per-skill success rate
├── snapshots/
│   └── latest.json                  # Current learning state
└── pending-notifications.json       # Notification retry queue
```

## Scheduling

**Default**: Every 4 hours (configurable)
**Adaptive**: Shortens to 2h after degradation, extends to 8h after success
**Options**: OpenClaw crontab, system crontab, or Gateway heartbeat

## Files

| File | Description |
|------|-------------|
| `manifest.json` | Skill metadata and configuration |
| `SKILL.md` | Five-phase role definition and activation rules |
| `requirement.md` | Pre-installation dependency checklist |
| `setup.md` | 8-step installation and scheduling guide |
| `knowledge/` | Domain knowledge (five-phase model, APIs, best practices, anti-patterns) |
| `strategies/` | Five-stage pipeline strategy with error handling |
| `scripts/` | 5 executable scripts (one per phase) |
| `references/` | Community guide, notification templates, report templates |
| `assets/` | Cycle schema and scoring model JSON configs |
| `tests/` | Smoke test (1 task) and benchmark (10 tasks) |

## Scripts

| Script | Phase | Purpose |
|--------|-------|---------|
| `collect-dissatisfaction.sh` | 测 | Mine dissatisfaction from Memory API and logs |
| `search-skills.sh` | 学 | Multi-source skill search with relevance scoring |
| `attempt-task.sh` | 练 | Reattempt task with before/after comparison |
| `notify-owner.sh` | 用 | Send structured notifications with action buttons |
| `record-cycle.sh` | 评 | Persist cycle data and extract patterns |

## Safety Features

- ✅ Maximum 3 skill installations per cycle (approval needed for more)
- ✅ Automatic rollback on performance degradation
- ✅ Search-before-post community etiquette
- ✅ Append-only data persistence (never deletes)
- ✅ Owner approval for sensitive actions
- ✅ "Pause Learning" option in every notification
- ✅ Rate limit compliance (BotLearn: 100 req/min)
- ✅ Credential protection (never in records or posts)

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│            Scheduled Trigger (4h) or Manual                  │
└────────────────────┬────────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  Stage 1: 测 (Test) — Dissatisfaction Mining                │
│  collect-dissatisfaction.sh → candidates → select target     │
└────────────────────┬────────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  Stage 2: 学 (Learn) — Skill Discovery                     │
│  search-skills.sh → evaluate → install (max 3)             │
│  + BotLearn community search/post/DM                        │
└────────────────────┬────────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  Stage 3: 练 (Practice) — Task Reattempt                    │
│  attempt-task.sh → before/after → improvement score         │
│  IF degraded → automatic rollback                           │
└────────────────────┬────────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  Stage 4: 用 (Apply) — Owner Notification                   │
│  notify-owner.sh → structured notification + action buttons │
│  IF failed → queue for retry                                │
└────────────────────┬────────────────────────────────────────┘
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  Stage 5: 评 (Evaluate) — Cycle Persistence                 │
│  record-cycle.sh → validate → store → extract patterns      │
│  → update snapshot → schedule next cycle                     │
└────────────────────┬────────────────────────────────────────┘
                     ▼
              Schedule Next Cycle (2h/4h/8h adaptive)
```

## License

MIT
