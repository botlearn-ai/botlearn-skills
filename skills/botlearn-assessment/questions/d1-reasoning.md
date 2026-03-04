---
dimension: D1
name: Reasoning & Planning
weight: 25%
questions: 3
benchmark: GAIA / Humanity's Last Exam (HLE)
---

# D1: Reasoning & Planning — Question Bank

> **Core probe**: Multi-step reasoning chains, analogical thinking, cross-domain inference.
> Reference benchmark: GAIA (Level 1–3) / Humanity's Last Exam (HLE)
>
> Present questions to the agent in the user's detected language.
> Score using the rubric below regardless of language.

---

## Q1-EASY | Reasoning Basics: Factual Inference Chain

**Difficulty**: Easy ×1.0

**Question**:

> DeepSeek-R1 was released in early 2025 and is positioned as a competitor to OpenAI o1 in reasoning capability.
> Given the following facts:
> (1) DeepSeek-R1's training cost is approximately 1/20 of GPT-4's;
> (2) It outscored GPT-4o on the AIME 2024 math competition;
> (3) It is an open-source model.
>
> Task: If a small-to-medium enterprise wants to deploy a locally-run, high-reasoning-capability model, what are the structural advantages and disadvantages of DeepSeek-R1 compared to a GPT-4 API solution?
>
> Requirements: List at least 3 advantages and 2 disadvantages, then provide a final recommendation.

**Scoring Rubric**:

| Criterion | Weight | Score 0 | Score 3 | Score 5 |
|-----------|--------|---------|---------|---------|
| Advantage identification | 35% | Fewer than 2 or severely wrong | 3 advantages, logic basically correct | 3+ advantages covering cost / open-source / local deployment as core points |
| Disadvantage identification | 25% | No disadvantages mentioned | 2 disadvantages basically accurate | 2+ disadvantages covering maintenance cost / ecosystem / service guarantees |
| Reasoning chain completeness | 25% | No logical derivation | Conclusions have basis but incomplete | Clear causal chain with point-by-point argumentation |
| Recommendation practicality | 15% | No recommendation or self-contradictory | Has recommendation but lacks conditional logic | Conditional recommendation distinguishing different company sizes |

**Full score**: 100 | **Verification**: 🧠 CoT self-judge

---

## Q2-MEDIUM | Advanced Reasoning: Multi-step Inference on Current Events

**Difficulty**: Medium ×1.2

**Question**:

> In 2025, Manus AI Agent achieved 86.5% on the GAIA benchmark (466 multi-step reasoning questions).
> Concurrently, OpenAI released GPT-5, achieving 74.9% on SWE-bench Verified.
>
> Questions:
> (1) Can GAIA 86.5% and SWE-bench 74.9% be directly compared to determine which system is "stronger"? Explain why or why not.
> (2) If you were an AI product manager choosing a foundation capability for "enterprise code review automation", which benchmark would you reference? Provide a 3-step decision framework.
> (3) Suppose a new Agent in 2026 reaches human-level performance on both benchmarks. What would this mean in practice?

**Scoring Rubric**:

| Criterion | Weight | Score 0 | Score 3 | Score 5 |
|-----------|--------|---------|---------|---------|
| Benchmark comparability analysis | 30% | Direct comparison or blanket refusal | Identifies different domains, cannot compare directly | Detailed explanation of evaluation dimension differences (task type / success definition / domain scope) |
| Decision framework quality | 35% | No framework or incoherent | 3-step framework with weak specificity | Framework covers: clarify use case → match benchmark type → validate with representative tasks |
| Future impact inference | 20% | Meaningless prediction | Mentions partial impacts | Covers labor market / code quality / security review processes at multiple levels |
| Argumentative rigor | 15% | No supporting evidence | Partial data support | Every conclusion has a traceable basis |

**Full score**: 100 | **Verification**: 🧠 CoT self-judge

---

## Q3-HARD | Reasoning Challenge: Cross-Domain Analogy and Boundary Inference

**Difficulty**: Hard ×1.5

**Question**:

> Background: In 2025's "Year of the AI Agent", Tool Chaining became a core capability for agents.
>
> Analogical reasoning task:
> In traditional software engineering, "microservices architecture" solved the maintainability problems of monolithic applications, at the cost of introducing network latency and service discovery complexity.
>
> Map this analogy onto AI Agent "Multi-Tool Orchestration":
> (1) What Agent design corresponds to the "monolithic application"?
> (2) What evolution corresponds to "microservices decomposition"?
> (3) What specific problems correspond to the microservices costs (latency, complexity) at the Agent level?
> (4) Do you think AI Agents will experience an "over-decomposition anti-pattern" similar to microservices? Provide your reasoning and a prevention strategy.

**Scoring Rubric**:

| Criterion | Weight | Score 0 | Score 3 | Score 5 |
|-----------|--------|---------|---------|---------|
| Analogy mapping accuracy | 40% | Wrong or meaningless mappings | First 3 mappings basically correct | All 4 mappings accurate with detail (including Tool Call overhead / context window fragmentation) |
| Anti-pattern recognition | 30% | Cannot identify or denies existence | Acknowledges possibility but no specifics | Clearly identifies over-tooling symptoms (tool call loops / context fragmentation / latency accumulation) |
| Prevention strategy practicality | 20% | No prevention strategy | Has strategy but too abstract | Concrete and actionable (e.g., tool merging heuristics / timeout circuit breaking / tool selection scoring) |
| Originality of thinking | 10% | Entirely restates common views | Has 1 novel observation | Presents at least 2 unique perspectives or counter-intuitive insights |

**Full score**: 100 | **Verification**: 🧠 CoT self-judge
