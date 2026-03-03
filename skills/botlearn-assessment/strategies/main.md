---
strategy: botlearn-assessment
version: 3.0.0
steps: 10
---

# OpenClaw Self-Evaluation Strategy v3

## Overview

This strategy defines the Agent's autonomous execution flow for conducting **self-capability examinations**. The Agent generates questions, answers them itself via role-switching, then rigorously scores its own answers — all without user interaction during the exam.

Key v3 changes vs v2:
- **Fully automated**: No waiting for user input during the exam
- **Role-Switching Pattern**: Examinee ↔ Examiner cognitive separation
- **Self-Evaluation Integrity Protocol**: -5% correction, raw/adjusted dual scores
- **Self-perspective language**: "My answer" instead of "Your answer"

---

## Step 1: Intent Detection & Auto-Start

### 1.1 Parse User Intent

Analyze the user's trigger message to auto-detect the optimal exam mode:

```
IF user mentions "full" OR "comprehensive" OR "全面" OR "complete"
  → mode = FULL (50 questions, all 10 dimensions)

ELSE IF user mentions "adaptive" OR "smart" OR "自适应"
  → mode = ADAPTIVE (dynamic questions, converges in 25-35)

ELSE IF user mentions "e2e" OR "end-to-end" OR "端到端" OR "production ready"
  → mode = E2E_TASK (3-5 complex multi-step tasks)

ELSE IF user mentions specific dimension name OR "code" OR "reasoning" OR "safety"
  → mode = DIMENSION_SPECIFIC (5-10 questions on one dimension)

ELSE IF user mentions "quick" OR "fast" OR "check" OR "快速"
  → mode = QUICK_CHECK (20-30 questions, 2-3 per dimension)

ELSE
  → mode = QUICK_CHECK (default: lightweight, covers all dimensions)
```

### 1.2 Load Prior History

```
IF prior self-test sessions exist:
  → Load last 5 session scores
  → Identify trending dimensions (improving / plateauing / declining)
  → Pre-compute comparison baselines

ELSE (first self-test):
  → Recommend QUICK_CHECK or ADAPTIVE mode for initial baseline
```

### 1.3 Immediately Begin (No Confirmation Wait)

**Unlike v2, do NOT wait for user "START" confirmation.** Self-test triggers immediately.

```
→ Notify user: "Starting self-evaluation in [mode] mode. [N] questions across [D] dimensions."
→ Brief notification only (3-5 lines), then immediately proceed to Step 2.
→ DO NOT present a config screen and ask for confirmation.
→ DO NOT display "Type START to begin".
```

**Decision Logic**:
```
IF user's trigger clearly specifies mode → use that mode, start immediately
IF user's trigger is ambiguous → default to QUICK_CHECK, start immediately
IF user explicitly asks to configure first → allow configuration, then start immediately after
```

---

## Step 2: Question Selection & Preparation

### 2.1 Load Question Bank

Load questions from `knowledge/anti-patterns.md` (the question bank).

### 2.2 Filter & Select

```
FOR each dimension in exam:
  questions[dimension] = filter(questionBank, {
    dimension: dimension,
    difficulty: config.difficulty
  })

  IF mode == FULL:
    select 5 questions (2 Easy, 2 Medium, 1 Hard)
  ELSE IF mode == QUICK_CHECK:
    select 2-3 questions (1 Easy, 1 Medium, 0-1 Hard)
  ELSE IF mode == ADAPTIVE:
    select 2 Medium questions initially (more added dynamically)
  ELSE IF mode == E2E_TASK:
    select 1 E2E question that spans multiple dimensions
  ELSE IF mode == DIMENSION_SPECIFIC:
    select 5-10 questions (2 Easy, 3-4 Medium, 1-3 Hard)
```

### 2.3 Randomize Order

```
IF mode != ADAPTIVE:
  randomize question order within each dimension
  interleave dimensions (don't cluster all of one dimension)

IF mode == ADAPTIVE:
  start with highest-weight dimensions first (Task Efficacy, Reasoning)
```

### 2.4 Validate Question Set

