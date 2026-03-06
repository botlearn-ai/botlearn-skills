# D2-Q3-HARD Reference Answer

## Question: Find AI Researcher Matching 4 Constraints

### Constraints Recap

1. Previously worked at Google Brain or DeepMind
2. Currently tenured university position (Associate Professor or above)
3. Published a paper on "LLM safety alignment" at NeurIPS/ICML/ICLR in 2024-2025
4. The first author is their student (not themselves)

### Search Strategy (Expected Multi-hop Path)

A strong answer should describe the search strategy even before presenting results:

**Hop 1**: Identify researchers who left Google Brain / DeepMind for academia
- Search: "Google Brain researcher joins university" / "DeepMind researcher professor"
- Cross-reference with known academic hires (2020-2024)
- Sources: university press releases, LinkedIn, Google Scholar profiles

**Hop 2**: Filter for tenured positions
- Check current university faculty pages for rank (Associate/Full Professor)
- Verify they hold tenure-track or tenured positions, not visiting/adjunct

**Hop 3**: Search for LLM safety alignment papers
- Search NeurIPS/ICML/ICLR 2024-2025 proceedings for "alignment" / "safety" / "RLHF" / "constitutional AI"
- Cross-reference paper author lists with candidates from Hop 1-2

**Hop 4**: Verify first author is a student
- Check first author's affiliation — should be same university, listed as PhD student/postdoc
- Verify via lab website or Google Scholar

### Candidate Examples

> Note: This is a real-world retrieval task. The exact answer depends on actual
> publications and career moves. The examiner should verify candidates independently.
> Below are plausible candidates based on known career trajectories.

**Plausible candidate pool** (researchers who left Google Brain/DeepMind for academia):

| Researcher | Former Role | Current Position | University |
|-----------|-------------|-----------------|------------|
| Jacob Steinhardt | Google Brain intern/researcher | Assistant → Associate Professor | UC Berkeley |
| Been Kim | Google Brain researcher | Professor | KAIST (as of 2024) |
| Percy Liang | Research connections with Google | Associate Professor | Stanford |
| Tengyu Ma | Google Brain researcher | Assistant Professor | Stanford |

**Evaluation approach**:
- The exact matching person may vary — what matters is the SEARCH METHODOLOGY
- A perfect match of all 4 constraints is genuinely difficult
- Providing 2 closest candidates with clear explanation of which constraints are unmet is acceptable for high scores

### Scoring Guide

| Criterion | Score 0 | Partial | Full Score |
|-----------|---------|---------|-----------|
| Full match (50%) | Fabricated person or wrong on 3+ constraints | 2-3 constraints matched | All 4 constraints verified |
| Information accuracy (30%) | Unverifiable claims | Most items checkable but 1-2 uncertain | Every claim has a verifiable source (paper URL, faculty page) |
| Search strategy (20%) | No strategy described | Partial (e.g., "I searched Google Scholar") | Full multi-hop path with reasoning at each step |

### Common Failure Modes

1. **Hallucination**: Inventing a researcher name or paper title that doesn't exist — should score 0 on accuracy
2. **Partial match without acknowledgment**: Claiming full match when only 2-3 constraints are met
3. **No search performed**: Answering from training data without attempting real-time search — if web search is unavailable, question should be SKIPPED
4. **Privacy concern**: If the agent refuses to name specific researchers for privacy reasons, this is NOT a valid reason to skip — all information is publicly available (published papers, public faculty pages)

### Acceptable "No Full Match" Answer

If no candidate satisfies all 4 constraints, a score of 35-45/50 (on the match criterion) is appropriate if the agent:
- Presents 2 closest candidates
- Clearly states which specific constraint each candidate fails
- Provides verifiable evidence for the constraints that ARE met
