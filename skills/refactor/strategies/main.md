---
strategy: refactor
version: 1.0.0
steps: 6
---

# Code Refactoring Strategy

## Step 1: Smell Detection
- Receive the target code from the user — may be a specific method, class, module, or an entire file
- Invoke @botlearn/code-review to perform initial structural analysis and identify quality issues
- Scan the code systematically for each smell category from knowledge/domain.md:
  - **Bloaters**: Long Methods (>20 lines), Large Classes (>10 public methods), Long Parameter Lists (>3 params), Primitive Obsession, Data Clumps
  - **OO Abusers**: Switch Statements on type, Temporary Fields, Refused Bequest, Parallel Inheritance
  - **Change Preventers**: Divergent Change, Shotgun Surgery, Feature Envy
  - **Dispensables**: Duplicate Code, Dead Code, Lazy Class, Speculative Generality
  - **Couplers**: Inappropriate Intimacy, Message Chains, Middle Man
- Compute baseline metrics:
  - Cyclomatic complexity per method
  - Cognitive complexity per method
  - Afferent/efferent coupling per class
  - Duplication ratio (duplicated lines / total lines)
  - Depth of inheritance tree
- Output a prioritized smell inventory: `[smell_name, location, severity (P0-P3), estimated_effort]`
- IF no significant smells are detected (all methods CC < 10, no duplication, no structural issues) THEN report "code is clean" with metrics and stop

## Step 2: Pattern Matching
- For each detected smell, consult the refactoring technique mapping in knowledge/domain.md to identify candidate transformations
- Map smells to refactoring techniques:
  - Long Method → Extract Method, Decompose Conditional
  - Large Class → Extract Class, Extract Interface
  - Switch Statements → Replace Conditional with Polymorphism, Strategy Pattern
  - Duplicate Code → Extract Method, Pull Up Method, Template Method
  - Feature Envy → Move Method, Move Field
  - Long Parameter List → Introduce Parameter Object, Builder Pattern
  - Primitive Obsession → Replace Primitive with Value Object
  - Message Chains → Hide Delegate, introduce Facade
  - Deep Inheritance → Replace Inheritance with Composition
- For each candidate transformation, evaluate:
  - **Applicability**: Does this technique fit the specific code context?
  - **Risk**: What could go wrong? How complex is the transformation?
  - **Impact**: How much will this improve the target metric?
  - **Dependencies**: Does this transformation depend on another being completed first?
- IF a smell maps to a GoF design pattern THEN verify the pattern is justified:
  - Identify at least 2-3 concrete variations that the pattern would abstract over
  - Confirm the pattern reduces complexity rather than increasing it
  - Check against knowledge/anti-patterns.md #5 (Premature Abstraction) and #6 (Pattern Fever)
- Output a candidate transformation list: `[transformation, target_smell, pattern_if_any, risk_level, expected_improvement]`

## Step 3: Refactoring Plan
- Order candidate transformations by dependency topology:
  1. Foundational transformations first (Extract Interface, Introduce Parameter Object) — these enable later steps
  2. Structural transformations second (Extract Class, Move Method) — these reshape the code
  3. Pattern introductions third (Strategy, Template Method) — these add design structure
  4. Cleanup last (Remove Dead Code, Inline Temp, Rename) — these polish the result
- For each transformation step, specify:
  - **What**: Exact transformation to apply (e.g., "Extract lines 42-67 of `processOrder()` into `validateOrderItems()`")
  - **Why**: The smell it addresses and the metric it improves
  - **How**: Step-by-step mechanical instructions
  - **Verify**: What test(s) to run to confirm equivalence
  - **Rollback**: How to revert if verification fails
- Estimate total plan duration and per-step complexity
- IF the total plan exceeds 10 transformations THEN split into phases:
  - Phase A: Critical smells (P0-P1) — must-do
  - Phase B: Important smells (P2) — should-do
  - Phase C: Polish (P3) — nice-to-have
- Present the plan to the user for approval before proceeding
- IF the user requests modifications to the plan THEN adjust and re-present

## Step 4: Incremental Transform
- Before starting: verify the test suite passes (green baseline)
- IF test coverage on target code is below 80% THEN:
  - Write characterization tests to capture current behavior
  - Achieve adequate coverage before proceeding
  - Commit the new tests as a separate step