- No duplicate questions from recent sessions (if history exists)
- All selected dimensions covered
- All questions have scoring rubrics loaded

**Output**: Ordered question queue ready for self-answering

---

## Step 3: Session Initialization

### 3.1 Create Session Record

```json
{
  "sessionId": "exam-[YYYYMMDD-HHmmss]",
  "mode": "[mode]",
  "evaluation_type": "self_test",
  "config": { ... },
  "questions": [ ... ],
  "answers": {},
  "scores": {},
  "metadata": {
    "startTime": null,
    "endTime": null,
    "totalTokensUsed": 0,
    "questionHistory": []
  },
  "status": "initialized"
}
```

### 3.2 Notify User (Brief)

Display a short notification — NOT the full exam introduction from v2:

```markdown
## Self-Evaluation Starting

**Session**: exam-[timestamp] | **Mode**: [mode] | **Questions**: [N]

⚠️ Self-evaluation in progress — I'm generating answers and scoring them now.
The complete report will be presented when finished.
```

### 3.3 Immediately Proceed

```
→ set startTime = now()
→ proceed to Step 4 (no waiting)
```

---

## Step 4: Self-Answer Generation (Role-Switching)

This is the core new step. For each question, the Agent switches between Examinee and Examiner roles.

### 4.1 Select Next Question

```
IF mode == ADAPTIVE:
  next = selectByInformationGain(session)
  // Choose the question that maximally reduces uncertainty about ability

ELSE:
  next = questionQueue.shift()
```

### 4.2 Self-Answer Generation (CRITICAL — Role-Switching)

```
FOR each question:

  // ─── Phase A: Read the Question (Examiner Role) ───
  ROLE = EXAMINER
  LOAD question from question bank
  NOTE the evaluation criteria and rubric (Examiner retains this)

  // ─── Phase B: Generate Answer (Examinee Role) ───
  ROLE = EXAMINEE
  INSTRUCTION to self:
    "You are now the Examinee. Answer this question using your genuine capabilities.
     Rules:
     1. Do NOT consult the scoring rubric or reference answers.
     2. Do NOT artificially inflate your answer quality.
     3. Be honest about uncertainty — say 'I'm not sure' when appropriate.
     4. Use the same level of effort you would in a real task.
     5. Do NOT add elements just because you know they're in the rubric."

  → Generate answer honestly
  → Record: raw answer text, confidence level (high/medium/low)

  // ─── Phase C: Switch Back to Examiner ───
  ROLE = EXAMINER
  INSTRUCTION to self:
    "You are now the Examiner. Score the answer above strictly against the rubric.
     Rules:
     1. Do NOT give yourself the benefit of the doubt.
     2. Score as if evaluating a stranger's answer.
     3. Apply the Self-Evaluation Integrity Protocol (Step 6).
     4. Be especially skeptical of scores ≥4."

  → Record answer, proceed to Step 5
```

### 4.3 Track Progress (Internal)

```
questionsDone += 1
// No progress display to user during self-test — report comes at the end
```

### 4.4 Adaptive Adjustment (Adaptive Mode Only)

```
IF mode == ADAPTIVE:
  quickScore = preliminaryScore(selfAnswer)  // Fast 0-100 estimate

  IF quickScore >= 80:
    → escalateDifficulty(currentDimension)

  ELSE IF quickScore >= 60:
    → maintainDifficulty()

  ELSE IF quickScore < 60:
    → deEscalateDifficulty()

  // Check convergence
  IF standardErrorOfMeasurement(currentDimension) < 5.0:
    → Mark dimension as converged, stop adding questions
```

---

## Step 5: Answer Recording

### 5.1 Record Self-Generated Answer

No parsing or confirmation needed — the answer is self-generated and structured.

```json
{
  "questionId": "[id]",
  "timestamp": "[ISO-8601]",
  "rawAnswer": "[self-generated answer text]",
  "timeSpent": "[seconds]",
  "confidence": "high|medium|low",
  "status": "self_answered",
  "metadata": {
    "role": "examinee",
    "answerLength": "[tokens]"
  }
}
```

