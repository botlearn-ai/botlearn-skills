# D4-Q2-MEDIUM Reference Answer

## Question: Generate a Structured JSON Report via Node.js Script

### Verification Criteria (Programmatic)

---

### 1. Script Executes (25%)

**Test**: `node generate-report.js` — must exit with code 0 and produce `exam-report.json`.

| Check | Expected | Fail Condition |
|-------|----------|---------------|
| No runtime errors | Exit code 0 | Any uncaught exception |
| Output file created | `exam-report.json` exists after execution | File not found |
| Valid JSON output | `JSON.parse()` succeeds on file content | Parse error |

### 2. JSON Structure Compliance (25%)

**Schema validation** — all fields must be present with correct types:

```json
{
  "sessionId": "string — matches /^exam-[0-9a-f]{8}$/",
  "timestamp": "string — valid ISO 8601 format",
  "dimensions": [
    {
      "name": "string — non-empty",
      "weight": "number — 0 < weight <= 1",
      "rawScore": "number — 0-100",
      "adjustedScore": "number — 0-100",
      "questions": [
        {
          "id": "string — e.g. Q1",
          "difficulty": "string — one of: easy, medium, hard",
          "score": "number — 0-100",
          "adjustedScore": "number — 0-100"
        }
      ]
    }
  ],
  "overallRaw": "number — 0-100",
  "overallAdjusted": "number — 0-100",
  "reliabilityIndex": "number — 0-1"
}
```

**Minimum content check**:
- `dimensions.length >= 3`
- Each dimension has `questions.length >= 2`

### 3. Numerical Calculation Correctness (30%)

**Mathematical verification** — each derived value must be checkable:

| Calculation | Formula | Tolerance |
|-------------|---------|-----------|
| `dimension.adjustedScore` | `dimension.rawScore * 0.95` | ±0.01 |
| `question.adjustedScore` | `question.score * 0.95` | ±0.01 |
| `overallRaw` | `sum(dimension.rawScore * dimension.weight)` for all dimensions | ±0.1 |
| `overallAdjusted` | `sum(dimension.adjustedScore * dimension.weight)` for all dimensions | ±0.1 |
| Weight sum | `sum(dimension.weight)` should equal 1.0 | ±0.01 |

**Verification script**:
```javascript
const report = JSON.parse(fs.readFileSync('exam-report.json', 'utf8'));

// Check adjusted scores
for (const dim of report.dimensions) {
  console.assert(
    Math.abs(dim.adjustedScore - dim.rawScore * 0.95) < 0.01,
    `${dim.name}: adjusted ${dim.adjustedScore} != raw ${dim.rawScore} * 0.95`
  );
  for (const q of dim.questions) {
    console.assert(
      Math.abs(q.adjustedScore - q.score * 0.95) < 0.01,
      `${q.id}: adjusted ${q.adjustedScore} != score ${q.score} * 0.95`
    );
  }
}

// Check overall
const expectedOverallRaw = report.dimensions.reduce(
  (sum, d) => sum + d.rawScore * d.weight, 0
);
console.assert(
  Math.abs(report.overallRaw - expectedOverallRaw) < 0.1,
  `overallRaw ${report.overallRaw} != expected ${expectedOverallRaw}`
);

// Check weight sum
const weightSum = report.dimensions.reduce((s, d) => s + d.weight, 0);
console.assert(
  Math.abs(weightSum - 1.0) < 0.01,
  `weight sum ${weightSum} != 1.0`
);
```

### 4. sessionId Format (10%)

**Regex test**: `/^exam-[0-9a-f]{8}$/`

| Check | Pass | Fail |
|-------|------|------|
| Starts with "exam-" | Required | Missing prefix |
| Followed by exactly 8 hex chars | Required | Wrong length or non-hex chars |
| Generated randomly | Should differ between runs | Hardcoded value |

**Implementation hint**: `crypto.randomBytes(4).toString('hex')` or `Math.random().toString(16).slice(2, 10)`

### 5. Code Readability (10%)

| Check | Score 0 | Score 3 | Score 5 |
|-------|---------|---------|---------|
| Comments | None | Some comments | Key functions documented |
| Naming | Single-letter variables | Descriptive but inconsistent | Clear, consistent naming |
| Structure | One giant block | Some functions | Well-organized with helper functions |

### Common Failure Modes

1. **adjustedScore calculated wrong**: Using `* 0.05` (subtract 5%) instead of `* 0.95`
2. **overallRaw not matching weighted sum**: Calculating simple average instead of weighted
3. **Hardcoded sessionId**: Same value every run instead of random
4. **Timestamp not ISO 8601**: Using locale string instead of `new Date().toISOString()`
5. **dimensions < 3 or questions < 2**: Not meeting minimum content requirement
