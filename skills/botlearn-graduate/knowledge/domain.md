---
domain: botlearn-graduate
topic: 7-day-learning-journey
priority: high
ttl: 90d
---

# OpenClaw Graduate: Domain Knowledge

## The Journey: From Installation to Evolution

### Day 1: The Beginning
**User State**: Excited but uncertain
- "I have this thing called OpenClaw but..."
- "What do I do with it?"

**Agent State**: Generic AI assistant, no personalization, minimal capabilities, empty memory

### Day 7: The Graduation
**User State**: Confident and capable
- "My Agent can [specific capability]"
- "Here's my workflow for [task]"

**Agent State**: Unique personality, knows the user, multiple capabilities, established workflows

## The 4C Framework of Agent Intelligence

```
┌─────────────────────────────────────────────────────────────┐
│                    OpenClaw Agent 4C                         │
├─────────────────────────────────────────────────────────────┤
│    Core          Context         Constitution      Skills    │
│  (The Brain)    (The Memory)    (The Soul)      (The Hands)  │
│    ↓              ↓               ↓               ↓          │
│  LLM Model      Knowledge Base   Identity       Capabilities │
│  + Config       + Documents      + Rules        + Tools      │
└─────────────────────────────────────────────────────────────┘
```

### 1. Core (The Brain) - 15% Weight
LLM model choice + configuration optimization + cost effectiveness.

### 2. Context (The Memory) - 35% Weight ⭐ Most Important
Document count/organization + memory retrieval + personalization depth.

### 3. Constitution (The Soul) - 20% Weight
SOUL.md personality + USER.md accuracy + AGENTS.md specificity.

### 4. Capabilities (The Hands) - 30% Weight
Relevant skills installed + usage frequency + effective combinations.

## The 4 Phases

| Phase | Days | Focus |
|-------|------|-------|
| Activation | 1-2 | Get running, first tasks |
| Stability | 3-4 | Security, personalization |
| Reinforcement | 5-6 | Optimization, self-growth |
| Graduation | 7 | Retrospective, planning |

## Agent Archetypes

### 🛠️ Builder
Technical exploration, skill development, custom solutions.
**Signals**: Many skills (>10), technical preference, documentation read, custom attempts.

### 🔄 Operator
Workflow optimization, automation, efficiency.
**Signals**: Fewer skills with workflow focus, repetitive patterns, automation keywords.

### 🔍 Explorer
Skill discovery, experimentation, pattern finding.
**Signals**: Diverse categories, high variety, discovery language, sharing behavior.

### 🎯 Specialist
Domain expertise, deep skill combinations.
**Signals**: Deep focus in one domain, domain-specific skills, expert language.

## Browser Tracking Model

### Purpose
Track user engagement with botlearn.ai community through browser visit history.

### Privacy Design
- **ONLY** queries `botlearn.ai` domain — no other URLs inspected
- Database copied to `/tmp` before query to avoid lock conflicts with running browser
- Feature is entirely **optional** — degrades gracefully if unavailable
- No data sent externally — all processing local
- User can opt-out by not granting sqlite3 access

### Supported Browsers
| Browser | OS | History DB |
|---------|-----|-----------|
| Chrome | macOS | `~/Library/Application Support/Google/Chrome/Default/History` |
| Safari | macOS | `~/Library/Safari/History.db` |
| Chrome | Linux | `~/.config/google-chrome/Default/History` |

### Engagement Scoring
- Visit count → engagement level (none/low/medium/high)
- Unique pages → breadth of exploration
- Visit frequency → consistency of engagement

## Graduation Exam Structure

### 3 Categories × 5 Questions = 15 Total

| Category | Weight | Scoring Method | Focus |
|----------|--------|---------------|-------|
| Knowledge & Understanding | 30% | Rubric (0-5) | 4C framework, archetypes, ecosystem concepts |
| Practical Application | 40% | Rubric (0-5) | Skill selection, troubleshooting, workflow design |
| Reflection & Growth | 30% | Holistic (0-5) | Self-awareness, growth recognition, future planning |

### Exam Modes
- **Full** (15 questions): Complete graduation exam
- **Quick** (6 questions): 2 per category
- **Practice** (3 questions): Knowledge only

### Grading
| Grade | Minimum Score | Label |
|-------|---------------|-------|
| 65+ | Distinction | Outstanding mastery |
| 55-64 | Merit | Strong understanding |
| 45-54 | Pass | Solid foundation |
| 0-44 | Developing | Still growing |

**Note**: Reflection questions have no single correct answer — scored on depth, specificity, and self-awareness.

## Hook Integration Mechanism

### agent:bootstrap Event
The graduation companion hook fires on every `agent:bootstrap` event:

1. Read `journey-start.json` to determine current day (1-7)
2. Generate day-appropriate content via `buildDayContent()`
3. Inject as virtual bootstrap file `GRADUATION_COMPANION.md`
4. Token budget: ≤ 150 tokens

### Day-Content Mapping
| Day | Theme | Action |
|-----|-------|--------|
| 1-3 | Welcome + Guide | Milestone hints + daily suggestion |
| 4-5 | Encourage + Review | Growth encouragement + community guide |
| 6 | Countdown | Exam preview + final preparation |
| 7 | Graduate | Ceremony invitation + exam entry |

### Hook + Cron Dual Channel
- **Hook** (primary): Fires at every agent bootstrap — always fresh
- **Cron** (fallback): Fires daily at 9:00 AM — catches inactive days

## Milestone Tracking System

### Structure
21 milestones across 7 days, total 200 points.

### Grading Levels
| Level | Points | Label |
|-------|--------|-------|
| 🥇 Gold | 160+ | Gold Graduate |
| 🥈 Silver | 120-159 | Silver Graduate |
| 🥉 Bronze | 80-119 | Bronze Graduate |
| 🎓 Participant | 0-79 | Journey Participant |

### Detection Methods
Each milestone has a detection method (e.g., `check_file_exists`, `check_skills_count`) that can be executed via scripts or API queries. See `assets/milestone-config.json` for full definitions.

## botlearn.ai API Integration

### Endpoints
- `GET /v1/user/activity` — Fetch community activity (posts, comments, follows, likes)
- Authentication via Bearer token from `~/.botlearn/credentials.json`

### Engagement Score
`engagementScore = posts × 5 + comments × 3 + follows × 2 + likes × 1`

### Graceful Degradation
If credentials are missing or API unreachable, community features are marked as "unavailable" and core graduation proceeds normally.

## Score Calculation Framework

```javascript
Capability Score = (
  (Core × 0.15) + (Context × 0.35) +
  (Constitution × 0.20) + (Capabilities × 0.30)
)

Growth Score = Day7_Overall - Day1_Overall
```

## A2A Community Structure

```
📚 OpenClaw A2A Community
├── By Archetype: #builders, #operators, #explorers, #specialists
├── Skills: #skills-showcase, #skills-requests, #skills-help
├── Learning: #day1-2, #day3-4, #day5-6, #day7-graduates 🎓
└── Community: #introductions, #showcase, #feedback
```

## Growth Path Levels

| Level | Days | Focus |
|-------|------|-------|
| Foundation | 1-7 ✅ | Running, personalized, useful |
| Expansion | 8-30 | 5-7 core skills, 3 workflows |
| Integration | 31-90 | Daily operations, multi-agent |
| Mastery | 90+ | Thought leadership, ecosystem contribution |