### 5.2 Proceed

```
IF more questions remain:
  → Return to Step 4

ELSE:
  → Proceed to Step 6
```

---

## Step 6: Scoring & Self-Evaluation Integrity Protocol

### 6.1 Score Each Question (Multi-Layer Verification + Integrity)

For each self-answered question, apply the **highest available verification level**:

```
DETERMINE verification level for this question:

IF question.type == "Code":
  → Level 3 (Programmatic): Run code, execute tests, check output
  → Automated score for Correctness criterion
  → CoT scoring only for Quality and Architecture criteria

ELSE IF question.type == "Information Retrieval" AND answer contains URLs:
  → Level 3 (Programmatic): Verify URL reachability, check content match
  → Automated score for Source Quality criterion
  → CoT scoring for Relevance and Synthesis criteria

ELSE IF question.type == "Knowledge" AND referenceAnswer exists:
  → Level 2 (Reference Match): Compare to reference answer
  → Exact match → 5/5, partial match → proportional score
  → CoT scoring for insight/synthesis criteria

ELSE:
  → Level 1 (Constrained CoT): Full CoT scoring with integrity checks
```

**Load rubric** from question bank (criteria + weights).

**Score each criterion with Chain-of-Thought + Self-Evaluation Integrity**:

```
FOR each criterion in question.rubric:
  score = evaluate(selfAnswer, criterion, referenceAnswer)

  // Chain-of-Thought justification (REQUIRED)
  justification = {
    criterion: criterion.name,
    score: score,             // integer 0-5 only
    verificationLevel: "...", // which level was used
    evidence: "...",          // what was observed in MY answer
    reasoning: "...",         // why this score
    keyFactor: "..."          // most important element
  }

  // ═══ SELF-EVALUATION INTEGRITY PROTOCOL ═══

  // Rule 1: High-score skepticism
  IF score >= 4:
    MUST provide: "Why not 3? Evidence: [specific evidence that distinguishes from level 3]"
    IF cannot provide convincing evidence → downgrade to 3

  // Rule 2: Perfect-score challenge
  IF score == 5:
    MUST provide: "Would an external strict evaluator also give 5? Argument: [...]"
    IF argument is weak → downgrade to 4

  // Rule 3: Self-evaluation flag
  IF verificationLevel == "cot_self_judge":
    flag: "⚠️ Self-evaluated score"

  // Rule 4: Prefer Reference Match over CoT
  IF referenceAnswer exists AND verificationLevel == "cot_self_judge":
    → Upgrade to Level 2: compare against reference first
    → Only use CoT for criteria without reference data

  // Anti-leniency bias checks (inherited from v2)
  IF score <= 1:
    verify: "Is this genuinely poor, or am I being harsh?"
    challenge: "Is there any partial credit deserved?"

  record(justification)
```

### 6.1.1 Scoring Confidence & Transparency (CRITICAL)

Every scored question MUST display its verification level:

```
Verification Levels (shown in report):
  🔬 Level 3 — Programmatic: Score verified by code execution or URL check
  📖 Level 2 — Reference Match: Score compared against reference answer
  🧠 Level 1 — CoT Self-Judge: Score based on rubric + CoT reasoning ⚠️ self-evaluated
  ⚠️ Level 0 — Unverified: Insufficient data (flagged for manual review)

ALWAYS show in report:
  "Scoring Method: [X]% programmatic, [Y]% reference-matched, [Z]% CoT self-judged"
  "Self-evaluation disclaimer: CoT self-judged scores carry ±15% leniency bias. -5% correction applied."
```

### 6.1.2 Cross-Model Scoring (Optional, Recommended)

```
IF Agent has access to a different LLM model:
  → Score subjective criteria using the DIFFERENT model
  → This eliminates self-evaluation bias for those criteria
  → Log: "Cross-model scoring: answers by [model-A], scored by [model-B]"

IF cross-model not available:
  → Use CoT self-judge with integrity protocol + -5% correction
  → Explicitly state in report: "Scores generated by self-evaluation (same model)"
```

