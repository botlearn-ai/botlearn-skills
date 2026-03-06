---
strategy: botlearn-assessment
topic: scoring-rules
version: 3.0.0
---

# Scoring Rules

## Formula

```
# Per question:
RawScore = Σ(criterion_score × criterion_weight) × 20    [0–100]
AdjScore = RawScore × 0.95                               [CoT-judged questions only]

# Per dimension (1 random question per run):
DimScore_raw = RawScore of the selected question
DimScore_adj = AdjScore of the selected question
# If question was SKIPPED (missing tool): DimScore = 0

# Overall (dimension-weighted):
Overall_raw = D1_raw×0.25 + D2_raw×0.22 + D3_raw×0.18 + D4_raw×0.20 + D5_raw×0.15
Overall_adj = D1_adj×0.25 + D2_adj×0.22 + D3_adj×0.18 + D4_adj×0.20 + D5_adj×0.15
```

## Dimension Weights

| Dimension | Weight | Rationale |
|-----------|--------|-----------|
| D1 Reasoning & Planning | 25% | Most predictive of real-world agent success (GAIA r=0.78) |
| D2 Information Retrieval | 22% | Critical for grounded, factual responses |
| D3 Content Creation | 18% | High user-facing impact |
| D4 Execution & Building | 20% | Core skill-based architecture requirement |
| D5 Tool Orchestration | 15% | Important but depends on installed skills |

## Difficulty Multipliers

| Difficulty | Multiplier |
|-----------|-----------|
| Easy | ×1.0 |
| Medium | ×1.2 |
| Hard | ×1.5 |

Note: Since each dimension only has 1 randomly selected question per run, the difficulty multiplier is recorded for context but does not affect the weighted average calculation (there's only one score to average).

## Skipped Questions

If a question is SKIPPED due to missing tools/capabilities:
- DimScore = 0 (both raw and adjusted)
- The skip reason is recorded in the report
- The dimension still contributes to the overall weighted score (as 0)
- Report clearly marks which dimensions were skipped

## Verification Methods

| Symbol | Method | Correction | Confidence |
|--------|--------|------------|-----------|
| 🔬 | Programmatic (code run, DOM check, math verify, schema validation) | None | ±5% |
| 📖 | Reference answer match (exact or semantic) | None | ±10% |
| 🧠 | CoT self-judge (rubric + Chain-of-Thought reasoning) | -5% global | ±15% |

## Self-Evaluation Integrity Rules

1. **Role separation**: ROLE = EXAMINEE when answering — do NOT consult rubric. ROLE = EXAMINER when scoring — apply rubric strictly.
2. **-5% correction**: Applied to ALL CoT self-judged scores. AdjScore = RawScore × 0.95.
3. **Programmatic scores not corrected**: Objective verification results reported as-is.
4. **Direct zero rule**: If a question requires a capability the agent does not have, score 0 — never estimate or guess. Auto-skip the entire question.
5. **Score 5 evidence requirement**: A criterion score of 5/5 must include "why not 4?" justification.
6. **First-exam cap**: If no historical exam records exist in `results/INDEX.md`, all criterion scores are capped at **4/5**. The agent tends to overestimate on first assessment ("doesn't know what it doesn't know"). This cap is removed once 1+ prior exam records exist.
7. **Immediate submission**: Once a score is output to the user, it is FINAL. No revision.
8. **No user assistance**: The user is the invigilator. Never ask for help during scoring.

## Criterion Score Scale (0–5)

| Score | Meaning |
|-------|---------|
| 5 | Fully meets all requirements; exceeds expectations. Must justify "why not 4?" |
| 4 | Meets most requirements; minor gaps |
| 3 | Partially meets requirements; noticeable gaps |
| 2 | Attempts the requirement; significant gaps |
| 1 | Minimal attempt; mostly fails |
| 0 | No attempt or capability entirely absent |

## Performance Levels

| Level | Score Range |
|-------|------------|
| Expert | 90–100 |
| Advanced | 80–89 |
| Proficient | 70–79 |
| Competent | 60–69 |
| Beginner | < 60 |

## Result File Naming

```
results/exam-{YYYYMMDD}-{HHmm}-full.md    ← Full exam (5 random questions)
results/exam-{YYYYMMDD}-{HHmm}-d1.md      ← D1 dimension only (1 random question)
results/exam-{YYYYMMDD}-{HHmm}-d2.md      ← D2 dimension only
results/exam-{YYYYMMDD}-{HHmm}-d3.md      ← D3 dimension only
results/exam-{YYYYMMDD}-{HHmm}-d4.md      ← D4 dimension only
results/exam-{YYYYMMDD}-{HHmm}-d5.md      ← D5 dimension only
results/INDEX.md                           ← Auto-updated history index
```

## Language Adaptation Note

All scoring rules and rubrics are written in English (internal instructions).
When presenting scores, reports, and feedback to the user, output in the user's detected language.
