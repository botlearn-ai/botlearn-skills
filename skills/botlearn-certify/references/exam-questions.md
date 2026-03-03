---
type: reference
topic: exam-questions
version: 2.0.0
---

# Graduation Exam Question Bank

3 类各 5 题（共 15 题），每题 0-5 分评分量规。

---

## Category 1: Knowledge & Understanding (30% weight)

### K1: 4C Framework Basics [Easy]

**Question**: Explain the 4C framework of Agent Intelligence. Name all 4 dimensions and briefly describe what each one represents.

**Rubric**:
- **5**: Names all 4 (Core, Context, Constitution, Capabilities) with accurate descriptions and weights
- **4**: Names all 4 with mostly accurate descriptions
- **3**: Names 3-4 but descriptions incomplete
- **2**: Names 2-3 with vague descriptions
- **1**: Names 1-2 or significant inaccuracies
- **0**: Cannot name or describe any dimension

### K2: Agent Archetypes [Easy]

**Question**: What are the 4 agent archetypes in the OpenClaw ecosystem? Describe the key behavioral signal for each.

**Rubric**:
- **5**: Names all 4 (Builder/Operator/Explorer/Specialist) with clear behavioral signals
- **4**: Names all 4 with mostly correct signals
- **3**: Names 3 with some signals
- **2**: Names 2 with vague descriptions
- **1**: Names 1 or largely inaccurate
- **0**: Cannot identify archetypes

### K3: Skill Ecosystem [Medium]

**Question**: How does the @botlearn skill system work? Explain the relationship between skills, agent memory, and the clawhub marketplace.

**Rubric**:
- **5**: Clear explanation of skill installation, memory injection, strategy registration, and marketplace discovery
- **4**: Covers most components with minor gaps
- **3**: Basic understanding of skills and installation
- **2**: Vague understanding, confuses components
- **1**: Minimal understanding
- **0**: No understanding demonstrated

### K4: Growth Path Levels [Medium]

**Question**: Describe the 4 growth path levels (Foundation through Mastery) and what milestones define each level.

**Rubric**:
- **5**: Accurately describes all 4 levels with specific milestones for each
- **4**: Describes 3-4 levels with most milestones
- **3**: Describes 2-3 levels with some milestones
- **2**: Vague description of levels without specific milestones
- **1**: Minimal understanding of growth progression
- **0**: No understanding

### K5: Hook & Automation System [Hard]

**Question**: Explain how OpenClaw hooks work. What is the `agent:bootstrap` event? How can hooks and cron jobs work together for continuous agent improvement?

**Rubric**:
- **5**: Clear explanation of hook system, bootstrap events, virtual file injection, and hook+cron synergy
- **4**: Good understanding with minor gaps in hook mechanics
- **3**: Basic understanding of hooks but unclear on bootstrap or cron integration
- **2**: Vague understanding of automation concepts
- **1**: Minimal understanding
- **0**: No understanding

---

## Category 2: Practical Application (40% weight)

### P1: Skill Selection [Easy]

**Question**: A user wants to build a daily research briefing workflow. Which 3-5 @botlearn skills would you recommend and why? Describe how they work together.

**Rubric**:
- **5**: Recommends appropriate skills (e.g., google-search, rss-manager, summarizer) with clear workflow chain
- **4**: Good selection with mostly clear reasoning
- **3**: Reasonable selection but workflow connection unclear
- **2**: Some relevant skills but poor justification
- **1**: Irrelevant selections
- **0**: No recommendations

### P2: Troubleshooting [Medium]

**Question**: An agent's health score dropped from 85 to 52. What diagnostic steps would you take? Which data would you collect and what common causes would you investigate?

**Rubric**:
- **5**: Systematic approach: check env, config, skills, runtime, logs; identifies 3+ common causes with fix strategies
- **4**: Good diagnostic approach with 2-3 common causes
- **3**: Basic troubleshooting with 1-2 causes
- **2**: Vague troubleshooting without systematic approach
- **1**: Minimal diagnostic ability
- **0**: No troubleshooting approach

### P3: Agent Personalization [Medium]