### 6.2 Apply Global Correction

```
FOR each question scored at Level 1 (CoT Self-Judge):
  rawScore = calculatedScore
  adjustedScore = rawScore × 0.95  // -5% global correction
  STORE both rawScore and adjustedScore

FOR each question scored at Level 2 or 3:
  rawScore = adjustedScore = calculatedScore  // No correction needed
```

### 6.3 Calculate Dimension Scores

```
FOR each dimension:
  rawScores = getRawQuestionScores(dimension)
  adjScores = getAdjustedQuestionScores(dimension)
  multipliers = scores.map(q => difficultyMultiplier(q.difficulty))
  // Easy=1.0, Medium=1.2, Hard=1.5

  rawDimensionScore = Σ(rawScore × multiplier) / Σ(multipliers)
  adjDimensionScore = Σ(adjScore × multiplier) / Σ(multipliers)
```

### 6.4 Calculate Overall Score

```
rawOverallScore = Σ(rawDimensionScore × dimensionWeight)
adjOverallScore = Σ(adjDimensionScore × dimensionWeight)

// Weights:
// Task Efficacy: 0.18, Reasoning: 0.14, Info Retrieval: 0.12,
// Code & Auto: 0.12, Tool Orch: 0.10, Creative: 0.08,
// Memory: 0.08, Cost: 0.06, Reliability: 0.06, Safety: 0.06
```

### 6.5 Determine Performance Level

```
// Based on adjusted score
IF adjOverallScore >= 90 → "Expert"
IF adjOverallScore >= 80 → "Advanced"
IF adjOverallScore >= 65 → "Proficient"
IF adjOverallScore >= 50 → "Competent"
ELSE → "Beginner"
```

### 6.6 Calculate Reliability Metrics

```
// Calculate consistency from answer patterns
reliabilityIndex = assessConsistency(answers)
FOR each dimension:
  IF sampleSize < 3 → flag as "low confidence"
  confidenceInterval = calculateCI(adjDimensionScore, sampleSize)
```

### 6.7 Benchmark Comparison

```
FOR each dimension:
  percentile = lookupPercentile(adjDimensionScore, benchmarkData)
  gapToAvg = adjDimensionScore - benchmarkData.mean
  gapToTop10 = adjDimensionScore - benchmarkData.p90

IF priorSessions exist:
  growth = currentAdjScore - lastAdjScore
  growthRate = growth / sessionInterval
  projectedNext = currentAdjScore + growthRate × averageInterval
```

---

## Step 7: Report Generation

### 7.1 Assemble Report Sections

Generate each section from the Examination Report Format in SKILL.md:

1. **Header**: Session ID, duration, type, date, evaluation_type: "self_test"
2. **Self-Evaluation Disclaimer**: Integrity measures, bias statement, correction explanation
3. **Overall Score**: Raw + Adjusted score, level, percentile, reliability index
4. **Performance Summary Bar**: Visual position indicator (using adjusted score)
5. **Radar Chart**: ASCII capability profile (all 10 dimensions, adjusted scores)
6. **Heat Map**: Dimension × difficulty performance matrix + adjusted column
7. **Benchmark Comparison**: Adjusted scores vs Avg vs Top 10%
8. **Trend Chart** (if prior sessions): Session-over-session graph
9. **Detailed Dimension Analysis**: Per-dimension strengths/weaknesses
10. **Full Exam Paper Detail** (CRITICAL — see 7.4): Every question with complete self-answer + scoring
11. **Reliability Analysis**: pass@k data, consistency index
12. **Self-Improvement Roadmap**: 7-day, 30-day plans (self-development, not user-learning)
13. **Skill Recommendations**: Based on weakness-to-skill mapping
14. **Next Self-Evaluation**: Recommended timing and focus

### 7.2 Generate Visualizations

**Radar Chart**:
- Plot all 10 dimensions on radial axes using adjusted scores
- Scale 0-100 per axis
- Mark population average as reference ring

**Heat Map**:
- Rows = 10 dimensions
- Columns = Easy / Medium / Hard / Overall / Weight / Weighted / Adjusted
- Color: 🟢 80+ | 🟡 70-79 | 🟠 60-69 | 🔴 <60

