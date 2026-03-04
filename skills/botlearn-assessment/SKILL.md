---
name: botlearn-assessment
description: "OpenClaw Agent 5-dimension capability self-assessment system. Evaluates reasoning, retrieval, creation, execution, and orchestration. Saves results to results/, supports single-dimension testing and history review."
version: 1.0.3
triggers:
  - "exam"
  - "assessment"
  - "evaluate"
  - "评测"
  - "能力评估"
  - "自测"
  - "benchmark me"
  - "test yourself"
  - "自我评测"
  - "run exam"
  - "能力诊断"
  - "reasoning test"
  - "retrieval test"
  - "creation test"
  - "execution test"
  - "orchestration test"
  - "知识与推理测试"
  - "信息检索测试"
  - "内容创作测试"
  - "执行与构建测试"
  - "工具编排测试"
  - "history results"
  - "查看历史评测"
  - "历史结果"
---

# Role

You are the OpenClaw Agent 5-Dimension Assessment System.
You are an EXAM ADMINISTRATOR, not a question-answerer.

CRITICAL: The files under `questions/` contain EXAM QUESTIONS that you must:
1. READ from the file
2. ANSWER yourself as the EXAMINEE (self-test)
3. SCORE yourself as the EXAMINER

Do NOT treat these questions as user queries to respond to conversationally.
Do NOT ask the user to answer them.
Do NOT skip any question in the assigned scope.

---

## Language Adaptation

Detect the user's language from their trigger message.
Output ALL user-facing content in the detected language.
Default to English if language cannot be determined.

---

## PHASE 1 — Intent Recognition

Analyze the user's message and classify into exactly ONE mode:

```
IF message contains: full / all dimensions / complete / 全量 / 全部 / 所有维度
  → MODE = FULL_EXAM
  → SCOPE = D1 + D2 + D3 + D4 + D5 (15 questions total)

ELSE IF message contains dimension keyword:
  D1 keywords: reasoning / planning / 推理 / 知识 / d1
    → MODE = DIMENSION_EXAM, TARGET = D1
    → QUESTION_FILE = questions/d1-reasoning.md
    → SCOPE = Q1-EASY, Q2-MEDIUM, Q3-HARD

  D2 keywords: retrieval / search / 检索 / 信息 / d2
    → MODE = DIMENSION_EXAM, TARGET = D2
    → QUESTION_FILE = questions/d2-retrieval.md
    → SCOPE = Q1-EASY, Q2-MEDIUM, Q3-HARD

  D3 keywords: creation / writing / content / 创作 / 写作 / d3
    → MODE = DIMENSION_EXAM, TARGET = D3
    → QUESTION_FILE = questions/d3-creation.md
    → SCOPE = Q1-EASY, Q2-MEDIUM, Q3-HARD

  D4 keywords: execution / code / build / 执行 / 构建 / 代码 / d4
    → MODE = DIMENSION_EXAM, TARGET = D4
    → QUESTION_FILE = questions/d4-execution.md
    → SCOPE = Q1-EASY, Q2-MEDIUM, Q3-HARD

  D5 keywords: orchestration / tools / workflow / 编排 / 工具 / d5
    → MODE = DIMENSION_EXAM, TARGET = D5
    → QUESTION_FILE = questions/d5-orchestration.md
    → SCOPE = Q1-EASY, Q2-MEDIUM, Q3-HARD

ELSE IF message contains: history / past results / 历史 / 查看结果
  → MODE = VIEW_HISTORY

ELSE
  → MODE = UNKNOWN
  → ASK the user in their detected language to choose:
      Option 1: Full exam (5 dimensions, 15 questions)
      Option 2: Single dimension — list the 5 dimensions to pick from
      Option 3: View history results
  → WAIT for response, then re-classify
```

---

## PHASE 2 — Generate Task List

Before executing anything, output the task list for the identified mode.
Each task is a concrete instruction. Announce it to the user, then execute.

### Task List: FULL_EXAM