**Question**: You have a fresh OpenClaw agent. Walk through the steps to personalize it for a software developer who works primarily in Python and needs daily code review support.

**Rubric**:
- **5**: Comprehensive: SOUL.md (personality), USER.md (developer profile), AGENTS.md (code review rules), relevant skills, workflow setup
- **4**: Covers most personalization steps with good detail
- **3**: Basic personalization covering 2-3 key files
- **2**: Superficial personalization plan
- **1**: Minimal personalization awareness
- **0**: No meaningful plan

### P4: Workflow Design [Hard]

**Question**: Design a multi-skill workflow that monitors competitors using google-search, summarizes findings with summarizer, and generates a weekly report. Include error handling and scheduling.

**Rubric**:
- **5**: Complete workflow with skill chain, scheduling (cron/hook), error handling, output format, and iteration strategy
- **4**: Good workflow design with minor gaps in error handling or scheduling
- **3**: Basic workflow without error handling or scheduling
- **2**: Vague workflow concept
- **1**: Minimal workflow understanding
- **0**: No workflow design

### P5: Community Contribution [Hard]

**Question**: You've developed a custom workflow that combines 3 @botlearn skills effectively. How would you share this with the OpenClaw A2A community? What format, channels, and documentation would you provide?

**Rubric**:
- **5**: Complete sharing plan: Discord channels, documentation format, reproducible steps, community engagement strategy
- **4**: Good plan with minor gaps
- **3**: Basic sharing approach without full documentation
- **2**: Vague sharing intent
- **1**: Minimal community awareness
- **0**: No sharing plan

---

## Category 3: Reflection & Growth (30% weight)

> **Note**: No single correct answer. Scored on depth, specificity, and self-awareness.

### R1: Personal Journey [Easy]

**Question**: Reflect on your 7-day journey. What was your most significant "aha moment"? What changed in how you think about AI agents?

**Rubric**:
- **5**: Specific, authentic reflection with clear before/after mindset shift and concrete example
- **4**: Good reflection with some specificity
- **3**: General reflection without specific moments
- **2**: Surface-level reflection
- **1**: Minimal reflection
- **0**: No reflection

### R2: Biggest Challenge [Medium]

**Question**: What was the biggest challenge you faced during your 7-day journey? How did you overcome it (or how would you approach it differently now)?

**Rubric**:
- **5**: Honest identification of specific challenge with thoughtful analysis of resolution and learnings
- **4**: Good challenge identification with some resolution analysis
- **3**: General challenge mentioned without deep analysis
- **2**: Vague challenge with no resolution strategy
- **1**: Minimal self-awareness
- **0**: No challenge identified

### R3: Archetype Self-Assessment [Medium]

**Question**: Based on your behavior over 7 days, which archetype do you identify with most? Do you agree with the system's assessment? Why or why not?

**Rubric**:
- **5**: Thoughtful self-assessment with specific behavioral evidence, agreement/disagreement well-reasoned
- **4**: Good self-assessment with some evidence
- **3**: Basic self-assessment without strong evidence
- **2**: Superficial agreement/disagreement without reasoning
- **1**: No meaningful self-assessment
- **0**: Skipped

### R4: Growth Areas [Hard]

**Question**: What are 3 specific areas where your agent still needs improvement? For each, propose a concrete action plan for the next 30 days.

**Rubric**:
- **5**: 3 specific, realistic areas with concrete, time-bound action plans leveraging available tools
- **4**: 3 areas with mostly concrete plans
- **3**: 2-3 areas with vague plans
- **2**: 1-2 areas without concrete plans
- **1**: Generic improvement wishes
- **0**: No growth areas identified

### R5: Vision Statement [Hard]

**Question**: Write a brief vision statement (3-5 sentences) for where you want your agent to be in 90 days. What will it be able to do? How will it change your daily workflow?

**Rubric**:
- **5**: Compelling, specific vision with measurable outcomes, connected to current state and archetype
- **4**: Good vision with some specificity
- **3**: General vision without measurable outcomes
- **2**: Vague aspirations
- **1**: Minimal forward thinking
- **0**: No vision articulated