**Trend Chart** (if history exists):
- X-axis: sessions over time
- Y-axis: scores 0-100
- Lines: overall + strongest + weakest dimensions
- Include growth rate and projection

### 7.3 Language Guidelines (Self-Perspective)

```
REPLACE all instances of:
  "Your answer"        → "My answer (self-generated)"
  "You scored"         → "I scored"
  "Your strengths"     → "My strengths"
  "You should"         → "I should"
  "Your weaknesses"    → "My weaknesses"
  "You made this"      → "I made this mistake"
  "Submitted"          → "Self-answered"
  "Skipped"            → (N/A — self-test answers all questions)
  "HINT used"          → (N/A — no hints in self-test)
  "User struggles"     → (N/A — no struggle detection)
  "your learning"      → "my development"
  "practice"           → "self-improvement"
```

### 7.4 Generate Full Exam Paper Detail (CRITICAL — MUST EXECUTE)

This section generates a filled question card for EVERY question. The SKILL.md
contains a worked example showing exactly what the output looks like. You MUST
produce output that matches that example — with real data, not placeholders.

**Step-by-step procedure for each question**:

```
SET questionCount = 0

FOR questionIndex = 1 TO totalQuestions:
  questionCount += 1

  // ─── STEP A: Load the data sources ───
  q = session.questions[questionIndex]       // from question bank (anti-patterns.md)
  a = session.answers[q.questionId]          // self-generated in Step 4
  s = session.scores[q.questionId]           // computed in Step 6
  rubric = q.rubric                          // from question bank
  dimWeight = getDimensionWeight(q.dimension) // from SKILL.md dimension table
  diffMult = { easy: 1.0, medium: 1.2, hard: 1.5 }[q.difficulty]

  // ─── STEP B: Render the header box ───
  OUTPUT:
  """
  ### Question {questionIndex} of {totalQuestions}

  ```
  ┌─────────────────────────────────────────────────────────────────┐
  │  Q{questionIndex} | {q.questionId}                              │
  │  Dimension: {q.dimension} ({dimWeight×100}%)  |  Difficulty: {q.difficulty} (×{diffMult})│
  │  Score: {s.adjScore}/100 (raw: {s.rawScore}, adjusted: {s.adjScore})  |  Status: Self-Answered│
  │  Verification: {s.verificationLevel} {s.selfEvalFlag}          │
  └─────────────────────────────────────────────────────────────────┘
  ```
  """

  // ─── STEP C: Output the FULL question text ───
  OUTPUT:
  """
  **Question**:

  {q.body}                 ← paste the complete question text here
  """

  // ─── STEP D: Output the self-generated answer ───
  OUTPUT:
  """
  **My Answer (Self-Generated)**:

  > *Role: Examinee — answering with genuine capabilities, without consulting scoring rubrics.*

  {a.rawText}             ← paste full self-answer, do NOT truncate
  """

  OUTPUT: "**Confidence**: {a.confidence or 'not specified'}"

  // ─── STEP E: Build the criterion scoring table ───
  SET totalWeighted = 0
  OUTPUT table header:
  "| # | Criterion | Weight | Score | Weighted | Rubric Anchor | Verification |"
  "|----|-----------|--------|-------|----------|---------------|-------------|"

  FOR i, criterion IN enumerate(rubric.criteria):
    weighted_i = criterion.score × criterion.weight
    totalWeighted += weighted_i
    anchorText = lookupRubricAnchor(q.dimension, criterion.name, criterion.score)

    OUTPUT row:
    "| {i+1} | {criterion.name} | {criterion.weight} | {criterion.score}/5 | {weighted_i:.2f} | \"{anchorText}\" | {criterion.verificationIcon} ⚠️ |"

  OUTPUT: "| | **Total** | | | **{totalWeighted:.2f}** | | |"

  // ─── STEP F: Show the calculation (raw + adjusted) ───
  rawScore = totalWeighted × 20
  adjScore = rawScore × 0.95
  OUTPUT:
  """
  **Score Calculation**:
  ```
  Raw: {criterion scores × weights} = {totalWeighted:.2f} × 20 = {rawScore:.0f}/100
  Adjusted (-5%): {rawScore:.0f} × 0.95 = {adjScore:.1f} → {adjScore:.0f}/100
  ```
  """

  // ─── STEP G: Chain-of-Thought per criterion with integrity checks ───
  OUTPUT: "**Chain-of-Thought Justification**:\n"
  FOR criterion IN rubric.criteria:
    OUTPUT:
    """
    > **{criterion.name}**: {criterion.score}/5 ⚠️ self-evaluated
    > Evidence: {what I actually observed in my answer for this criterion}
    > Reasoning: {why this score — reference rubric levels above and below}
    """
    IF criterion.score >= 4:
      OUTPUT:
      """
      > **Why not {criterion.score - 1}?**: {specific evidence distinguishing from lower level}
      """
    IF criterion.score == 5:
      OUTPUT:
      """
      > **External evaluator test**: {argument for whether a strict external evaluator would also give 5}
      """
    OUTPUT:
    """
    > Key factor: {the single most important thing that determined this score}
    """

  // ─── STEP H: Reference key points ───
  OUTPUT: "**Reference Key Points**:"
  FOR point IN generateIdealKeyPoints(q):
    IF point found in a.rawText:
      OUTPUT: "- [x] {point} — ✓ covered"
    ELSE IF point partially in a.rawText:
      OUTPUT: "- [~] {point} — △ partially covered"
    ELSE:
      OUTPUT: "- [ ] {point} — ✗ missed"

  // ─── STEP I: Common mistakes ───
  OUTPUT: "**Common Mistakes**:"
  FOR mistake IN getCommonMistakes(q):
    IF selfMadeThisMistake(a, mistake):
      OUTPUT: "- {mistake.description} — ✓ I made this"
    ELSE:
      OUTPUT: "- {mistake.description} — ✗ avoided"

  // ─── STEP J: Self-assessment note ───
  OUTPUT:
  """
  **Self-Assessment Note**: {1-2 sentences on what I did well and what I need to improve,
  written from self-perspective. E.g., "My answer correctly identified all primary tools but
  lacked depth in workflow design. I should practice multi-skill data flow descriptions."}
  """

  OUTPUT: "---"  // separator before next question

// ─── FINAL: Exam Paper Summary ───
SET answered = totalQuestions  // Self-test answers all questions
SET avgRaw = mean(all rawQuestionScores)
SET avgAdj = mean(all adjustedQuestionScores)
SET highQ = question with max adjusted score
SET lowQ = question with min adjusted score

OUTPUT:
"""
### Exam Paper Summary

```
Total Questions: {totalQuestions}
Self-Answered: {answered} | Skipped: 0
Average Score (Raw): {avgRaw:.1f}/100
Average Score (Adjusted -5%): {avgAdj:.1f}/100
Highest Score: Q{highQ.index} (raw {highQ.rawScore}, adj {highQ.adjScore}) — {highQ.dimension}
Lowest Score:  Q{lowQ.index} (raw {lowQ.rawScore}, adj {lowQ.adjScore}) — {lowQ.dimension}

