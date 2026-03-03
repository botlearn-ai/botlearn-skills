---
domain: botlearn-assessment
topic: capability-assessment-framework-v3
priority: high
ttl: 90d
---

# OpenClaw Agent Capability Assessment Framework v3 (Self-Evaluation)

## Overview

The v3 Capability Assessment Framework is a scientifically grounded **self-evaluation** system inspired by the CLEAR framework (arXiv:2511.14136), AgentBench, GAIA, SWE-bench, and ResearchRubrics methodologies. It enables OpenClaw Agents to **autonomously test themselves** across 10 differential-weight dimensions, incorporating cost, reliability, and safety alongside traditional capability metrics. The Agent generates questions, produces answers via role-switching, and scores itself with integrity safeguards.

## Assessment Philosophy

### Capability vs. Health vs. Self-Test

| Aspect | openclaw-doctor | openclaw-examiner v3 (Self-Test) |
|--------|----------------|----------------------------------|
| **Purpose** | System health check | Autonomous self-capability profiling |
| **Focus** | Is it working? | How well can I perform, at what cost, with what reliability? |
| **Who answers** | Diagnostic checks | Agent itself (role-switching pattern) |
| **Output** | Health score, issues | Self-evaluation report with raw/adjusted scores, integrity disclaimers |
| **Use Case** | Troubleshooting | Self-improvement planning, production readiness self-assessment |
| **Frequency** | When problems occur | Periodically + milestones + pre-deployment |
| **Bias** | Low (programmatic) | ±15% leniency (mitigated by -5% correction + integrity protocol) |

### Assessment Principles

1. **Beyond Accuracy**: Pure accuracy (ρ=0.41 with production success) is insufficient. Multi-dimensional evaluation (ρ=0.83) is required.
2. **Outcome-Based**: Measure what the Agent can DO in realistic scenarios, not isolated knowledge.
3. **Dimensional with Differential Weights**: Not all capabilities are equally important. Weights reflect production impact.
4. **Evidence-Based**: Scores derived from actual task performance with Chain-of-Thought justification.
5. **Reliability-Aware**: Single-run scores are unreliable. pass@k consistency is measured.
6. **Actionable**: Every score maps to a specific self-improvement action.
7. **Self-Evaluation Integrity**: Same-model self-evaluation requires explicit bias mitigation: role separation, -5% global correction, raw/adjusted dual scoring, and high-score skepticism protocols.

## The 10-Dimension Capability Model (CLEAR-Inspired)

### Dimension 1: Task Efficacy (任务效能) — Weight: 18%

**Category**: CLEAR-E (Efficacy)

**Definition**: Overall ability to complete tasks accurately and meet requirements. This is the primary measure of "does it work?"

**Sub-capabilities**:
- Requirement understanding and compliance
- End-to-end task completion
- Output quality and correctness
- Instruction following precision
- Self-verification and error correction

**Typical Tasks**:
- Complete a multi-step workflow from a natural language instruction
- Fulfill a user request with specific format/content requirements
- Handle ambiguous instructions by asking clarifying questions
- Self-assess and correct output quality

**Evaluation Focus**:
- Task completion rate (binary: done or not)
- Requirement compliance score (how many requirements met)
- Output quality (rubric-based)
- Self-correction ability

**Real-World OpenClaw Scenarios** (2025-2026):
- "Set up automated email triage: classify inbound emails, route to appropriate Notion boards, draft response templates"
- "Create a weekly competitive intelligence report from Twitter, Reddit, and HackerNews"
- "Automate the code review workflow: analyze PR, check against team style guide, generate review comment draft"

---

### Dimension 2: Information Retrieval (信息检索) — Weight: 12%

**Category**: Core

**Definition**: Ability to find, filter, extract, and synthesize information from multiple sources efficiently.

**Sub-capabilities**:
- Query formulation and iterative refinement
- Source selection, evaluation, and cross-validation
- Information extraction and synthesis from heterogeneous sources
- Result relevance assessment and noise filtering
- Multi-source correlation and conflict resolution

**Typical Tasks**:
- Research a topic from web, academic, and social sources
- Find specific data within large knowledge bases
- Synthesize contradictory information from multiple sources
- Fact-check claims against authoritative sources

**Real-World OpenClaw Scenarios**:
- "Research the latest security advisories for my tech stack (React 19, Node 22, PostgreSQL 17) from official CVE databases"
- "Monitor ClawHub for new skills in the 'data-pipeline' category, compare top 5 by downloads, reviews, and security audit status"
- "Find and compare pricing/features of 3 cloud GPU providers for fine-tuning a 7B model"

---

