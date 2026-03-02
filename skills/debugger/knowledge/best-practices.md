---
domain: debugger
topic: debugging-methodologies-and-strategies
priority: high
ttl: 30d
---

# Debugging — Best Practices

## The Scientific Debugging Method

Debugging is hypothesis-driven investigation. Apply the scientific method rigorously:

### 1. Observe
- Collect all available evidence: error messages, stack traces, logs, user reports, screenshots
- Record the exact steps to reproduce, the expected behavior, and the actual behavior
- Note the environment: OS, language version, framework version, configuration

### 2. Hypothesize
- Based on observed symptoms, formulate 2-3 ranked hypotheses for the root cause
- Each hypothesis must be **falsifiable** — you must be able to design a test that would disprove it
- Rank by likelihood using bug pattern knowledge (see knowledge/domain.md)

### 3. Predict
- For each hypothesis, predict what you would observe if it were true
- Example: "If the bug is a race condition, adding a sleep(1) before the read should make it pass consistently"

### 4. Test
- Design the smallest experiment that distinguishes between hypotheses
- Change exactly ONE variable at a time
- Record the result: did the prediction hold?

### 5. Conclude
- If the prediction held: the hypothesis is supported (but gather more evidence if possible)
- If the prediction failed: discard the hypothesis and promote the next one
- Repeat until root cause is confirmed with high confidence

## Binary Search / Bisection Debugging

The most powerful technique for narrowing down bugs in large codebases or long histories.

### Code Bisection (Runtime)
1. Identify a known-good state and a known-bad state
2. Insert a diagnostic check at the midpoint of the code path between them
3. Determine which half contains the bug
4. Repeat, halving the search space each time
5. **Efficiency**: Finds the bug in O(log n) steps instead of O(n)

### Git Bisect (Historical)
```bash
git bisect start
git bisect bad              # Current commit is broken
git bisect good abc1234     # This older commit was working
# Git checks out the midpoint — test it
git bisect good             # or git bisect bad
# Repeat until the first bad commit is found
git bisect reset
```
- **When to use**: Bug exists now but worked before; unclear when it was introduced
- **Automate**: `git bisect run ./test_script.sh` for fully automated bisection

### Data Bisection
- For bugs triggered by specific input data, bisect the input:
  1. Split the input in half
  2. Test each half separately
  3. Recurse on the half that triggers the bug
  4. Identify the minimal triggering input

## Strategic Logging

### Log Placement Strategy

| Placement | Purpose | Example |
|-----------|---------|---------|
| Function entry | Verify function is called with expected args | `log.debug("processOrder called", {orderId, items})` |
| Before external call | Verify outbound request data | `log.debug("Calling payment API", {payload})` |
| After external call | Verify response data | `log.debug("Payment API response", {status, body})` |
| Branch points | Verify which code path executes | `log.debug("Using cache path" \| "Using DB path")` |
| Loop iterations | Track iteration state for off-by-one / infinite loops | `log.debug("Loop iteration", {i, current, total})` |
| Catch blocks | Always log caught exceptions with full context | `log.error("Failed to process", {error, context})` |

### Structured Logging for Debugging
- Use structured key-value pairs, not string concatenation
- Include correlation IDs to trace requests across services
- Log the **state** (variable values) not just the **event** (what happened)
- Use log levels appropriately: DEBUG for investigation, ERROR for failures, WARN for recoverable issues

### Temporary Debug Logging Pattern
```
// DEBUG-START: investigating issue #1234
console.log('[DEBUG-1234] state at checkpoint:', JSON.stringify(state));
// DEBUG-END
```
- Always tag temporary logging with a ticket/issue number
- Always remove before committing (or use a lint rule to catch it)

## Rubber Duck Debugging

When stuck, explain the problem out loud (or in writing) step by step:

1. State the expected behavior clearly
2. State the actual behavior clearly
3. Walk through the code line by line, explaining what each line does
4. The act of explaining often reveals the incorrect assumption

**Why it works**: Forces you to examine each assumption explicitly rather than glossing over them mentally.

## Minimal Reproduction

### Why Minimize?
- Removes noise from unrelated code/data
- Makes the bug easier to understand and communicate
- Confirms you understand what triggers the bug
- Provides a ready-made regression test

### Minimization Process
1. Start with the full failing scenario
2. Remove components one at a time, checking if the bug persists
3. Simplify input data to the smallest triggering case
4. Remove configuration, middleware, and dependencies that are not involved
5. The result should be the **smallest code + input that reproduces the bug**

### Reproduction Environment Checklist
- [ ] Same language/runtime version
- [ ] Same dependency versions (check lock files)
- [ ] Same OS or container environment
- [ ] Same configuration / environment variables
- [ ] Same data state (database, cache, files)

## Debugging by Error Category

### For Null/Undefined Errors
1. Trace the variable backwards from the crash point to where it was assigned
2. Identify which code path leads to the null/undefined assignment
3. Common sources: missing API response field, failed database query, uninitialized state

### For Async/Promise Errors
1. Map the async execution flow (draw it if needed)
2. Check for missing `await`, unhandled rejections, or callback error parameters
3. Verify execution order — async code may not run in the order it appears

### For Performance Bugs
1. Profile first, optimize second — never guess at bottlenecks
2. Check algorithmic complexity: O(n^2) in a loop over large data is a common culprit
3. Look for N+1 query patterns in database-backed code
4. Check for unnecessary re-renders in frontend frameworks

### For Concurrency Bugs
1. Identify shared mutable state
2. Map the order of lock acquisitions across threads
3. Use thread-safe data structures or synchronization primitives
4. Test with increased parallelism to amplify timing-sensitive bugs

## Fix Verification Checklist

After implementing a fix:
- [ ] The original bug is no longer reproducible
- [ ] No new failures introduced (run full test suite)
- [ ] Edge cases covered (empty input, null, boundary values, concurrent access)
- [ ] A regression test exists that would catch this bug if reintroduced
- [ ] The fix addresses the root cause, not just the symptom
- [ ] Code review completed (leverage @botlearn/code-review)