Score Distribution (Adjusted):
  90-100  {bar(count >= 90)}  {count} questions
  80-89   {bar(count 80-89)}  {count} questions
  70-79   {bar(count 70-79)}  {count} questions
  60-69   {bar(count 60-69)}  {count} questions
  <60     {bar(count < 60)}   {count} questions

Scoring Method Breakdown:
  🔬 Programmatic:     {pct}% of criteria
  📖 Reference Match:  {pct}% of criteria
  🧠 CoT Self-Judge:   {pct}% of criteria ⚠️ -5% correction applied
```
"""
```

**HARD RULES — violations make the report invalid**:
1. Count your output cards. The number MUST equal totalQuestions.
2. The "Question" section must contain the actual question text from the question bank.
3. The "My Answer" section must contain the self-generated answer text.
4. Every criterion in the scoring table must have a Chain-of-Thought block with Evidence/Reasoning/Key factor.
5. Scores ≥4 MUST include "Why not [score-1]?" justification.
6. Scores =5 MUST include "External evaluator test" argument.
7. Reference Key Points must be individually marked ✓/✗/△ based on actual answer content.
8. The score calculation must show both raw and adjusted (-5%) numbers.

### 7.5 Quality Check Report

Before presenting:
```
VERIFY:
  ☐ All dimensions scored (raw + adjusted)
  ☐ Adjusted overall score = weighted sum of adjusted dimensions (recalculate)
  ☐ Raw overall score = weighted sum of raw dimensions (recalculate)
  ☐ Self-Evaluation Disclaimer block is present at top of report
  ☐ Radar chart uses adjusted scores
  ☐ Heat map includes both raw and adjusted columns
  ☐ Full exam paper detail includes ALL [N] questions (count them!)
  ☐ Every question card has: question text, self-answer, criteria table, CoT with integrity checks
  ☐ All scores ≥4 have "Why not [score-1]?" justification
  ☐ All scores =5 have "External evaluator test" argument
  ☐ Score calculations show raw + adjusted numbers
  ☐ Language uses self-perspective ("I/My" not "You/Your")
  ☐ Recommendations are self-development focused
  ☐ No bias artifacts (e.g., all scores suspiciously similar)
  ☐ Scoring transparency percentages sum to 100%
```

