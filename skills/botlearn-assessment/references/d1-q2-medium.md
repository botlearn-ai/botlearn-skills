# D1-Q2-MEDIUM Reference Answer

## Question: GAIA 86.5% vs SWE-bench 74.9% — Benchmark Comparability & Decision Framework

### Key Points Checklist

---

### Part 1: Can GAIA and SWE-bench scores be directly compared?

**Answer: No.** A qualified answer must explain WHY, covering at least 3 of these differences:

1. **Task domain**: GAIA measures general multi-step reasoning across diverse domains (math, logic, fact-checking, web browsing). SWE-bench measures software engineering specifically (resolving real GitHub issues in real codebases).

2. **Success definition**: GAIA uses a multi-step accuracy metric (did the agent reach the correct final answer through valid intermediate steps). SWE-bench uses pass@1 — does the generated patch pass the repository's test suite.

3. **Task granularity**: GAIA has 466 questions across 3 difficulty levels. SWE-bench Verified has ~500 filtered real-world GitHub issues. The tasks differ fundamentally in structure — GAIA is question-answering, SWE-bench is code generation + patch application.

4. **Evaluation methodology**: GAIA is evaluated by answer correctness (often with human verification). SWE-bench is evaluated programmatically (test suite pass/fail) — more objective but narrower.

5. **Capability measured**: GAIA → breadth of reasoning + tool use. SWE-bench → depth of code understanding + modification in complex codebases.

**Common mistake**: Simply saying "different benchmarks can't be compared" without explaining the specific dimensional differences. This earns score 1-2, not 3-5.

### Part 2: Decision Framework for Enterprise Code Review Automation

A strong 3-step framework:

**Step 1 — Define the use case precisely**:
- Code review automation = understanding existing code + identifying issues + suggesting fixes
- This maps to code comprehension + generation + patch application
- Closest match: SWE-bench (code-level tasks in real repositories)

**Step 2 — Match benchmark type to capability requirements**:
- SWE-bench directly tests code modification in real repos → high relevance
- GAIA tests general reasoning → relevant for understanding complex logic but not directly code review
- Supplementary benchmarks: HumanEval (code generation), CodeContests (competitive programming)

**Step 3 — Validate with representative tasks**:
- Select 5-10 actual code review cases from your own codebase
- Run candidate models on these cases
- Compare against human reviewer decisions
- No benchmark fully replaces domain-specific evaluation

### Part 3: Human-Level Performance on Both Benchmarks — Practical Implications

Must cover at least 2 levels of impact:

1. **Labor market**: Software engineers' role shifts from writing code to reviewing AI-generated code. Code review becomes a human-AI collaboration, not replacement. New roles emerge: AI code auditor, prompt engineer for code generation.

2. **Code quality and reliability**: AI-generated patches that pass test suites don't guarantee correctness in untested edge cases. False confidence risk — passing tests != correct solution. Need for more comprehensive test suites becomes critical.

3. **Security review**: AI agents capable of human-level code modification could also discover/exploit vulnerabilities. Dual-use concern for security. Automated security scanning becomes mandatory alongside AI code generation.

4. **Development velocity**: Iteration cycles shorten dramatically. The bottleneck shifts from writing to specification, review, and testing.

### Scoring Anchors

| Criterion | Score 3 anchor | Score 5 anchor |
|-----------|---------------|---------------|
| Comparability analysis | "Different benchmarks, can't compare" with 1-2 reasons | Detailed breakdown of 3+ specific dimensional differences |
| Decision framework | 3 steps but generic (e.g., "evaluate, compare, decide") | Each step has specific actions tied to code review use case |
| Future impact | Mentions 1-2 surface impacts | Multi-level analysis covering labor + quality + security |
| Argumentative rigor | Some claims unsupported | Every conclusion traces to benchmark characteristics or industry evidence |
