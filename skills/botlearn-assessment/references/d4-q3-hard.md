# D4-Q3-HARD Reference Answer

## Question: Complete TypeScript Scorer Module

### Verification Criteria (Programmatic)

---

### 1. TypeScript Compiles (20%)

**Test**: `tsc scorer.ts` exits with 0 errors.

| Check | Expected | Fail Condition |
|-------|----------|---------------|
| No compilation errors | Exit code 0 | Any TypeScript error |
| Strict mode compatible | Should work with `--strict` flag | Implicit `any` or missing types |
| No `any` type abuse | Minimal or zero `any` usage | `any` used for core data types |

### 2. Type Definition Completeness (20%)

**Required interfaces** (must be present and complete):

```typescript
interface Question {
  id: string;
  dimension: string;
  difficulty: 'easy' | 'medium' | 'hard';
  rawScore: number; // 0-100
}

interface DimensionConfig {
  name: string;
  weight: number;
}

// Must be defined by the examinee:
interface ExamReport {
  sessionId: string;
  timestamp: string;
  dimensions: DimensionResult[];
  overallRaw: number;
  overallAdjusted: number;
}

interface DimensionResult {
  name: string;
  weight: number;
  rawScore: number;           // weighted average of question raw scores
  adjustedScore: number;      // rawScore * 0.95
  questions: QuestionResult[];
}

interface QuestionResult {
  id: string;
  difficulty: 'easy' | 'medium' | 'hard';
  rawScore: number;
  adjustedScore: number;      // rawScore * 0.95
  difficultyMultiplier: number; // 1.0 / 1.2 / 1.5
}
```

**Checklist**:
- [ ] `ExamReport` interface defined (not just using `any` or inline types)
- [ ] `DimensionResult` interface defined
- [ ] `QuestionResult` interface defined
- [ ] Difficulty is typed as union `'easy' | 'medium' | 'hard'`, not `string`
- [ ] Return type of `calculateReport` is `ExamReport`

### 3. Business Logic Correctness (35%)

**Three business rules that must be correctly implemented**:

#### Rule 1: Adjusted Score
```
adjustedScore = rawScore * 0.95
```
Applied at both question and dimension level.

#### Rule 2: Difficulty Multipliers
```
easy   = 1.0
medium = 1.2
hard   = 1.5
```

#### Rule 3: Dimension Score Calculation
```
DimensionScore = sum(adjustedScore_i * difficultyMultiplier_i) / sum(difficultyMultiplier_i)
```
This is a weighted average where the weights are the difficulty multipliers, NOT a simple average.

**Example verification**:
```
Questions for D1:
  Q1: easy,  rawScore=80 → adjusted=76, multiplier=1.0 → contribution=76*1.0=76
  Q2: hard,  rawScore=60 → adjusted=57, multiplier=1.5 → contribution=57*1.5=85.5

DimensionScore = (76 + 85.5) / (1.0 + 1.5) = 161.5 / 2.5 = 64.6
```

#### Overall Score
```
OverallScore = sum(DimensionScore_i * dimensionWeight_i)
```

**Verification test case**:
```typescript
const questions: Question[] = [
  { id: 'Q1', dimension: 'D1', difficulty: 'easy', rawScore: 80 },
  { id: 'Q2', dimension: 'D1', difficulty: 'hard', rawScore: 60 },
  { id: 'Q3', dimension: 'D2', difficulty: 'medium', rawScore: 90 },
];

const dimensions: DimensionConfig[] = [
  { name: 'D1', weight: 0.6 },
  { name: 'D2', weight: 0.4 },
];

// Expected:
// D1: (80*0.95*1.0 + 60*0.95*1.5) / (1.0+1.5) = (76+85.5)/2.5 = 64.6
// D2: (90*0.95*1.2) / 1.2 = 102.6/1.2 = 85.5
// Overall raw:  (64.6*0.6 + 85.5*0.4) = 38.76 + 34.2 = 72.96
// Overall adj:  same since adjusted is already applied per-question
```

### 4. Error Handling (15%)

**Edge cases that should be handled**:

| Edge Case | Expected Behavior |
|-----------|-------------------|
| Empty questions array | Return report with zero scores, no crash |
| Empty dimensions array | Return report with zero scores, no crash |
| Weight sum != 1.0 | Either normalize weights or throw descriptive error |
| rawScore < 0 or > 100 | Clamp to valid range or throw error |
| Question references unknown dimension | Skip or throw descriptive error |
| Dimension with no questions | Score = 0, noted in result |

### 5. Test Case Quality (10%)

**Minimum 3 `console.assert` statements**:

```typescript
// Test 1: Basic calculation
const report = calculateReport(questions, dimensions);
console.assert(report.dimensions.length === 2, 'Should have 2 dimensions');

// Test 2: Adjusted score correctness
console.assert(
  Math.abs(report.dimensions[0].adjustedScore - 64.6) < 0.1,
  'D1 adjusted score should be ~64.6'
);

// Test 3: Overall score
console.assert(
  Math.abs(report.overallAdjusted - 72.96) < 0.1,
  'Overall should be ~72.96'
);
```

**Quality levels**:
- 1 assert = minimal (score 1-2)
- 3 asserts covering different aspects = good (score 3-4)
- 5+ asserts including edge cases = excellent (score 5)

### Common Failure Modes

1. **Simple average instead of weighted**: `sum(scores) / count` instead of `sum(score * multiplier) / sum(multipliers)`
2. **Multiplier applied to raw instead of adjusted**: Should be `adjustedScore * multiplier`, not `rawScore * multiplier` then adjust
3. **Missing ExamReport type**: Using inline object type or `any`
4. **No error handling at all**: Function crashes on empty input
5. **Test assertions always pass**: Using tautological assertions like `assert(true)`
