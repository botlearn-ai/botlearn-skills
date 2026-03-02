---
domain: refactor
topic: refactoring-best-practices
priority: high
ttl: 30d
---

# Code Refactoring — Best Practices

## Incremental Refactoring

### 1. Small, Reversible Steps
- Each refactoring step should be a single, well-defined transformation (one Extract Method, one Move Field, one Rename)
- Every step must be independently compilable and testable — never leave code in a broken state between steps
- Maintain a rollback point before each transformation — use version control commits as checkpoints
- If a step takes more than 15 minutes without a green test suite, the step is too large — decompose further

### 2. The Refactoring Cycle
```
Red (failing test, if adding coverage) → Green (make it pass) → Refactor (improve structure) → Green (verify equivalence) → Commit
```
- Never refactor red code — always start from a passing test suite
- After each refactoring step, run the full relevant test suite before proceeding
- Commit after each successful step to create a rollback point

### 3. Prioritize by Impact
Rank refactoring candidates using this priority matrix:

| Priority | Criteria | Example |
|----------|----------|---------|
| P0 — Critical | Blocks feature development or causes bugs | Circular dependency preventing deployment |
| P1 — High | High complexity (CC > 20) in frequently modified code | God class edited in every sprint |
| P2 — Medium | Code smells in stable code with moderate complexity | Duplicate code in rarely-changed modules |
| P3 — Low | Cosmetic improvements, naming, formatting | Inconsistent naming conventions |

Focus on code that is **both complex and frequently changed** (high churn + high complexity = refactoring priority).

### 4. Scope Control
- Define a clear refactoring boundary before starting — which files/classes/methods are in scope
- Resist the urge to "fix one more thing" outside the defined scope
- Track discovered issues outside scope as separate refactoring tasks for later
- Time-box refactoring sessions: 30-90 minutes per focused refactoring session

## Test-Driven Refactoring

### 1. Characterization Tests
Before refactoring code that lacks tests:
- Write **characterization tests** that capture the current behavior, including edge cases
- Execute the code with various inputs and assert the actual outputs (even if they seem wrong)
- These tests serve as a behavioral contract — they should pass both before and after refactoring
- Cover at minimum: happy path, boundary values, null/empty inputs, error paths

### 2. Test Coverage Requirements
Before beginning a refactoring session:
- Verify that the code under refactoring has at least **80% line coverage** and **70% branch coverage**
- If coverage is insufficient, write additional tests BEFORE refactoring
- Pay special attention to conditional branches — each branch of an if/else, each case in a switch
- For extracted methods: ensure the original tests still exercise the extracted code through the caller

### 3. Mutation Testing Awareness
- After refactoring, consider whether the test suite would catch regressions introduced by common errors:
  - Off-by-one errors in extracted boundary logic
  - Inverted boolean conditions
  - Missing null checks after moving code
  - Changed evaluation order in extracted expressions
- If any mutation would go undetected, add targeted tests

### 4. Test Refactoring
- Tests themselves may need refactoring — but refactor tests and production code separately, never simultaneously
- When extracting a class, create a new test class for it; keep original tests as integration tests
- Use the same incremental approach for test refactoring: one step at a time, verify passing after each step

## Equivalence Verification

### 1. Behavioral Equivalence Checklist
After each refactoring step, verify:
- [ ] All existing tests pass without modification
- [ ] Public method signatures are unchanged (names, parameters, return types)
- [ ] Exception/error behavior is preserved (same exceptions for same invalid inputs)
- [ ] Side effects are preserved (same writes, same external calls, same logging)
- [ ] Concurrency behavior is preserved (thread safety, locking semantics, ordering)
- [ ] Performance characteristics are within acceptable bounds (no O(n) to O(n^2) regressions)

### 2. Contract-Based Verification
For each public method under refactoring, document:
- **Preconditions**: What must be true before the method is called (parameter constraints, object state)
- **Postconditions**: What must be true after the method returns (return value properties, state changes)
- **Invariants**: What must always be true about the object (field relationships, consistency rules)
- Verify that all three are preserved after refactoring

### 3. Snapshot Testing
For complex transformations:
- Record input/output pairs from the original code for a comprehensive set of scenarios
- After refactoring, replay the same inputs and compare outputs byte-for-byte
- This is especially valuable for functions with complex output (serialization, formatting, rendering)

### 4. Integration Point Verification
When refactoring code that interacts with external systems:
- Verify that API call patterns are unchanged (same endpoints, same payloads, same headers)
- Verify that database queries produce the same results
- Verify that message queue interactions are preserved (same topics, same message formats)
- Run integration tests if available; if not, document the integration contracts

## Code Quality Measurement

### 1. Before/After Metrics
Always measure and report:
- **Cyclomatic Complexity**: Per-method and per-class, before and after
- **Cognitive Complexity**: Per-method, before and after
- **Coupling**: Afferent and efferent, before and after
- **Duplication**: Lines/blocks of duplicate code, before and after
- **Lines of Code**: Per-method and per-class (with context — shorter is not always better)

### 2. Quality Gates
A refactoring is considered successful when:
- All tests pass (mandatory — non-negotiable)
- Cyclomatic complexity of target methods is reduced by at least 20%
- No new code smells are introduced (verified by static analysis)
- Code review indicates improved readability
- No performance regressions beyond 5% in hot paths

### 3. Static Analysis Integration
Leverage static analysis tools to validate improvements:
- Run linter before and after to compare violation counts
- Check for new warnings introduced by the refactoring
- Validate that type safety is preserved or improved
- Ensure no new accessibility or security issues are introduced

## Communication and Documentation

### 1. Refactoring Commit Messages
Structure commit messages for refactoring:
```
refactor(<scope>): <what was changed>

- Why: <smell or metric that triggered the refactoring>
- How: <technique applied (e.g., Extract Method, Replace with Strategy)>
- Metrics: <before/after complexity, coupling, or duplication numbers>
- Equivalence: <how behavioral equivalence was verified>
```

### 2. Decision Records
For significant refactorings (pattern introductions, architecture changes):
- Document the problem that triggered the refactoring
- List alternatives considered and why the chosen approach was selected
- Record the expected and actual quality improvements
- Note any trade-offs or known limitations of the new design