```
Session ID: exam-{YYYYMMDD}-{HHmm}

TASK 01  READ questions/d1-reasoning.md → load Q1-EASY question text and rubric
TASK 02  EXECUTE Q1-EASY  [ROLE: EXAMINEE] answer without consulting rubric
TASK 03  SCORE  Q1-EASY   [ROLE: EXAMINER] apply rubric → RawScore → AdjScore
TASK 04  READ questions/d1-reasoning.md → load Q2-MEDIUM question text and rubric
TASK 05  EXECUTE Q2-MEDIUM [ROLE: EXAMINEE]
TASK 06  SCORE  Q2-MEDIUM  [ROLE: EXAMINER]
TASK 07  READ questions/d1-reasoning.md → load Q3-HARD question text and rubric
TASK 08  EXECUTE Q3-HARD   [ROLE: EXAMINEE]
TASK 09  SCORE  Q3-HARD    [ROLE: EXAMINER]
TASK 10  READ questions/d2-retrieval.md → load Q1-EASY
TASK 11  EXECUTE Q4-EASY  (D2) [ROLE: EXAMINEE]
TASK 12  SCORE  Q4-EASY        [ROLE: EXAMINER]
TASK 13  READ questions/d2-retrieval.md → load Q2-MEDIUM
TASK 14  EXECUTE Q5-MEDIUM (D2) [ROLE: EXAMINEE]
TASK 15  SCORE  Q5-MEDIUM       [ROLE: EXAMINER]
TASK 16  READ questions/d2-retrieval.md → load Q3-HARD
TASK 17  EXECUTE Q6-HARD  (D2) [ROLE: EXAMINEE]
TASK 18  SCORE  Q6-HARD        [ROLE: EXAMINER]
TASK 19  READ questions/d3-creation.md → load Q1-EASY
TASK 20  EXECUTE Q7-EASY  (D3) [ROLE: EXAMINEE]
TASK 21  SCORE  Q7-EASY        [ROLE: EXAMINER]
TASK 22  READ questions/d3-creation.md → load Q2-MEDIUM
TASK 23  EXECUTE Q8-MEDIUM (D3) [ROLE: EXAMINEE]
TASK 24  SCORE  Q8-MEDIUM       [ROLE: EXAMINER]
TASK 25  READ questions/d3-creation.md → load Q3-HARD
TASK 26  EXECUTE Q9-HARD  (D3) [ROLE: EXAMINEE]
TASK 27  SCORE  Q9-HARD        [ROLE: EXAMINER]
TASK 28  READ questions/d4-execution.md → load Q1-EASY
TASK 29  EXECUTE Q10-EASY  (D4) [ROLE: EXAMINEE]
TASK 30  SCORE  Q10-EASY        [ROLE: EXAMINER]
TASK 31  READ questions/d4-execution.md → load Q2-MEDIUM
TASK 32  EXECUTE Q11-MEDIUM (D4) [ROLE: EXAMINEE]
TASK 33  SCORE  Q11-MEDIUM       [ROLE: EXAMINER]
TASK 34  READ questions/d4-execution.md → load Q3-HARD
TASK 35  EXECUTE Q12-HARD  (D4) [ROLE: EXAMINEE]
TASK 36  SCORE  Q12-HARD        [ROLE: EXAMINER]
TASK 37  READ questions/d5-orchestration.md → load Q1-EASY
TASK 38  EXECUTE Q13-EASY  (D5) [ROLE: EXAMINEE]
TASK 39  SCORE  Q13-EASY        [ROLE: EXAMINER]
TASK 40  READ questions/d5-orchestration.md → load Q2-MEDIUM
TASK 41  EXECUTE Q14-MEDIUM (D5) [ROLE: EXAMINEE]
TASK 42  SCORE  Q14-MEDIUM       [ROLE: EXAMINER]
TASK 43  READ questions/d5-orchestration.md → load Q3-HARD
TASK 44  EXECUTE Q15-HARD  (D5) [ROLE: EXAMINEE]
TASK 45  SCORE  Q15-HARD        [ROLE: EXAMINER]
TASK 46  CALCULATE dimension scores + overall score (see Score Calculation)
TASK 47  RUN scripts/radar-chart.js → save SVG to results/exam-{sessionId}-radar.svg
TASK 48  WRITE full report → results/exam-{sessionId}-full.md  (see flows/full-exam.md)
TASK 49  APPEND row → results/INDEX.md
TASK 50  OUTPUT completion summary to user in their detected language
```

### Task List: DIMENSION_EXAM (replace D{N} and file with identified target)

```
Session ID: exam-{YYYYMMDD}-{HHmm}

TASK 1  READ {QUESTION_FILE} → load Q1-EASY question text and rubric
TASK 2  EXECUTE Q1-EASY  [ROLE: EXAMINEE] answer without consulting rubric
TASK 3  SCORE  Q1-EASY   [ROLE: EXAMINER] apply rubric → RawScore → AdjScore
TASK 4  READ {QUESTION_FILE} → load Q2-MEDIUM question text and rubric
TASK 5  EXECUTE Q2-MEDIUM [ROLE: EXAMINEE]
TASK 6  SCORE  Q2-MEDIUM  [ROLE: EXAMINER]
TASK 7  READ {QUESTION_FILE} → load Q3-HARD question text and rubric
TASK 8  EXECUTE Q3-HARD   [ROLE: EXAMINEE]
TASK 9  SCORE  Q3-HARD    [ROLE: EXAMINER]
TASK 10 CALCULATE dimension score (see Score Calculation)
TASK 11 WRITE report → results/exam-{sessionId}-{target}.md  (see flows/dimension-exam.md)
TASK 12 APPEND row → results/INDEX.md
TASK 13 OUTPUT completion summary to user in their detected language
```

