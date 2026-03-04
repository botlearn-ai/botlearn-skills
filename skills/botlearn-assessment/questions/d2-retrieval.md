---
dimension: D2
name: Information Retrieval
weight: 22%
questions: 3
benchmark: BrowseComp (OpenAI) / DeepSearchQA (Google DeepMind) / GAIA Level 2
---

# D2: Information Retrieval — Question Bank

> **Core probe**: Precision retrieval from authoritative sources, multi-source synthesis, multi-hop constrained search.
> Reference: BrowseComp (answers are objectively unique, require multi-hop search, cannot be found on a first-page result).
>
> Present questions to the agent in the user's detected language.
> Score using the rubric below regardless of language.

---

## Q1-EASY | Retrieval Basics: Single-Source Precision Lookup

**Difficulty**: Easy ×1.0

**Question**:

> Using data from the BLS (Bureau of Labor Statistics) official website at bls.gov/cps/,
> what were the unemployment rates for "men aged 20 and over" and "women aged 20 and over" in June 2009?
> What is the difference in percentage points between the two?
>
> Requirements: Provide the specific page or table name as the data source.
> Answering from memory is not allowed.

**Scoring Rubric**:

| Criterion | Weight | Scoring Rule |
|-----------|--------|--------------|
| Numerical accuracy | 50% | Both numbers correct: 50 pts; only one correct: 20 pts; both wrong: 0 pts |
| Difference calculation | 20% | Correct difference: 20 pts; numbers correct but calculation wrong: 10 pts |
| Source citation | 30% | Specific table name or URL cited: 30 pts; only "BLS website": 10 pts; no citation: 0 pts |

**Full score**: 100 | **Verification**: 🔬 Programmatic (numbers verifiable)

> **Note**: If the agent lacks real-time search and relies on memory, expected score is 0–20 (numbers likely inaccurate or no source provided).

---

## Q2-MEDIUM | Advanced Retrieval: Multi-Source Synthesis and Comparison

**Difficulty**: Medium ×1.2

**Question**:

> You need to collect data for a "2025 Global Top AI Research Institutions" report:
>
> (1) According to the QS World University Rankings 2025, list the global top 5 universities in Computer Science (include country).
> (2) According to AI Index 2025 Report or Papers With Code, which of those 5 universities ranks highest in deep learning publication volume?
> (3) Synthesizing both dimensions, which institution would you recommend as the top priority partner for AI talent recruitment? Provide your reasoning.
>
> Requirements: Cite a source for each data point; conclusions must be derived from the data.

**Scoring Rubric**:

| Criterion | Weight | Score 0 | Score 3 | Score 5 |
|-----------|--------|---------|---------|---------|
| QS ranking accuracy | 30% | More than 3 wrong | 3–4 correct | All 5 correct |
| Publication data validity | 25% | No data or obviously wrong | Has data but source unclear | Source clearly identified and verifiable |
| Multi-source synthesis quality | 25% | Conclusion unrelated to data | Some synthesis but weak logic | Explicit weighting, clear reasoning chain |
| Source citation completeness | 20% | No citations | Partial citations | Every data point has a cited source |

**Full score**: 100 | **Verification**: 📖 Reference answer match

---

## Q3-HARD | Retrieval Challenge: Multi-hop Constrained Search (BrowseComp Style)

**Difficulty**: Hard ×1.5

**Question**:

> Find a real AI researcher who satisfies ALL of the following conditions:
> - Previously worked at Google Brain or DeepMind
> - Currently holds a tenured university position (Associate Professor or above)
> - Published a paper on "LLM safety alignment" at a top conference (NeurIPS / ICML / ICLR) in 2024 or 2025
> - The first author of that paper is one of their students (not themselves)
>
> Provide: the researcher's name, current position, paper title, and the student first author's name.
>
> If no fully matching case can be found, provide the 2 closest candidates and explain which conditions are missing.

**Scoring Rubric**:

| Criterion | Weight | Scoring Rule |
|-----------|--------|--------------|
| Full match | 50% | All 4 conditions satisfied: 50 pts; deduct 15 pts per missing condition |
| Information accuracy | 30% | Full score if every item is verifiable; deduct 10 pts per unverifiable item |
| Search strategy explanation | 20% | Multi-hop search path explained: 20 pts; partial explanation: 10 pts; none: 0 pts |

**Full score**: 100 | **Verification**: 📖+🧠 Mixed verification
