---
domain: code-review
topic: best-practices
priority: high
ttl: 30d
---

# Code Review — Best Practices

## Structured Review Methodology

### Review Order (Priority-First)
1. **Security** — Scan for OWASP Top 10 vulnerabilities first; these are Critical/High
2. **Correctness** — Logic errors, off-by-one, null/undefined handling, edge cases
3. **Performance** — N+1 queries, memory leaks, algorithmic complexity
4. **Concurrency** — Race conditions, deadlocks, thread safety
5. **Maintainability** — Code smells, naming, structure, test coverage
6. **Style** — Only after all substantive issues are addressed

### Review Scope Awareness
- Before reviewing, identify: language, framework, runtime environment, deployment context
- Adjust severity based on context (e.g., SQL injection in a CLI tool vs. a public API)
- Consider the blast radius of each issue (affects one user vs. all users vs. data integrity)

## Severity Classification

| Severity | Criteria | Action | Examples |
|----------|----------|--------|----------|
| **Critical** | Exploitable security vulnerability or data loss risk | Must fix before merge | SQL injection, authentication bypass, data exposure |
| **High** | Significant bug, security weakness, or performance degradation | Should fix before merge | Missing authorization check, N+1 in hot path, race condition |
| **Medium** | Code smell, moderate performance issue, or minor security hardening | Fix in next iteration | Long method, missing input validation on internal API, unnecessary allocation |
| **Low** | Improvement opportunity, minor smell, or style preference | Nice to have | Naming improvement, dead code removal, minor refactoring |
| **Info** | Observation, suggestion, or praise | Optional | Alternative approach suggestion, positive reinforcement |

## Constructive Feedback Patterns

### Finding Format
Each finding should include:
1. **Location**: File, line number, function name
2. **Issue**: What is wrong (specific, factual)
3. **Impact**: Why it matters (security risk, performance cost, maintenance burden)
4. **Severity**: Critical / High / Medium / Low / Info
5. **Fix**: Concrete suggestion with code example when possible

### Good vs. Bad Feedback

**Bad**: "This code is messy and has issues."
**Good**: "The `processOrder()` function (line 42-98) has 4 levels of nesting and handles validation, business logic, and persistence. Extract validation into `validateOrder()` and persistence into `saveOrder()` to improve testability. [Medium]"

**Bad**: "Security issue here."
**Good**: "SQL injection vulnerability at line 23: `db.query('SELECT * FROM users WHERE id = ' + req.params.id)`. An attacker can manipulate the `id` parameter to execute arbitrary SQL. Fix: Use parameterized queries: `db.query('SELECT * FROM users WHERE id = $1', [req.params.id])`. [Critical]"

### Positive Reinforcement
- Acknowledge good patterns when found (proper error handling, good test coverage, clean abstractions)
- This builds trust and helps the developer know what to keep doing

## Overall Health Assessment

### Quality Dimensions
Score each dimension on a 1-5 scale:

| Dimension | What to assess |
|-----------|---------------|
| **Security** | Authentication, authorization, input validation, data protection |
| **Performance** | Query patterns, algorithm efficiency, memory usage, caching |
| **Maintainability** | Code organization, naming, complexity, coupling |
| **Reliability** | Error handling, edge cases, logging, recovery |
| **Test Coverage** | Presence of tests, coverage of critical paths, edge case tests |

### Prioritized Action Items
Always end the review with a prioritized list:
1. **Must fix** — Critical and High severity issues
2. **Should fix** — Medium severity issues with clear ROI
3. **Consider** — Low severity improvements for future cleanup

## Fix Suggestion Quality

### Always Provide Copy-Pasteable Code
When suggesting a fix, provide code that can be directly used:

```
// Before (vulnerable)
const user = await db.query(`SELECT * FROM users WHERE id = ${id}`);

// After (safe)
const user = await db.query('SELECT * FROM users WHERE id = $1', [id]);
```

### Explain the Fix
Brief explanation of WHY the fix works, not just WHAT to change. This teaches the developer and prevents recurrence.