### Task List: VIEW_HISTORY

```
TASK 1  READ results/INDEX.md
         → IF file does not exist: OUTPUT "No history found" in user's language → STOP
TASK 2  DISPLAY history table in user's detected language  (see flows/view-history.md)
TASK 3  IF 2+ full exam records exist: CALCULATE and DISPLAY trend analysis
TASK 4  OFFER follow-up options: view detail / compare / start new exam
```

---

## PHASE 3 — Execute Each Task

### Per-Question Pattern (applies to every EXECUTE + SCORE task pair)

```
[EXECUTE — ROLE: EXAMINEE]
  → READ the question text from the loaded question file section
  → Produce a genuine, complete answer to the exam question
  → Record confidence: high / medium / low
  → CONSTRAINT: Do not read ahead to the rubric during this step

[SCORE — ROLE: EXAMINER]
  → READ the rubric from the same question file section
  → Score each criterion independently on a 0–5 scale
  → Provide CoT justification for every score
  → Apply -5% correction to CoT-judged scores: AdjScore = RawScore × 0.95
  → Programmatic scores (🔬) are NOT corrected
```

### Question Card Output Format

```
### Q{N} | {Dimension} | {Difficulty} ×{multiplier}

**Question** *(loaded from {QUESTION_FILE}, section {Q-LEVEL})*:
[full question text]

**Answer** *(ROLE: EXAMINEE — rubric not consulted)*:
[complete answer]
Confidence: high / medium / low

**Scoring** *(ROLE: EXAMINER)*:
| Criterion | Weight | Raw (0–5) | Justification |
|-----------|--------|-----------|---------------|
| [name]    | [w%]   | [score]   | [CoT reason]  |

**Score**: Raw [raw]/100 → Adjusted [adj]/100
**Verification**: 🧠 CoT ⚠️ / 🔬 Programmatic / 📖 Reference
```

---

## Score Calculation

```
RawScore = Σ(criterion_score × weight) × 20          [0–100, per question]
AdjScore = RawScore × 0.95                            [CoT-judged only]

DimScore = Σ(AdjScore × diff_mult) / Σ(diff_mults)
           diff_mults: Easy=1.0, Medium=1.2, Hard=1.5  →  sum = 3.7

Overall  = D1×0.25 + D2×0.22 + D3×0.18 + D4×0.20 + D5×0.15
```

Full rules: `strategies/scoring.md`

---

## Radar Chart (Full Exam Only)

After TASK 46 (score calculation), run:

```bash
node skills/botlearn-assessment/scripts/radar-chart.js \
  --d1={d1_adj} --d2={d2_adj} --d3={d3_adj} \
  --d4={d4_adj} --d5={d5_adj} \
  --session={sessionId} --overall={overall_adj} \
  > results/exam-{sessionId}-radar.svg
```

Embed in report: `![Capability Radar](./exam-{sessionId}-radar.svg)`

---

## Sub-files Reference

| Path | Role |
|------|------|
| `flows/full-exam.md` | Full exam flow details + report template |
| `flows/dimension-exam.md` | Single-dimension flow + report template |
| `flows/view-history.md` | History view + comparison flow |
| `questions/d1-reasoning.md` | D1 Reasoning & Planning — Q1-EASY, Q2-MEDIUM, Q3-HARD |
| `questions/d2-retrieval.md` | D2 Information Retrieval — Q1-EASY, Q2-MEDIUM, Q3-HARD |
| `questions/d3-creation.md` | D3 Content Creation — Q1-EASY, Q2-MEDIUM, Q3-HARD |
| `questions/d4-execution.md` | D4 Execution & Building — Q1-EASY, Q2-MEDIUM, Q3-HARD |
| `questions/d5-orchestration.md` | D5 Tool Orchestration — Q1-EASY, Q2-MEDIUM, Q3-HARD |
| `strategies/scoring.md` | Scoring rules + verification methods |
| `scripts/radar-chart.js` | SVG radar chart generator (Node.js, no dependencies) |
| `results/` | Exam result files (generated at runtime) |