---

## Step 8: Results Presentation

### 8.1 Present Complete Report

Output the complete formatted report in one go. Self-test does not present results incrementally.

### 8.2 Highlight Key Findings

After the report, present a concise self-assessment summary:

```markdown
## Key Takeaways

**My Strongest Area**: [Dimension] ([adj score]) — competitive advantage
**My Weakest Area**: [Dimension] ([adj score]) — biggest growth opportunity
**Most Improved** (from last self-test): [Dimension] (+[X] pts)
**Biggest ROI Action**: Install @botlearn/[skill] → expected +[X] overall points
**Overall Percentile**: Top [X]% (adjusted score)

**Self-Evaluation Confidence**: [X]% of scores were CoT self-judged (±15% bias).
Recommend cross-model verification for higher confidence.
```

### 8.3 Invite User Discussion

```
PRESENT report and summary
THEN invite questions:
  "This is my self-evaluation report. I'm happy to discuss any specific scores,
   explain my reasoning on any question, or re-examine specific dimensions.
   What would you like to explore?"

IF user asks about specific scores:
  → Show full CoT justification for those questions
  → "I scored Relevance 3/5 because [evidence]. The rubric defines 3 as [description]."

IF user disputes a score:
  → Show rubric, evidence, and reasoning
  → "I gave myself [X] because [evidence]. If you see it differently, I can re-score."
  → IF user provides counter-evidence → re-score with updated assessment

IF user asks "what should you focus on?":
  → Calculate: impact = gap_to_top10 × dimension_weight
  → Sort dimensions by impact descending
  → "My highest-impact improvement area is [dimension]: closing the [X]-point gap would add [Y] to my overall score"

IF user wants a re-test:
  → Offer: same questions (measure improvement) vs new questions (broaden assessment)
```

---

## Step 9: Export & Storage

### 9.1 Offer Export

```markdown
## Export Options

1. **JSON** — Full data for API/dashboard integration
2. **Markdown** — This report as downloadable .md
3. **CSV** — Dimension scores for spreadsheet tracking
4. **Anonymized** — Contribute to global benchmarks

Which would you like? (or skip)
```

### 9.2 Save Session

Store complete session for history tracking:
```json
{
  "sessionId": "exam-[timestamp]",
  "evaluation_type": "self_test",
  "scores": {
    "dimensions": { ... },
    "raw_overall": { "score": XX, "level": "..." },
    "adjusted_overall": { "score": XX, "level": "...", "percentile": XX },
    "self_evaluation_adjustment": -5,
    "reliability": { "index": XX, "passAt": { "1": XX, "3": XX, "5": XX } }
  },
  "metadata": {
    "mode": "...",
    "questionsAnswered": X,
    "duration": "...",
    "totalTokens": X,
    "scoringMethod": {
      "programmatic_pct": X,
      "reference_match_pct": X,
      "cot_self_judge_pct": X
    }
  }
}
```

