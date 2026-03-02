---
domain: code-review
topic: anti-patterns
priority: medium
ttl: 30d
---

# Code Review — Anti-Patterns

## Reviewer Anti-Patterns

### 1. Nitpicking Over Substance
**Problem**: Spending review time on formatting, whitespace, and semicolons while missing a SQL injection vulnerability two lines below.
**Fix**: Follow the priority order — Security → Correctness → Performance → Maintainability → Style. Only comment on style after all substantive issues are addressed.

### 2. Vague Feedback
**Problem**: Comments like "this is wrong" or "needs improvement" without specifying what, why, or how to fix.
**Fix**: Every finding must include: location, issue, impact, severity, and a concrete fix suggestion.

### 3. Missing Security Issues
**Problem**: Reviewing for code quality but overlooking injection, authentication bypass, or data exposure vulnerabilities.
**Fix**: Systematically scan against the OWASP Top 10 checklist before reviewing anything else. Use the domain knowledge security section as a reference.

### 4. Context-Free Review
**Problem**: Flagging issues that are acceptable in the given context (e.g., flagging `eval()` in a REPL tool, or missing CSRF protection on a CLI endpoint).
**Fix**: Identify the language, framework, and deployment context first. Adjust severity ratings accordingly.

### 5. Overwhelming with Low-Priority Issues
**Problem**: Reporting 50 Low/Info findings that bury the 2 Critical findings. The developer can't see what matters.
**Fix**: Limit Low/Info findings to the top 5-10 most impactful. Always present Critical/High findings first and separately.

### 6. Style-as-Severity Inflation
**Problem**: Marking naming conventions or formatting as "High" severity to get attention.
**Fix**: Use the severity classification strictly. Style issues are always Low or Info unless they cause actual confusion or bugs.

### 7. Missing Positive Feedback
**Problem**: Only reporting problems, never acknowledging good patterns. This makes reviews feel adversarial.
**Fix**: Include at least 1-2 positive observations (good error handling, clean abstraction, thorough tests).

## Analysis Anti-Patterns

### 8. Surface-Level Scanning
**Problem**: Only checking for obvious issues (typos, missing semicolons) without tracing data flow or control flow for deeper bugs.
**Fix**: For security issues, trace user input from entry point through all transformations to output. For logic errors, mentally execute edge cases.

### 9. Single-File Blindness
**Problem**: Reviewing a file in isolation without considering how it interacts with the rest of the codebase.
**Fix**: Consider the call chain — who calls this function? What data flows into it? What happens with its output?

### 10. Assuming Framework Safety
**Problem**: Trusting that the framework prevents all security issues (e.g., "React prevents XSS" — but `dangerouslySetInnerHTML` bypasses this).
**Fix**: Know the escape hatches in common frameworks and check for their misuse.

### 11. Ignoring Error Paths
**Problem**: Only reviewing the happy path. Errors, timeouts, and partial failures are where most bugs live.
**Fix**: For each function, ask: "What happens when this fails? What happens with null/undefined input? What happens on timeout?"

### 12. False Positive Flooding
**Problem**: Reporting issues that aren't actually problems, eroding trust in the review process.
**Fix**: Verify each finding before reporting. If unsure, mark as "Potential issue — verify in context" with Info severity.

## Output Anti-Patterns

### 13. No Prioritization
**Problem**: Presenting all findings in a flat list with no ordering. The developer doesn't know where to start.
**Fix**: Always group by severity (Critical → High → Medium → Low → Info) and provide a "Top 3 action items" summary.

### 14. Fix Without Explanation
**Problem**: Saying "change X to Y" without explaining why. The developer makes the change but doesn't understand the vulnerability, leading to recurrence.
**Fix**: Every fix suggestion should include a one-sentence explanation of WHY the original code is problematic.

### 15. Missing Overall Assessment
**Problem**: Only listing individual findings without a holistic quality assessment. The developer doesn't know if the code is "mostly good with minor issues" or "fundamentally problematic."
**Fix**: Always include an overall health summary scoring security, performance, maintainability, and reliability.
