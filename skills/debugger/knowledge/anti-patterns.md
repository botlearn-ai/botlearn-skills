---
domain: debugger
topic: anti-patterns
priority: medium
ttl: 30d
---

# Debugging — Anti-Patterns

## Investigation Anti-Patterns

### 1. Symptom Fixing (Patch-and-Pray)
- **Problem**: Applying a surface-level fix that silences the error without understanding the root cause. Example: wrapping a NullPointerException in a try-catch that returns a default value
- **Why it's harmful**: The underlying defect remains. It will resurface in a different form, often harder to diagnose, or cause silent data corruption
- **Fix**: Always trace the causal chain from symptom to root cause before writing any fix code. Ask: "Why is this value null?" not "How do I handle null?"

### 2. Shotgun Debugging
- **Problem**: Making multiple simultaneous changes hoping one of them fixes the bug, without understanding which change (if any) actually addresses the root cause
- **Why it's harmful**: Even if the bug disappears, you don't know why. You may have introduced side effects, masked the real issue, or created new bugs. You cannot write a meaningful regression test
- **Fix**: Change exactly ONE variable at a time. Observe the result. Revert if it didn't help. Proceed methodically

### 3. Ignoring Error Messages
- **Problem**: Glancing at an error and immediately forming a theory without reading the full message, stack trace, and context
- **Why it's harmful**: Error messages are the most direct diagnostic evidence. Ignoring them leads to investigating the wrong hypothesis entirely. Developers frequently report spending hours debugging only to discover the answer was in the error message
- **Fix**: Read the ENTIRE error message. Read the ENTIRE stack trace. Parse every field: exception type, message string, file, line, column. Then hypothesize

### 4. Assuming the Bug Is Somewhere Else
- **Problem**: Blaming the framework, library, compiler, or OS without evidence. "It must be a React bug" or "The database is broken"
- **Why it's harmful**: Widely-used libraries have been tested by millions of users. The bug is almost certainly in your code. Blaming external components wastes time investigating the wrong system
- **Fix**: Assume the bug is in YOUR code until you have strong evidence otherwise. Only escalate to library/framework investigation after ruling out your own code with concrete evidence

### 5. Not Reading the Documentation
- **Problem**: Using an API based on assumptions about its behavior instead of reading the official documentation
- **Why it's harmful**: APIs frequently have non-obvious semantics: nullable return values, specific error conditions, required initialization order, thread-safety guarantees (or lack thereof)
- **Fix**: Before debugging an API integration issue, re-read the relevant documentation section. Check for known issues, version-specific behavior changes, and migration guides

## Process Anti-Patterns

### 6. Debugging Without Reproducing
- **Problem**: Attempting to fix a bug based solely on a bug report or stack trace without first reproducing it locally
- **Why it's harmful**: Without reproduction, you cannot verify your fix works. You may fix a different bug or introduce a regression. You have no way to write a regression test
- **Fix**: ALWAYS reproduce the bug before attempting a fix. If reproduction is difficult, invest time in creating a minimal reproduction case. If the bug is intermittent, increase the probability of occurrence (e.g., stress test, increase parallelism)

### 7. Not Using Version Control During Debugging
- **Problem**: Making changes to investigate a bug without committing or stashing first, leading to a tangled mix of investigation code and attempted fixes
- **Why it's harmful**: You cannot cleanly revert to a known state. You lose track of what you changed. You may accidentally commit debug code
- **Fix**: Always stash or commit your work before starting to debug. Create a debug branch. Make each investigation step a separate commit that can be reverted. Use `git bisect` when the bug is a regression

### 8. Premature Optimization During Bug Fix
- **Problem**: While fixing a bug, simultaneously refactoring or optimizing the surrounding code
- **Why it's harmful**: Conflates two different changes. If the fix introduces a new bug, it's harder to isolate. Code review becomes more difficult. The optimization may not be needed
- **Fix**: Fix the bug in the smallest possible change. Commit. Then refactor or optimize in a separate commit if warranted

### 9. Debugging in Production
- **Problem**: Adding debug logging, print statements, or experimental fixes directly in the production environment
- **Why it's harmful**: Risk of breaking production for all users. Debug output may expose sensitive data. Changes are not tracked in version control
- **Fix**: Reproduce the bug in a development or staging environment. If production-only debugging is unavoidable, use observability tools (structured logging, APM, distributed tracing) instead of code changes

### 10. Ignoring Intermittent Failures
- **Problem**: Dismissing a test or error that "only fails sometimes" as a flaky test or transient issue without investigation
- **Why it's harmful**: Intermittent failures are often concurrency bugs, race conditions, or timing-dependent issues — the hardest and most dangerous class of bugs. They tend to worsen under load
- **Fix**: Treat intermittent failures as HIGH priority. They often indicate a real concurrency or state-management bug. Run the test in a loop (100-1000 iterations) to increase reproduction probability. Add logging at synchronization points

## Output Anti-Patterns

### 11. Vague Bug Reports
- **Problem**: Describing the bug as "it doesn't work" or "it's broken" without specifying: what was expected, what actually happened, steps to reproduce, environment details
- **Why it's harmful**: Forces the recipient to guess and ask follow-up questions, wasting time. May lead to investigating the wrong issue
- **Fix**: Every bug report should include: (1) steps to reproduce, (2) expected behavior, (3) actual behavior, (4) environment details, (5) relevant error output

### 12. Fix Without Regression Test
- **Problem**: Fixing a bug without adding a test that would catch it if reintroduced
- **Why it's harmful**: Without a regression test, the same bug can (and often does) come back in a future change. The team has no automated safety net for this specific failure mode
- **Fix**: For every bug fix, write at least one test that: (1) fails without the fix applied, (2) passes with the fix applied, (3) covers the specific input/state that triggered the original bug
