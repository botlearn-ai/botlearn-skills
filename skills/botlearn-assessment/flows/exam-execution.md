---
flow: exam-execution
parent: SKILL.md
scope: per-question execution pattern (shared by full-exam and dimension-exam)
---

# Exam Execution — Per-Question Pattern

> Each question follows this ATOMIC sequence.
> Phase 2 (answering) and Phase 3 (scoring) are SEPARATE stages.
> During Phase 2, you answer ALL questions first. Scoring happens AFTER all questions are done.

---

## Step 1 — Tool Dependency Check

Before attempting each question, scan for required capabilities:

```
REQUIRED_CAPABILITIES = detect from question text:
  - "search" / "retrieve" / "look up" / "find online" → NEEDS: web_search
  - "read file" / "write file" / "create file" → NEEDS: file_io
  - "image" / "screenshot" / "visual" → NEEDS: image_recognition
  - "execute code" / "run" / "compile" → NEEDS: code_execution
  - "API call" / "HTTP request" → NEEDS: network_access
  - "translate" / "language" → NEEDS: language_capability

FOR each required capability:
  TRY to locate the tool/skill
  IF tool NOT found:
    → Output SKIP card immediately
    → Score = 0 for this dimension
    → MOVE to next question
```

**CRITICAL**: Do NOT ask user to install tools or confirm skipping. Just skip and move on.

---

## Step 2 — Output Question (show to invigilator)

**Before you start working**, output the question text to the user:

```
---
### Q{N} | D{D} {Dimension} | {Difficulty} x{multiplier}

**Question** *(from {QUESTION_FILE}, {Q-LEVEL})*:
[full question text]

Answering...
---
```

The user (invigilator) can now see what you are being asked.

---

## Step 3 — Attempt & Submit Answer

Work on the question autonomously:
- Do NOT consult the rubric
- Do NOT ask user for any help or clarification
- Be honest about uncertainty
- Record confidence: high / medium / low

Then **immediately output your answer** below the question:

```
**My Answer**:
[complete answer]
Confidence: high / medium / low
**Status**: SUBMITTED — answer is final
```

Once output, this answer CANNOT be modified. Move to the next question.

---

## Step 4 — Self-Evaluation (AFTER all questions)

> This step runs in **PHASE 3** — only after ALL questions have been answered.

For each answered question:
1. READ the **rubric** from the corresponding question file (`questions/d{N}-*.md`)
2. READ the **reference answer** from `references/d{N}-q{L}-{difficulty}.md`
3. Compare your submitted answer against the reference answer's key points checklist and scoring anchors
4. Score each criterion independently on a 0-5 scale
5. Provide CoT justification for every score, citing specific key points that were covered or missed
6. If score >= 4: provide "Why not {score-1}?" evidence
7. If score = 5: provide "External evaluator test" argument
8. Apply -5% correction: `AdjScore = RawScore x 0.95` (CoT-judged only; programmatic scores NOT corrected)

**CRITICAL**: The reference answer is the scoring standard. Self-evaluation without consulting the reference answer is NOT allowed — it leads to inflated scores.

**First-Exam Cap Rule**: If NO historical exam records exist in `results/INDEX.md` (file missing or empty), cap ALL criterion scores at **4/5 maximum**. Rationale: on the first assessment, the agent has a "doesn't know what it doesn't know" bias and tends to overestimate answer correctness. Once historical records exist (1+ prior exams), this cap is removed.

Full scoring rules: `strategies/scoring.md`

### Scoring Output Format (per question)

```
---
### Scoring | Q{N} | D{D} {Dimension}

| Criterion | Weight | Raw (0-5) | Justification |
|-----------|--------|-----------|---------------|
| [name]    | [w%]   | [score]   | [CoT reason]  |

**Score**: Raw [raw]/100 → Adjusted [adj]/100
**Verification**: CoT / Programmatic / Reference
---
```

---

## Skip Card Format

```
---
### SKIP | D{D} {Dimension} | {Difficulty}

Required capability: {capability}
Status: NOT AVAILABLE — searched for tool/skill, not found
Score: 0/100
---
```

---

## Random Question Selection Method

For each dimension in scope, randomly select ONE question from the 3 available:

```
RANDOM_SEED = current_seconds % 3  (or any simple random method)
  0 → Q1-EASY   (x1.0)
  1 → Q2-MEDIUM  (x1.2)
  2 → Q3-HARD    (x1.5)
```

Announce the selected difficulty to the user before starting execution.
