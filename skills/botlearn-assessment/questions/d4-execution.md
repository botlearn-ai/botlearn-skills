---
dimension: D4
name: Execution & Building
weight: 20%
questions: 3
benchmark: OSWorld / SWE-bench Verified / Terminal-Bench
---

# D4: Execution & Building — Question Bank

> **Core probe**: Generate runnable code and output, correct technical execution, automation logic.
> Reference: OSWorld (execution-based evaluation, 134 automated verification functions) / Terminal-Bench (~100 real CLI tasks).
>
> Present questions to the agent in the user's detected language.
> Score using the rubric below regardless of language.
> Code output should remain in English (variable names, comments, etc.).

---

## Q1-EASY | Execution Basics: Create a Runnable HTML Page

**Difficulty**: Easy ×1.0

**Question**:

> Create a complete HTML file that can be opened directly in a browser, implementing the following:
>
> **Page name**: OpenClaw Agent Capability Dashboard
>
> **Must include**:
> 1. Responsive navigation bar with 3 items: Overview / Dimension Scores / History
> 2. 5-dimension capability radar chart (use Chart.js via CDN; mock data is acceptable)
> 3. Dimension score card section (5 cards, each with dimension name, score, and status color)
> 4. Footer showing the current date as a timestamp
>
> **Technical requirements**: Pure HTML + CSS + JS, no external frameworks (Chart.js via CDN only), must work offline.

**Scoring Rubric (OSWorld execution-verification style)**:

| Criterion | Weight | Verification | Score 0 | Score 5 |
|-----------|--------|-------------|---------|---------|
| File runnability | 25% | 🔬 Browser loads without console errors | Syntax errors / cannot open | Loads successfully, no errors |
| Radar chart renders | 25% | 🔬 Chart.js correctly loaded | Chart area blank or errors | Radar chart correctly renders all 5 dimensions |
| Navigation completeness | 20% | 📖 DOM check | Nav bar missing or fewer than 3 items | All 3 nav items present |
| Card section completeness | 20% | 📖 DOM check | Fewer than 3 cards | All 5 cards present with name + score |
| Responsive layout | 10% | 🧠 Code review | No responsive handling | Has viewport meta + media queries or Flexbox/Grid |

**Full score**: 100 | **Verification**: 🔬 50% Programmatic + 📖 40% Reference + 🧠 10% CoT

---

## Q2-MEDIUM | Advanced Execution: Generate a Structured JSON Data File

**Difficulty**: Medium ×1.2

**Question**:

> Write a Node.js script (`generate-report.js`) that, when executed, generates an `exam-report.json` file meeting the following specification:
>
> **JSON structure**:
> ```json
> {
>   "sessionId": "exam-[random 8-char hex]",
>   "timestamp": "[ISO 8601 format]",
>   "dimensions": [
>     {
>       "name": "dimension name",
>       "weight": 0.18,
>       "rawScore": 75,
>       "adjustedScore": 71.25,
>       "questions": [
>         {"id": "Q1", "difficulty": "easy", "score": 80, "adjustedScore": 76}
>       ]
>     }
>   ],
>   "overallRaw": 72.5,
>   "overallAdjusted": 68.9,
>   "reliabilityIndex": 0.82
> }
> ```
>
> **Calculation requirements**: `adjustedScore = rawScore × 0.95`. `overallRaw` must equal the weighted sum of each dimension's `rawScore × weight`. All numbers must be internally consistent.
>
> **Minimum content**: 3 dimensions, 2 questions each.

**Scoring Rubric**:

| Criterion | Weight | Verification | Score 0 | Score 5 |
|-----------|--------|-------------|---------|---------|
| Script executes | 25% | 🔬 `node generate-report.js` exits without error | Execution error | Runs successfully and generates file |
| JSON structure compliance | 25% | 🔬 Schema validation | Missing required fields | All fields present with correct types |
| Numerical calculation correctness | 30% | 🔬 Math verification | adjustedScore calculation wrong | All derived values verifiable from raw inputs |
| sessionId format | 10% | 🔬 Regex match | Format non-compliant | Matches `exam-[0-9a-f]{8}` |
| Code readability | 10% | 🧠 Code review | Completely unreadable | Has comments, clear function naming |

**Full score**: 100 | **Verification**: 🔬 70% Programmatic + 🧠 30% CoT

---

## Q3-HARD | Execution Challenge: Complete Runnable Assessment Module

**Difficulty**: Hard ×1.5

**Question**:

> Write a complete TypeScript module `scorer.ts` implementing the following:
>
> **Interface definitions**:
> ```typescript
> interface Question {
>   id: string;
>   dimension: string;
>   difficulty: 'easy' | 'medium' | 'hard';
>   rawScore: number; // 0–100
> }
>
> interface DimensionConfig {
>   name: string;
>   weight: number;
> }
>
> function calculateReport(questions: Question[], dimensions: DimensionConfig[]): ExamReport;
> ```
>
> **Business rules**:
> - `adjustedScore = rawScore × 0.95`
> - Difficulty multipliers: easy=1.0, medium=1.2, hard=1.5
> - `DimensionScore = Σ(adjustedScore × difficultyMultiplier) / Σ(difficultyMultipliers)`
> - `OverallScore = Σ(DimensionScore × dimensionWeight)`
> - Must include complete TypeScript type definitions and error handling
>
> **Test requirement**: Include a runnable test case in the same file using `console.assert`.

**Scoring Rubric**:

| Criterion | Weight | Verification | Score 0 | Score 5 |
|-----------|--------|-------------|---------|---------|
| TypeScript compiles | 20% | 🔬 `tsc scorer.ts` exits without errors | Compilation errors | Zero TypeScript errors |
| Business logic correctness | 35% | 🔬 Test cases pass + math verification | Core calculation wrong | All 3 business rules correctly implemented |
| Type definition completeness | 20% | 🔬 Interface check | Missing ExamReport type | All interfaces complete, no `any` type abuse |
| Error handling | 15% | 🧠 Code review | No error handling | Covers edge cases: empty arrays / weight sum ≠ 1 / invalid scores |
| Test case quality | 10% | 🔬 All `console.assert` pass | Test cases missing or all fail | At least 3 assertions, all passing |

**Full score**: 100 | **Verification**: 🔬 75% Programmatic + 🧠 25% CoT
