---
strategy: code-review
version: 1.0.0
steps: 6
---

# Code Review Strategy

## Step 1: Context Identification
- Identify the **programming language**, **framework**, and **runtime environment**
- Determine the **deployment context** (public API, internal service, CLI tool, library)
- Note any **security-sensitive operations** (authentication, payment, PII handling)
- IF the code interacts with a database THEN prioritize SQL injection and N+1 query checks
- IF the code handles user input THEN prioritize injection and XSS checks
- IF the code is async THEN prioritize race condition and error handling checks

## Step 2: Security Scan (OWASP Top 10)
- Trace all **user input entry points** through the code to their usage
- Check for **injection vulnerabilities**: SQL, NoSQL, command, XSS, template injection
  - Look for string concatenation in queries, `eval()`, `exec()`, unescaped HTML rendering
- Check for **authentication/authorization**: missing auth checks, IDOR, privilege escalation
- Check for **cryptographic issues**: hardcoded secrets, weak hashing, missing encryption
- Check for **SSRF**: fetching user-provided URLs without validation
- Check for **deserialization**: untrusted data deserialized without validation
- Flag every security issue as **Critical** or **High** severity

## Step 3: Performance Analysis
- Scan for **N+1 query patterns**: loops containing database queries
- Check for **memory leaks**: unclosed resources, growing caches, orphaned listeners
- Identify **blocking operations** in async contexts: sync I/O, CPU-intensive loops on event loop
- Evaluate **algorithmic complexity**: look for O(n²) where O(n) or O(n log n) is feasible
- Check for **unnecessary allocations**: objects created in loops, redundant copies
- IF performance issues are in a hot path THEN classify as **High**, else **Medium**

## Step 4: Code Smell & Pattern Check
- Apply the code smell catalog from knowledge/domain.md:
  - **Long Method**: > 30 lines or > 4 nesting levels
  - **Large Class**: > 10 public methods or > 300 lines
  - **God Object**: single module handling unrelated responsibilities
  - **Feature Envy**: method using more data from another class
  - **Dead Code**: unreachable or unused code paths
- Check for **logic errors**: off-by-one, null handling, edge cases, boundary conditions
- Check for **naming**: misleading names, inconsistent conventions, abbreviations
- Check for **error handling**: swallowed exceptions, missing `catch`, no error recovery
- Apply knowledge/anti-patterns.md to verify review thoroughness

## Step 5: Issue Classification
- Assign **severity** to each finding using the classification from knowledge/best-practices.md:
  - **Critical**: Exploitable vulnerability, data loss risk → Must fix
  - **High**: Significant bug, security weakness, perf degradation → Should fix
  - **Medium**: Code smell, moderate perf issue → Fix in next iteration
  - **Low**: Improvement opportunity → Nice to have
  - **Info**: Observation, suggestion, praise → Optional
- Assign **confidence** level: Certain / Likely / Possible
- For each finding, prepare: location, issue description, impact, severity, fix suggestion

## Step 6: Report & Fix Suggestions
- Structure the output report:
  1. **Summary**: One-paragraph overall assessment
  2. **Health Scores**: Security (1-5), Performance (1-5), Maintainability (1-5), Reliability (1-5)
  3. **Critical/High Findings**: Listed first with full details and code fix examples
  4. **Medium Findings**: Listed with fix suggestions
  5. **Low/Info Findings**: Brief list (top 5-10 most impactful only)
  6. **Positive Observations**: 1-2 things done well
  7. **Action Items**: Top 3 prioritized next steps
- Every fix suggestion must include a **code example** showing before/after
- Every fix must include a **one-sentence explanation** of why the original is problematic
- SELF-CHECK:
  - Did I check all OWASP Top 10 categories?
  - Did I trace all user input paths?
  - Did I check error paths, not just happy paths?
  - Did I avoid the anti-patterns from knowledge/anti-patterns.md?