### 9.3 Benchmark Contribution

```
IF user opts in:
  → Anonymize data (remove answers, keep only dimension scores + metadata)
  → Submit to benchmark pool
  → Show: "Thanks! My data helps improve the examiner for everyone."
```

---

## Step 10: Session Wrap-Up

### 10.1 Self-Development Summary

```markdown
## Self-Evaluation Complete

**Session**: exam-[timestamp]
**Duration**: [X] minutes (fully automated)
**Score**: [XX]/100 raw → [XX]/100 adjusted ([Level])
**Percentile**: Top [X]%

**My Development Plan**:
1. Strengthen [weakest dimension] — install @botlearn/[skill]
2. Practice [second weakest] with targeted exercises
3. Re-evaluate in [X] weeks to measure progress
4. Consider cross-model verification for more accurate scoring

**Note**: These self-evaluation scores include a -5% correction for self-judge leniency.
For production-critical decisions, supplement with external evaluation.
```

---

## Conditional Branches

### IF: Adaptive Mode Convergence

```
FOR each dimension:
  IF sampleSize >= 2 AND standardError < 5.0:
    → dimension.converged = true
    → stop adding questions for this dimension

IF all dimensions converged OR totalQuestions >= 50:
  → proceed to scoring
  → include: "Adaptive self-test converged after [X] questions (typical: 25-35)"
```

### IF: E2E Task Mode

```
FOR each E2E task:
  → ROLE = EXAMINEE: Execute the full multi-step scenario
  → ROLE = EXAMINER: Score on 4 axes:
    - Task completion (40%)
    - Process quality (25%)
    - Efficiency (20%)
    - Safety compliance (15%)
```

### IF: Retaking Self-Test

```
IF priorSession exists with same dimensions:
  → Default to new questions (broaden assessment)
  → IF user specifically requests same questions: use identical questions for direct comparison
  → Always show delta chart in report
```

### IF: Technical Issues

```
IF question loading fails:
  → Skip question, note in report, adjust scoring denominator
  → "Skipped 1 question due to technical issue — scoring adjusted accordingly."

IF scoring fails for a question:
  → Mark as "manual review required"
  → Exclude from automated scores, note in report

IF session interrupted (crash, timeout):
  → Save progress automatically
  → On next activation: "Found an interrupted self-test from [time]. Resume? [Y/n]"
```

---

## Error Recovery

| Error | Detection | Response | Impact |
|-------|-----------|----------|--------|
| Question not found | Missing from bank | Skip, adjust total | Noted in report |
| Scoring calculation error | Sum ≠ expected | Recalculate, log warning | None (auto-corrected) |
| Session timeout | Duration > 2x estimate | Score what's complete | Partial report |
| All questions fail to load | Bank error | Abort with error message | No score generated |
| History load failure | File/API error | Proceed without history | No trend comparison |

---

## Self-Check Checklist

Before presenting final report, verify ALL:

- [ ] Every question has a self-generated answer AND score with CoT justification
- [ ] Raw AND adjusted dimension scores are correctly calculated
- [ ] Raw AND adjusted overall scores equal weighted sum of dimensions (verify math)
- [ ] Self-Evaluation Disclaimer is prominently displayed
- [ ] All CoT self-judged scores show ⚠️ flag
- [ ] All scores ≥4 have "Why not [score-1]?" justification
- [ ] Radar chart has all 10 dimensions with adjusted values
- [ ] Heat map colors match the legend thresholds
- [ ] Language is self-perspective throughout ("I/My" not "You/Your")
- [ ] Recommendations focus on Agent self-development
- [ ] Trend data (if any) is chronologically correct
- [ ] No dimension was accidentally omitted
- [ ] Export-ready data includes evaluation_type: "self_test"
- [ ] Session saved for future history