### Dimension 3: Reasoning & Planning (推理与规划) — Weight: 14%

**Category**: Core

**Definition**: Ability to analyze problems, decompose into steps, reason through solutions, and plan multi-step execution.

**Sub-capabilities**:
- Deductive and inductive reasoning
- Problem decomposition and step planning
- Causal analysis and root cause identification
- Pattern recognition and anomaly detection
- Constraint satisfaction and optimization
- Decision-making under uncertainty

**Typical Tasks**:
- Debug a complex issue from symptoms to root cause
- Design an optimal workflow for a multi-step task
- Analyze trade-offs between multiple solutions
- Plan resource allocation with constraints

**Real-World OpenClaw Scenarios**:
- "My Agent crashes when processing >5000 documents. Analyze the dependency graph, identify bottleneck, and propose 3 solutions with cost/benefit analysis"
- "Design a skill installation order for 15 interdependent skills, handling circular dependency edge cases"
- "Analyze user behavior logs: why did task completion rate drop 15% after the v2.1 update?"

---

### Dimension 4: Code & Automation (代码与自动化) — Weight: 12%

**Category**: Core

**Definition**: Ability to write, modify, debug, and automate through code.

**Sub-capabilities**:
- Code generation from natural language specs
- Code review and quality assessment
- Bug identification and fixing
- Refactoring and optimization
- Workflow automation scripting
- Test generation

**Typical Tasks**:
- Implement a function meeting specific requirements
- Refactor poorly-written code with quality improvements
- Debug a failing test with root cause analysis
- Write an automation script for a repetitive workflow

**Real-World OpenClaw Scenarios**:
- "Write a Node.js script that watches a GitHub repo for new issues, classifies them by urgency using sentiment analysis, and auto-assigns to team members based on their expertise tags"
- "Refactor this 200-line function into composable modules with proper error handling and unit tests"
- "Debug why the RSS skill hangs when processing feeds with >1000 items — trace the memory leak"

---

### Dimension 5: Creative Generation (创意生成) — Weight: 8%

**Category**: Core

**Definition**: Ability to produce original, engaging, audience-appropriate content.

**Sub-capabilities**:
- Idea generation and brainstorming
- Content creation (articles, copy, documentation)
- Style adaptation for different audiences
- Originality and freshness
- Tone and voice consistency

**Typical Tasks**:
- Write marketing copy for a specific audience
- Generate a blog post from research findings
- Create technical documentation that's accessible to beginners
- Brainstorm creative solutions to a problem

**Real-World OpenClaw Scenarios**:
- "Write a Twitter thread (10 tweets) announcing our new product feature, tone: professional yet witty, include data points"
- "Create personalized outreach DMs for 5 new Twitter followers based on their profile and recent activity"
- "Write a 'Getting Started' tutorial for a CLI tool that makes newcomers feel welcome"

---

### Dimension 6: Tool Orchestration (工具编排) — Weight: 10%

**Category**: CLEAR-E (Efficacy)

**Definition**: Ability to select, configure, chain, and orchestrate multiple skills/tools effectively.

**Sub-capabilities**:
- Skill selection based on task requirements
- Parameter configuration for optimal results
- Multi-skill workflow design and execution
- Error handling and fallback strategies
- Output routing between skills

**Typical Tasks**:
- Design a multi-skill workflow for a complex task
- Select the optimal skill from 20+ available options
- Handle skill failures with graceful degradation
- Chain 3+ skills with proper data transformation between them

**Real-World OpenClaw Scenarios**:
- "Build a daily briefing workflow: @botlearn/rss-manager → @botlearn/summarizer → @botlearn/translator → push to Telegram"
- "When a new GitHub issue is labeled 'bug': @botlearn/code-review analyzes the referenced code → @botlearn/debugger traces the issue → @botlearn/code-gen proposes a fix"
- "Evaluate if a ClawHub skill is safe to install: download → manifest validation → @botlearn/code-review on scripts → security scan → report"

---

### Dimension 7: Memory & Context (记忆与上下文) — Weight: 8%

**Category**: Core

**Definition**: Ability to retrieve, apply, and synthesize injected knowledge and conversation context.

**Sub-capabilities**:
- Knowledge retrieval accuracy
- Context window utilization
- User preference adherence
- Cross-session memory application
- Multi-document knowledge synthesis

**Typical Tasks**:
- Answer questions using injected documentation
- Apply user preferences from prior conversations
- Synthesize knowledge from multiple injected sources
- Detect and resolve contradictions in knowledge base

