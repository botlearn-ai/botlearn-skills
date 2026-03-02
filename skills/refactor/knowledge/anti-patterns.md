---
domain: refactor
topic: refactoring-anti-patterns
priority: medium
ttl: 30d
---

# Code Refactoring — Anti-Patterns

## Planning Anti-Patterns

### 1. Big-Bang Refactor
- **Problem**: Attempting to refactor an entire module, class, or system in a single large change; rewriting from scratch under the guise of "refactoring"
- **Consequences**: Merge conflicts with ongoing feature work; impossible to isolate introduced bugs; no rollback point; multi-day or multi-week branches that diverge from main; high risk of abandonment
- **Fix**: Decompose into the smallest possible independent steps; each step modifies one structural element (one method, one class, one dependency); each step is a separate commit with passing tests; use the Strangler Fig pattern for large-scale migrations

### 2. Refactoring Without Tests
- **Problem**: Restructuring code that has no test coverage and writing no characterization tests before beginning
- **Consequences**: No safety net to detect behavioral changes; silent regressions discovered weeks later in production; loss of team confidence in the codebase
- **Fix**: Write characterization tests first — capture existing behavior as-is, even if the behavior seems incorrect; achieve at least 80% line coverage and 70% branch coverage on the target code before making any structural changes; if tests are impractical, use snapshot testing to record input/output pairs

### 3. Refactoring Without Measuring
- **Problem**: Performing refactoring based on gut feeling without measuring code quality before or after
- **Consequences**: No evidence that the refactoring improved anything; possible degradation disguised as improvement; no way to justify the investment to stakeholders
- **Fix**: Measure cyclomatic complexity, cognitive complexity, coupling, and duplication before starting; set explicit improvement targets; measure after completion; report the delta

### 4. Scope Creep Refactoring
- **Problem**: Starting with a focused refactoring target but continuously expanding scope as new issues are discovered ("while I'm here, I'll also fix this...")
- **Consequences**: Unbounded work; touching unrelated code increases risk; delays the original goal; makes the changeset unreviewable
- **Fix**: Define a strict boundary before starting; log discovered issues as separate tasks; complete the original scope first; address new issues in subsequent, independent refactoring sessions

## Execution Anti-Patterns

### 5. Premature Abstraction
- **Problem**: Introducing design patterns, abstract classes, or generic interfaces before there is concrete evidence of the need for extensibility — typically after seeing only 1 concrete case
- **Consequences**: Over-engineered code that is harder to understand than the original; abstractions that don't match actual variation points; increased indirection with no benefit; refactoring the refactoring later
- **Rule of Three**: Wait until you have 3 concrete instances of duplication or variation before introducing an abstraction; 2 instances are a coincidence, 3 are a pattern
- **Fix**: Start concrete, generalize only when variation is demonstrated; prefer duplication over the wrong abstraction

### 6. Pattern Fever
- **Problem**: Applying GoF design patterns because they are "good practices" rather than because they solve a specific identified problem in the code
- **Consequences**: Unnecessary complexity; explosion of small classes and interfaces that obscure simple logic; Factory patterns wrapping a single constructor; Strategy patterns with a single strategy; Observer patterns where a direct call suffices
- **Fix**: Every pattern application must reference a specific code smell it resolves; if you cannot name the smell, you do not need the pattern; after applying a pattern, verify that the code is easier to understand, not harder

### 7. Refactoring in Production Hotfix Branches
- **Problem**: Combining refactoring changes with bug fixes in the same commit or branch
- **Consequences**: Difficult to review — reviewer cannot separate intentional behavior changes (fix) from structural changes (refactoring); difficult to revert the fix without losing the refactoring or vice versa; increases hotfix risk
- **Fix**: Separate refactoring commits from fix commits completely; in hotfix scenarios, fix first, refactor later in a dedicated branch

### 8. Copy-Paste Refactoring
- **Problem**: "Refactoring" by duplicating code and modifying the copy instead of restructuring the original; creating a "v2" method alongside the original
- **Consequences**: Doubles the maintenance burden; the original is never removed; two diverging implementations of the same logic
- **Fix**: Use Extract Method/Class to share common logic; migrate callers incrementally to the new structure; remove the old code once all callers are migrated

## Design Anti-Patterns

### 9. Speculative Generalization in Refactoring
- **Problem**: Adding extension points, plugin architectures, or configuration options "in case we need them later" during a refactoring session
- **Consequences**: YAGNI violation; increased code surface area with no current users; maintenance cost for unused abstractions; the predicted future need often does not materialize or looks different than expected
- **Fix**: Refactor only to address current, concrete problems; optimize for readability and simplicity today; add extension points when an actual second use case arrives

### 10. Inheritance Over Composition
- **Problem**: Refactoring duplication by creating deep inheritance hierarchies instead of using composition and delegation
- **Consequences**: Fragile base class problem; tight coupling between parent and children; DIT (depth of inheritance tree) exceeds 3-4; Liskov Substitution violations; difficulty understanding behavior without reading the entire hierarchy
- **Fix**: Prefer composition and delegation; use interfaces to define contracts; extract shared behavior into composed helper objects rather than base classes; limit inheritance depth to 2-3 levels

### 11. Over-Decomposition
- **Problem**: Breaking code into extremely small methods (1-3 lines) or extremely small classes (single method) in pursuit of SRP purity
- **Consequences**: Reading the code requires following 15+ method calls to understand a single operation; debugger stepping becomes painful; the "where is the logic?" problem; increased indirection without improved clarity
- **Fix**: Methods should be small but semantically complete — a method should perform one complete thought, not one line of code; aim for 5-15 lines per method as a sweet spot; group closely related operations

### 12. Refactoring Toward the Wrong Abstraction
- **Problem**: Refactoring code to match a textbook pattern or architecture that does not fit the actual domain or usage patterns
- **Consequences**: Impedance mismatch between code structure and domain logic; forced workarounds; worse readability than the original
- **Fix**: Let the domain drive the abstraction; study how the code is actually used before choosing a target structure; validate the target design with concrete use cases before transforming

## Process Anti-Patterns

### 13. Solo Refactoring of Shared Code
- **Problem**: Refactoring heavily-used shared code (utilities, core libraries, data models) without consulting the team
- **Consequences**: Breaks other team members' work; merge conflicts across multiple branches; API changes that callers did not expect
- **Fix**: Discuss significant refactorings in code review or team standup before starting; for shared code, create a migration plan; deprecate old APIs before removing them; provide a migration guide

### 14. Refactoring Under Time Pressure
- **Problem**: Attempting significant refactoring during a release crunch, sprint end, or incident response
- **Consequences**: Incomplete refactoring committed under pressure; half-refactored code is worse than the original; increased risk of production incidents
- **Fix**: Time-box all refactoring; if the scope cannot fit the available time, defer it; never force-merge an incomplete refactoring

### 15. Ignoring Performance During Refactoring
- **Problem**: Assuming that any behavior-preserving transformation is also performance-preserving
- **Consequences**: Extract Method may cause additional function call overhead in hot loops; replacing direct access with getter chains may cause cache misses; introducing polymorphism where JIT was inlining direct calls
- **Fix**: Profile performance-critical code before and after refactoring; for hot paths, benchmark with realistic data; acceptable regression threshold: < 5% for hot paths, < 10% for non-critical paths
