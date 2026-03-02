---
strategy: debugger
version: 1.0.0
steps: 7
---

# Debugging Strategy

## Step 1: Symptom Analysis
- Collect ALL available diagnostic data: error messages, stack traces, logs, screenshots, user-reported steps
- Parse the error message completely — identify: exception type, message body, file, line, column
- Read the FULL stack trace — identify: the failure frame, the boundary between your code and library code, and the call chain
- Classify the symptom using knowledge/domain.md bug taxonomy:
  - Logic error / Null reference / Type error / Concurrency / Resource / Async / Import / Other
- Record: **expected behavior** vs. **actual behavior** vs. **environment context** (OS, runtime version, configuration)
- IF the symptom report is incomplete THEN ask for: exact error message, steps to reproduce, environment details

## Step 2: Hypothesis Generation
- Based on the symptom classification, generate 2-4 ranked hypotheses for the root cause
- For each hypothesis, specify:
  - **What**: The specific defect (e.g., "variable `user` is null because the API returns 404 when the user is not found")
  - **Where**: The file and approximate code region
  - **Why**: What makes this hypothesis plausible given the symptoms
  - **Test**: How to confirm or disprove this hypothesis
- Rank hypotheses by:
  1. **Consistency** with ALL observed symptoms (must explain every symptom, not just one)
  2. **Probability** based on common bug patterns (knowledge/domain.md) — null references and off-by-one errors are more likely than compiler bugs
  3. **Testability** — prefer hypotheses that can be quickly confirmed or disproved
- IF the code is available THEN leverage @botlearn/code-review to identify defect-prone patterns (deep nesting, missing error handling, unvalidated inputs) that support or refute hypotheses

## Step 3: Reproduction
- Design the **minimal reproduction case**: the smallest input + code + configuration that triggers the bug
- Follow the minimization process from knowledge/best-practices.md:
  1. Start with the full failing scenario
  2. Remove components one at a time, verifying the bug persists after each removal
  3. Simplify input data to the smallest triggering case
  4. Document the exact steps: "Given X, when Y, then Z happens instead of W"
- IF the bug is intermittent THEN:
  - Increase parallelism or load to amplify the timing window
  - Add logging at synchronization points
  - Run the reproduction in a loop (100+ iterations) with state logging
- IF the bug cannot be reproduced locally THEN:
  - Verify environment parity (versions, configuration, data state)
  - Check for environment-specific factors: timezone, locale, file system permissions, network latency
  - Consider using production observability (traces, metrics) if available

## Step 4: Root Cause Isolation
- Test the top-ranked hypothesis first:
  - Change exactly ONE variable and observe the result
  - IF the prediction from Step 2 holds THEN the hypothesis is supported — gather one more piece of confirming evidence
  - IF the prediction fails THEN discard the hypothesis and test the next one
- Use bisection techniques from knowledge/best-practices.md to narrow the search space:
  - **Code bisection**: Insert diagnostic checks at the midpoint of the suspect code path
  - **Git bisect**: If the bug is a regression, identify the first bad commit in O(log n) steps
  - **Data bisection**: If triggered by specific input, bisect the input to find the minimal trigger
- Verify anti-patterns from knowledge/anti-patterns.md are not present in your investigation:
  - Are you changing multiple things at once? (shotgun debugging)
  - Are you ignoring the error message? (ignoring error messages)
  - Are you blaming the framework without evidence? (assuming bug is elsewhere)
- The step is complete when you can state: "The root cause is [specific defect] in [specific location] because [evidence]"

## Step 5: Fix Design
- Design the fix to address the ROOT CAUSE, not the symptom:
  - IF the root cause is a missing null check THEN add validation at the source of the null, not a try-catch at the crash point
  - IF the root cause is a race condition THEN add proper synchronization, not a retry/sleep workaround
  - IF the root cause is a logic error THEN correct the logic, not add a special-case branch
- Evaluate fix options if multiple exist:
  - **Correctness**: Does it fully resolve the root cause?
  - **Scope**: Is the change minimal and focused? (avoid premature optimization — knowledge/anti-patterns.md #8)
  - **Side effects**: Could the fix break other code paths? Check callers and dependents
  - **Consistency**: Does it follow the codebase's existing patterns and conventions?
- Request @botlearn/code-review on the proposed fix before implementation if the change is non-trivial

## Step 6: Regression Test Design
- Write at least ONE test that:
  1. **Fails** without the fix applied (reproduces the original bug)
  2. **Passes** with the fix applied
  3. Covers the specific input/state/sequence that triggered the bug
- Consider edge case tests:
  - Boundary values (0, -1, MAX_INT, empty string, empty array, null)
  - Concurrent access scenarios (if the bug was concurrency-related)
  - Error handling paths (if the bug was in exception handling)
- Name the test descriptively to document the bug:
  - `test_processOrder_returnsError_whenItemQuantityIsZero`
  - `test_userList_rendersEmpty_whenApiReturnsEmptyArray`
- IF the codebase has no test infrastructure THEN provide the test as a standalone script with clear pass/fail output

## Step 7: Verification
- Apply the fix and run the regression test — confirm it passes
- Run the FULL test suite — confirm no new failures introduced
- Re-test the original reproduction case from Step 3 — confirm the bug is resolved
- Verify edge cases from Step 6 — confirm they pass
- SELF-CHECK against knowledge/best-practices.md Fix Verification Checklist:
  - [ ] Original bug no longer reproducible
  - [ ] No new failures introduced
  - [ ] Edge cases covered
  - [ ] Regression test exists and is meaningful
  - [ ] Fix addresses root cause, not symptom
  - [ ] Code review completed
- IF any check fails THEN loop back to the appropriate step:
  - New failures → Step 5 (revise fix design)
  - Edge case failures → Step 6 (add more tests, adjust fix)
  - Root cause not actually fixed → Step 4 (re-investigate)
- Output the final deliverable:
  - **Root Cause**: One-sentence description of the defect
  - **Evidence**: Key diagnostic findings that confirmed the root cause
  - **Fix**: Description of the change with code diff
  - **Regression Test**: The test(s) added
  - **Risk Assessment**: Any residual risk or areas to monitor