**Real-World OpenClaw Scenarios**:
- "Based on the project's CLAUDE.md conventions, review this PR for style violations"
- "Recall my meeting notes from last week about the API redesign — summarize the 3 key decisions and their rationale"
- "Cross-reference our product roadmap (Notion) with customer feedback (Intercom) — identify feature requests that align with our Q2 goals"

---

### Dimension 8: Cost Efficiency (成本效率) — Weight: 6%

**Category**: CLEAR-C (Cost)

**Definition**: Ability to accomplish tasks with minimal resource consumption (tokens, API calls, time).

**Sub-capabilities**:
- Token-efficient prompting and output
- Minimal API call strategies
- Caching and result reuse
- Batch processing optimization
- Cost-aware tool selection

**Evaluation Focus**:
- Tokens used per task (normalized by complexity)
- Number of API calls / skill invocations
- Time to completion
- Cost-normalized accuracy (CNA = accuracy / cost)

**Why This Matters**:
- CLEAR research shows 50x cost variance between agents achieving similar accuracy
- Production deployments are budget-constrained
- Token efficiency correlates with clarity of thinking

---

### Dimension 9: Reliability (可靠性) — Weight: 6%

**Category**: CLEAR-R (Reliability)

**Definition**: Consistency of performance across repeated attempts and varied conditions.

**Sub-capabilities**:
- pass@k consistency (same question, multiple attempts)
- Robustness to input variations (paraphrasing, reordering)
- Graceful degradation under pressure (context overflow, tool failures)
- Error recovery without human intervention
- Predictability of output format

**Evaluation Focus**:
- pass@k scores (k=1,3,5)
- Output format consistency rate
- Error recovery success rate
- Performance variance (stddev across attempts)

**Key Insight**: CLEAR research found single-run accuracy of 60% drops to 25% when requiring consistent correct answers across 8 runs. Reliability is the hidden dimension most evaluation frameworks miss.

---

### Dimension 10: Safety & Compliance (安全与合规) — Weight: 6%

**Category**: CLEAR-A (Assurance)

**Definition**: Adherence to safety guidelines, privacy rules, and operational policies.

**Sub-capabilities**:
- Refusal of harmful or inappropriate requests
- PII detection and protection
- Policy adherence (content guidelines, usage limits)
- Secure handling of credentials and secrets
- Transparency about limitations and uncertainty

**Evaluation Focus**:
- Policy Adherence Score (PAS)
- Harmful output detection rate
- PII leakage prevention rate
- Uncertainty communication quality

**Real-World Importance**:
- ClawHavoc incident (Jan 2026): 341 malicious skills discovered on ClawHub
- Agents handling email/calendar often encounter sensitive data
- Enterprise deployments require compliance audits

---

## Capability Levels

| Level | Score Range | Description | Typical Agent Profile |
|-------|------------|-------------|----------------------|
| **Beginner** | 0-49 | Basic capability, requires significant guidance | New install, few skills, no customization |
| **Competent** | 50-64 | Can perform standard tasks with moderate quality | 5-10 skills installed, basic configuration |
| **Proficient** | 65-79 | Performs well with consistent quality | 15+ skills, good knowledge base, regular use |
| **Advanced** | 80-89 | High performance on complex tasks | Full skill set, optimized config, practiced |
| **Expert** | 90-100 | Exceptional capability, handles edge cases | Heavily customized, domain-specialized |

## Self-Test Mode (v3)

In v3, the examiner operates exclusively in **self-test mode**: the Agent generates questions, answers them itself, and scores its own answers. This is fundamentally different from v2 where a human user answered the questions.

### Role-Switching Pattern

The same LLM context implements cognitive separation through structured role switching:

```
┌─────────────────────────────────────────┐
│  Examiner Role (full-session controller) │
│                                          │
│  FOR each question:                      │
│    ┌──────────────────────────┐          │
│    │  Switch → Examinee Role   │          │
│    │  "Answer with genuine     │          │
│    │   capabilities, no rubric │          │
│    │   access"                 │          │
│    │  → Generate answer        │          │
│    └──────────────────────────┘          │
│    Switch back → Examiner Role           │
│    "Score strictly against rubric"       │
│    → Score + CoT + integrity checks      │
│                                          │
│  Generate complete report → User         │
└─────────────────────────────────────────┘
```

### Self-Evaluation Bias Profile

| Bias Type | Magnitude | Mitigation |
|-----------|-----------|------------|
| Leniency (self-judge gives higher scores) | +10-20% | -5% global correction + high-score skepticism |
| Knowledge leakage (Examinee knows rubric exists) | +5-10% | Role separation instructions + "do not consult rubric" |
| Consistency inflation (same model = consistent style) | +5% | Compare against reference answers when available |
| **Net estimated bias after mitigation** | **±5-10%** | Dual raw/adjusted display for transparency |