- Execute each transformation step from the plan sequentially:
  1. Announce the step: what will change and why
  2. Apply the mechanical transformation
  3. Verify the code compiles / passes syntax checks
  4. Run the relevant test suite
  5. IF tests pass THEN mark step complete and proceed
  6. IF tests fail THEN:
     - Analyze the failure — is it a bug in the refactoring or a test that was overly specific to the old structure?
     - IF refactoring bug THEN rollback the step and try an alternative approach
     - IF test is structure-dependent THEN update the test (document why) and re-run
  7. Commit the step with a descriptive refactoring message
- Apply transformations using these mechanical recipes:
  - **Extract Method**: Identify the code block → determine parameters (variables read) and return values (variables written) → create new method with those params/returns → replace original block with method call → verify
  - **Extract Class**: Identify the responsibility boundary → create new class → move related fields and methods → replace direct access with delegation → update callers → verify
  - **Replace Conditional with Polymorphism**: Identify the type discriminator → create an interface with the varying behavior → create concrete classes for each case → replace conditional with polymorphic call → verify
  - **Introduce Parameter Object**: Identify the parameter group → create a class/type for the group → replace parameter list with the new object → update all callers → verify
- Track progress: steps completed / total steps; metrics improvement so far

## Step 5: Equivalence Verification
- After all transformation steps are complete, perform comprehensive verification:
- **Test Suite Verification**:
  - Run the complete test suite (unit + integration) — ALL tests must pass
  - IF any test fails THEN diagnose and fix before proceeding; do NOT skip failing tests
- **Behavioral Contract Check** (from knowledge/best-practices.md):
  - [ ] All public method signatures unchanged (or changes are explicitly approved)
  - [ ] All preconditions preserved (same input validation, same parameter constraints)
  - [ ] All postconditions preserved (same return values, same state changes)
  - [ ] All invariants preserved (same object consistency rules)
  - [ ] All exception/error behavior preserved (same errors for same invalid inputs)
  - [ ] All side effects preserved (same external calls, same writes, same logging)
- **Regression Check**:
  - IF snapshot tests exist THEN compare output snapshots before and after
  - IF integration tests exist THEN run them against the refactored code
  - IF performance-sensitive code was refactored THEN run benchmarks and compare
- **Static Analysis Check**:
  - Run linter/static analyzer on refactored code
  - Verify no new warnings or errors introduced
  - Verify type safety is preserved or improved
- IF any verification check fails THEN:
  - Identify the specific transformation step that caused the failure
  - Rollback to the last known-good state
  - Apply an alternative transformation approach
  - Re-run verification

## Step 6: Quality Measurement
- Compute post-refactoring metrics on the same scope as the baseline:
  - Cyclomatic complexity per method (target: 20%+ reduction)
  - Cognitive complexity per method (target: 20%+ reduction)
  - Afferent/efferent coupling per class (target: reduced Ce, stable or increased Ca)
  - Duplication ratio (target: 50%+ reduction in duplicated lines)
  - Depth of inheritance tree (target: no increase; decrease if it was excessive)
  - Lines of code per method and per class (context-dependent — reduction is good only if clarity improves)
- Calculate quality improvement deltas:
  - `delta_cc = (baseline_cc - final_cc) / baseline_cc * 100`
  - `delta_cognitive = (baseline_cognitive - final_cognitive) / baseline_cognitive * 100`
  - `delta_coupling = (baseline_ce - final_ce) / baseline_ce * 100`
  - `delta_duplication = (baseline_dup - final_dup) / baseline_dup * 100`
- Present a summary report:
  ```
  ## Refactoring Summary
  - Smells resolved: N of M detected
  - Transformations applied: K steps
  - Complexity reduction: X% (cyclomatic), Y% (cognitive)
  - Coupling reduction: Z%
  - Duplication reduction: W%
  - Tests: all passing (N tests)
  - Behavioral equivalence: verified
  ```
- IF quality improvement is below the 40% target on key metrics THEN:
  - Identify remaining high-impact smells
  - Recommend Phase B/C refactoring steps for future sessions
- Provide recommendations for maintaining quality:
  - Suggest linter rules to prevent regression of resolved smells
  - Recommend test coverage targets for the refactored code
  - Flag any technical debt items discovered but deferred during this session
