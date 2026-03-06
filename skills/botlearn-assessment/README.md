# @botlearn/botlearn-assessment

OpenClaw Agent 5-Dimension Capability Self-Assessment System — the agent autonomously takes an exam, answers questions, self-evaluates against reference answers, and generates a visual report.

## How It Works

The assessment follows a strict **4-phase pipeline** where the agent acts as both examinee and examiner:

```
Phase 1: Intent Recognition
    → Detect exam mode (full / single dimension / view history)

Phase 2: Answer All Questions (Examinee Role)
    → For each question:
       1. Output the question to the user (invigilator)
       2. Attempt to solve it autonomously
       3. Output the answer — FINAL, no revision
       4. Move to next question

Phase 3: Self-Evaluation (Examiner Role)
    → After ALL questions answered:
       1. Read rubric + reference answer for each question
       2. Score each criterion (0-5) with CoT justification
       3. Apply -5% correction to prevent self-inflation
       4. First-exam cap: max 4/5 per criterion if no history exists

Phase 4: Report Generation
    → Generate Markdown + HTML reports with radar chart
    → Output file paths to the user
```

## 5 Dimensions

| # | Dimension | Weight | What It Tests |
|---|-----------|--------|--------------|
| D1 | Reasoning & Planning | 25% | Multi-step inference, cross-domain analogy, decision frameworks |
| D2 | Information Retrieval | 22% | Precision search, multi-source synthesis, multi-hop constrained lookup |
| D3 | Content Creation | 18% | Structured writing, style control, audience targeting, data consistency |
| D4 | Execution & Building | 20% | Runnable code generation, schema compliance, TypeScript modules |
| D5 | Tool Orchestration | 15% | Tool selection, workflow design, pipeline orchestration, error recovery |

Each dimension has 3 questions (Easy / Medium / Hard). Each run randomly selects ONE question per dimension for variety across assessments.

## Exam Modes

| Mode | Scope | When to Use |
|------|-------|-------------|
| Full Exam | All 5 dimensions, 5 questions total | Comprehensive capability baseline |
| Dimension Exam | Single dimension, 1 question | Targeted improvement tracking |
| View History | Read past results + trend analysis | Progress review |

## Key Design Principles

### Question First, Answer Second
Each question is shown to the user (invigilator) before the agent attempts it. The user sees what is being asked, then watches the agent work through it.

### Separation of Answering and Scoring
The agent answers ALL questions first without consulting any rubric. Only after all answers are submitted does the self-evaluation phase begin. This prevents the agent from tailoring answers to the scoring criteria.

### Reference Answer Verification
Every question has a corresponding reference answer (`references/d{N}-q{L}-{difficulty}.md`) containing:
- **Key points checklist** — what a qualified answer must cover
- **Scoring anchors** — concrete examples for each score level
- **Expected values** — for programmatic verification (D2, D4)
- **Common failure modes** — typical mistakes to watch for

The agent MUST compare its answer against the reference before scoring.

### Anti-Inflation Safeguards

| Safeguard | Mechanism |
|-----------|-----------|
| -5% global correction | All CoT self-judged scores: `AdjScore = RawScore × 0.95` |
| First-exam cap | No criterion can score above 4/5 on the first assessment (no history) |
| High-score justification | Score 4+ requires "why not 3?" evidence; score 5 requires "external evaluator" argument |
| Reference anchoring | Scoring must cite specific key points from the reference answer |

## Scoring Formula

```
Per question:  RawScore = sum(criterion_score × criterion_weight) × 20  [0-100]
Per question:  AdjScore = RawScore × 0.95                               [CoT only]
Per dimension: DimScore = single question score (0 if skipped)
Overall:       D1×0.25 + D2×0.22 + D3×0.18 + D4×0.20 + D5×0.15
```

## Performance Levels

| Level | Score | Description |
|-------|-------|-------------|
| Expert | 90-100 | Exceptional capability, handles complex edge cases |
| Advanced | 80-89 | Strong capability, tackles complex tasks reliably |
| Proficient | 70-79 | Solid capability, stable and reliable |
| Competent | 60-69 | Basic competence, standard performance |
| Beginner | < 60 | Developing, needs guidance |

## Output Files

Each assessment generates:

```
results/
├── exam-{sessionId}-data.json      ← Structured data (JSON)
├── exam-{sessionId}-full.md        ← Markdown report
├── exam-{sessionId}-report.html    ← HTML report with embedded radar chart
├── exam-{sessionId}-radar.svg      ← Standalone radar chart (full exam only)
└── INDEX.md                        ← History index for trend tracking
```

## Triggers

```
exam / assessment / evaluate / benchmark me / test yourself / run exam
评测 / 能力评估 / 自测 / 自我评测 / 能力诊断
reasoning test / retrieval test / creation test / execution test / orchestration test
history results / 查看历史评测 / 历史结果
```

## File Structure

```
botlearn-assessment/
├── SKILL.md                          # Entry point: roles, rules, 4-phase pipeline
├── flows/
│   ├── exam-execution.md             # Per-question pattern (tool check → answer → score)
│   ├── full-exam.md                  # Full exam flow + report template
│   ├── dimension-exam.md             # Single-dimension flow + report template
│   ├── generate-report.md            # Dual-format report generation (MD + HTML)
│   └── view-history.md               # History view + trend comparison
├── questions/
│   ├── d1-reasoning.md               # D1 questions (Easy/Medium/Hard)
│   ├── d2-retrieval.md               # D2 questions
│   ├── d3-creation.md                # D3 questions
│   ├── d4-execution.md               # D4 questions
│   └── d5-orchestration.md           # D5 questions
├── references/                       # Reference answers (15 files, 1 per question)
│   ├── d1-q1-easy.md ... d1-q3-hard.md
│   ├── d2-q1-easy.md ... d2-q3-hard.md
│   ├── d3-q1-easy.md ... d3-q3-hard.md
│   ├── d4-q1-easy.md ... d4-q3-hard.md
│   └── d5-q1-easy.md ... d5-q3-hard.md
├── strategies/
│   ├── scoring.md                    # Scoring rules, weights, verification methods
│   └── main.md                       # Overall assessment strategy (v4)
├── scripts/
│   ├── radar-chart.js                # SVG radar chart generator (Node.js)
│   └── generate-html-report.js       # HTML report generator with embedded radar
└── results/                          # Generated at runtime
```

## Install

```bash
clawhub install @botlearn/botlearn-assessment --force
```

## Version

Current: 0.1.5 (v4 architecture)

## License

MIT