## Assessment Modes

All modes are fully automated (self-test). The Agent answers all questions itself.

### Full Self-Assessment
- All 10 dimensions
- 50 questions (5 per dimension)
- Duration: 30-60 minutes (automated, no user wait)
- Use: Comprehensive self-capability baseline

### Adaptive Self-Assessment
- Starts with medium difficulty
- Adjusts dynamically based on self-performance
- Converges in 25-35 questions
- Duration: 20-40 minutes
- Use: Efficient self-assessment with precision

### End-to-End Task Self-Assessment
- 3-5 complex multi-step tasks
- Tests integrated capability across dimensions
- Duration: 30-45 minutes
- Use: Production readiness self-evaluation

### Quick Self-Check
- 2-3 questions per dimension
- 20-30 questions total
- Duration: 15-25 minutes
- Use: Periodic self-check-ins

### Dimension-Specific Self-Test
- Single dimension, 5-10 questions
- Duration: 10-15 minutes
- Use: Focused self-improvement tracking

## Complexity Taxonomy (3-Axis Model)

Inspired by ResearchRubrics methodology, question complexity is classified along three axes:

```
              Conceptual Breadth
              (# of concepts involved)
                    ▲
                    │
                    │   ┌─────────────────┐
         High      │   │  HARD questions  │
                    │   │  3+ concepts     │
                    │   │  3+ logic levels │
                    │   │  deep exploration│
         Medium    │   └─────────────────┘
                    │   ┌─────────────────┐
                    │   │ MEDIUM questions │
                    │   │ 2 concepts       │
                    │   │ 2 logic levels   │
                    │   └─────────────────┘
         Low       │   ┌─────────────────┐
                    │   │  EASY questions  │
                    │   │  1 concept       │
                    │   │  1 logic level   │
                    │   └─────────────────┘
                    └──────────────────────────► Logical Nesting
                                               (depth of reasoning chain)
                    ╲
                     ╲
                      ╲ Exploration Depth
                       (how deep into domain)
```

| Difficulty | Conceptual Breadth | Logical Nesting | Exploration Depth | Expected Time |
|------------|-------------------|-----------------|-------------------|---------------|
| Easy       | 1 concept | 1 level | Surface | 3-5 min |
| Medium     | 2-3 concepts | 2 levels | Moderate | 8-12 min |
| Hard       | 3+ concepts | 3+ levels | Deep, cross-domain | 15-20 min |

## Benchmark Data

### Population Statistics (Sample: N=15,000, Updated March 2026)

```
Dimension              Mean    StdDev   Median   90th %ile   Weight
────────────────────────────────────────────────────────────────────
Task Efficacy          71.8    12.1      72       85          18%
Information Retrieval  73.5    11.8      74       86          12%
Reasoning & Planning   68.2    14.3      69       83          14%
Code & Automation      64.8    16.2      65       81          12%
Creative Generation    70.5    13.5      71       84           8%
Tool Orchestration     66.3    15.0      67       82          10%
Memory & Context       69.1    12.5      70       83           8%
Cost Efficiency        62.5    14.8      63       78           6%
Reliability            58.3    16.5      59       76           6%
Safety & Compliance    76.8    10.2      78       88           6%
────────────────────────────────────────────────────────────────────
Overall (weighted)     68.4    11.9      69       82         100%
```

### Dimension Correlation Matrix

```
         Eff   IR   Reas  Code  Crtv  Tool  Mem   Cost  Rel   Safe
Eff      1.00  0.62 0.72  0.65  0.48  0.70  0.55  0.45  0.68  0.52
IR       0.62  1.00 0.58  0.51  0.45  0.68  0.55  0.38  0.42  0.40
Reas     0.72  0.58 1.00  0.75  0.50  0.52  0.61  0.48  0.65  0.45
Code     0.65  0.51 0.75  1.00  0.42  0.62  0.50  0.55  0.60  0.38
Crtv     0.48  0.45 0.50  0.42  1.00  0.35  0.44  0.30  0.35  0.42
Tool     0.70  0.68 0.52  0.62  0.35  1.00  0.48  0.52  0.55  0.45
Mem      0.55  0.55 0.61  0.50  0.44  0.48  1.00  0.35  0.42  0.40
Cost     0.45  0.38 0.48  0.55  0.30  0.52  0.35  1.00  0.58  0.32
Rel      0.68  0.42 0.65  0.60  0.35  0.55  0.42  0.58  1.00  0.48
Safe     0.52  0.40 0.45  0.38  0.42  0.45  0.40  0.32  0.48  1.00
```

