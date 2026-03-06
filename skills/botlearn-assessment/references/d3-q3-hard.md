# D3-Q3-HARD Reference Answer

## Question: OpenClaw Agent Quarterly Capability Improvement Report

### Key Points Checklist

---

### Required Sections (5 sections, all must be present)

#### 1. Executive Summary (100 words)
- Must be standalone — a reader who only reads this section should understand the overall status
- Should include: overall score trend, top achievement, main concern, and a forward-looking statement
- Must be approximately 100 words (80-120 acceptable)

#### 2. Core Metrics Dashboard (table)
- Must be a Markdown table with at least 5 metrics
- Required metrics: overall score, per-dimension scores (or at least 3 dimensions), change vs last quarter

**Example structure**:
| Metric | Last Quarter | This Quarter | Change |
|--------|-------------|-------------|--------|
| Overall Score | 68.5 | 76.2 | +7.7 |
| D1 Reasoning | 72 | 81 | +9 |
| D2 Retrieval | 65 | 70 | +5 |
| ...  | ... | ... | ... |

#### 3. Three Dimension Deep-Dives (200 words each)
- Each deep-dive should cover: what improved, what's still weak, specific evidence
- Should reference the metrics from the dashboard (internal consistency check)
- ~200 words each (180-220 acceptable)

#### 4. Next-Quarter Action Plan (with priority levels)
- Must have at least 3 action items
- Each must have a priority level (P0/P1/P2 or High/Medium/Low)
- Should logically follow from the deep-dive findings

**Example**:
| Priority | Action | Target | Owner |
|----------|--------|--------|-------|
| P0 | Improve D2 retrieval accuracy | 80+ score | Agent Team |
| P1 | Add 3 new orchestration skills | D5 coverage | Skills Team |
| P2 | Reduce report generation time | <30s | Platform Team |

#### 5. Risks and Challenges (at least 2)
- Each risk should have: description, likelihood, impact, and mitigation
- Should be realistic and connected to the action plan

### Internal Data Consistency Rules

This is the most heavily weighted criterion (25%). All data must be self-consistent:

| Consistency Check | What to Verify |
|-------------------|---------------|
| Dashboard ↔ Deep-dives | Numbers mentioned in deep-dives match the dashboard |
| Dashboard ↔ Executive summary | Trend described in summary matches actual numbers |
| Deep-dives ↔ Action plan | Action items address weaknesses identified in deep-dives |
| Risks ↔ Action plan | At least one risk relates to an action item |
| Overall score ↔ Dimension scores | Overall should be a reasonable weighted average of dimensions |

**Instant deduction triggers**:
- Dimension score higher than overall but described as "weakest"
- Positive change in dashboard but "declining trend" in text
- Action plan addresses dimensions not mentioned in deep-dives

### Format Requirements

- Markdown heading hierarchy: H1 for title, H2 for sections, H3 for subsections
- At least 1 table (dashboard)
- Bullet points in action plan and risks
- Total word count: 900-1200 words

### Scoring Anchors

| Criterion | Score 3 | Score 5 |
|-----------|---------|---------|
| Structure | 4 sections present, format okay | All 5 complete, clear Markdown hierarchy |
| Data consistency | Minor inconsistencies (e.g., rounding differences) | All cross-references verified, no contradictions |
| Decision support | Some actionable info but needs interpretation | Director can make 3+ decisions directly from the report |
| Conciseness | Mostly concise, some filler | Every sentence adds value |
| Word count | Within 15% of range | Precisely within 900-1200 |