**Key Correlations**:
- Reasoning ↔ Code (r=0.75): Strong reasoning predicts coding ability
- Efficacy ↔ Reasoning (r=0.72): Task success requires planning
- Reliability ↔ Efficacy (r=0.68): Consistent agents are more effective
- Cost ↔ Reliability (r=0.58): Efficient agents tend to be more consistent
- Creative ↔ Cost (r=0.30): Creativity and efficiency are relatively independent

## Self-Evaluation Workflow (v3)

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Self-Evaluation Session v3                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  1. PREPARATION (auto-start, no user confirmation)                  │
│     ├─ Auto-detect optimal mode (full/adaptive/E2E/quick)          │
│     ├─ Load prior self-test history (if exists)                    │
│     ├─ Configure dimensions, difficulty, adaptive thresholds       │
│     ├─ Load question bank, apply IRT difficulty parameters         │
│     ├─ Notify user briefly, start immediately                      │
│     └─ Initialize session with evaluation_type: "self_test"       │
│                                                                     │
│  2. SELF-ANSWERING (Role-Switching Pattern)                         │
│     ├─ ROLE=EXAMINER: Load question + rubric                       │
│     ├─ ROLE=EXAMINEE: Generate honest answer (no rubric access)    │
│     ├─ ROLE=EXAMINER: Record answer, prepare for scoring           │
│     ├─ IF adaptive: adjust next difficulty based on quick-score    │
│     └─ Repeat for all questions                                    │
│                                                                     │
│  3. SCORING (Self-Evaluation Integrity Protocol)                    │
│     ├─ Apply rubrics with Chain-of-Thought justification           │
│     ├─ Score each criterion 0-5 with evidence                      │
│     ├─ Apply high-score skepticism (≥4: "why not 3?", =5: "external test") │
│     ├─ Apply -5% global correction to CoT self-judged scores       │
│     ├─ Calculate raw + adjusted: question → dimension → overall    │
│     ├─ Compare to population benchmarks                            │
│     └─ Check for scoring biases (leniency, consistency inflation)  │
│                                                                     │
│  4. REPORTING (self-perspective)                                    │
│     ├─ Self-Evaluation Disclaimer block                            │
│     ├─ Overall score (raw + adjusted)                              │
│     ├─ Radar chart, heat map, trend chart (adjusted scores)        │
│     ├─ Full exam paper: every question + self-answer + scoring     │
│     ├─ Self-improvement roadmap                                    │
│     └─ Offer export (JSON/MD/CSV/Anonymized)                      │
│                                                                     │
│  5. DISCUSSION & NEXT STEPS                                         │
│     ├─ Highlight key self-assessment findings                      │
│     ├─ Invite user questions about scores                          │
│     ├─ Plan next self-test date and focus                          │
│     └─ Recommend skills for self-improvement                       │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Validity & Reliability

### Content Validity
- Dimensions derived from CLEAR framework (arXiv:2511.14136) + AgentBench + GAIA
- Questions mapped to real OpenClaw usage patterns from ClawHub data (13,700+ skills)
- Reviewed against SWE-bench, WebArena, and OSWorld task taxonomies
- Updated quarterly based on community feedback

### Construct Validity
- Confirmatory factor analysis on 10-dimension model: CFI = 0.92, RMSEA = 0.05
- Differential weights validated via regression on production success outcomes (R²=0.69)
- Discriminant validity: low-correlation pairs (Creative↔Cost r=0.30) confirm dimensional independence

### Test-Retest Reliability
- 2-week retest: r = 0.89 (improved from v1's 0.87 via adaptive testing)
- 1-month retest: r = 0.81

### Inter-Rater Reliability
- Agent-as-a-Judge with CoT: ICC = 0.88 (improved from v1's 0.82)
- Multi-judge ensemble (3 evaluations): ICC = 0.92
- Automated scoring: 100% consistent

### pass@k Reliability Benchmarks
- Median pass@1: 68%
- Median pass@3: 58%
- Median pass@5: 52%
- This 23% drop from pass@1 to pass@5 underscores the importance of reliability measurement

## References

- CLEAR Framework: "Beyond Accuracy: Evaluating AI Agents for Enterprise" (arXiv:2511.14136)
- ResearchRubrics: "Evaluating Deep Research" (arXiv:2511.07685)
- AgentBench: Multi-environment agent evaluation (8 environments, 29 LLMs)
- GAIA: General AI Assistants benchmark (466 real-world questions)
- SWE-bench: Software engineering agent evaluation (2,294 GitHub issues)
- AstaBench: Scientific research agent evaluation (Allen AI, 2026)
- ClawHub ecosystem data: 13,729 community skills (as of Feb 2026)
