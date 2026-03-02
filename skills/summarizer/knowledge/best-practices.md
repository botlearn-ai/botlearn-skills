---
domain: summarizer
topic: extractive-abstractive-techniques-and-detail-preservation
priority: high
ttl: 30d
---

# Content Summarization — Best Practices

## Extractive vs. Abstractive Summarization

### Extractive Summarization
Selects and assembles existing sentences or phrases from the source without modification.

**When to use extractive**:
- Legal, medical, or regulatory documents where precise wording carries meaning
- When the user explicitly requests "in the author's own words"
- When quantitative data is dense and paraphrasing risks numerical errors
- For attributing specific claims — direct quotes preserve accountability

**Technique**:
1. Score each sentence by information density (see knowledge/domain.md)
2. Select top-N sentences by density score, preserving document order
3. Add minimal connective tissue between extracted sentences for readability
4. Indicate extracted passages with source markers (e.g., [para 3], [section 2.1])

### Abstractive Summarization
Generates new sentences that capture the meaning of the source in compressed form.

**When to use abstractive**:
- General-purpose summaries where readability is the priority
- When compression ratio exceeds 5:1 (extractive becomes choppy at high compression)
- When synthesizing multiple documents into a unified summary
- When the source is poorly written and extraction would perpetuate unclear language

**Technique**:
1. Build an argument map (see knowledge/domain.md) to capture logical structure
2. Rewrite each branch of the argument map as a concise statement
3. Verify every factual claim in the rewritten text against the source
4. Flag any inference you made that goes beyond the source material

### Hybrid Approach (Recommended Default)
Combine extractive and abstractive methods for optimal accuracy and readability:
- **Abstractive** for narrative flow, transitions, and structural framing
- **Extractive** for quantitative data, direct quotes, and precise technical claims
- Mark the boundary: use quotation marks or source markers for extracted content

## Detail Preservation Framework

### Tier 1 — Must Preserve (Never Omit)
These details, if present in the source, must appear in any summary regardless of length:
- **Central thesis or conclusion** — The main point of the document
- **Quantitative results** — Key numbers, percentages, financial figures, dates
- **Named entities driving the narrative** — People, organizations, products central to the argument
- **Causal claims with evidence** — "X caused Y" where Y is a significant outcome
- **Contradictions or caveats** — If the source acknowledges limitations, the summary must too

### Tier 2 — Preserve When Space Permits
- Supporting examples (keep the strongest one per claim)
- Methodological details (sample size, data sources, time period)
- Secondary claims that reinforce but do not introduce new information
- Historical context that frames the current discussion

### Tier 3 — Safe to Omit
- Repeated examples after the first strong one
- Author biography or credentials (unless relevant to credibility assessment)
- Acknowledgments, funding disclosures, boilerplate
- Detailed literature reviews (summarize as "building on prior work by [key names]")

## Multi-Document Summarization

When summarizing across multiple sources, additional practices apply:

### 1. Claim Reconciliation
- Identify claims that appear across multiple sources → strengthen confidence
- Identify contradictory claims → present both with attribution
- Identify claims unique to a single source → note as "according to [source]"

### 2. Overlap Deduplication
- When multiple sources state the same fact, consolidate into one statement
- Cite the most authoritative source for the consolidated claim
- Note the number of corroborating sources if relevant (e.g., "confirmed by 3 independent studies")

### 3. Gap Analysis
- After merging, check: are there aspects of the topic that no source covers?
- Flag gaps explicitly: "None of the sources address [aspect]"
- This prevents the user from assuming comprehensive coverage when gaps exist

### 4. Synthesis Structure
For multi-document summaries, organize by theme rather than by source:

```
Theme A
├── Source 1 finding
├── Source 2 finding (corroborates)
└── Source 3 finding (contradicts — note discrepancy)

Theme B
├── Source 1 finding (only source)
└── [Gap: not addressed by other sources]
```

## Compression Ratio Guidelines

| User Request | Target Ratio | Strategy |
|-------------|-------------|----------|
| "TLDR" / "one-liner" | 20:1 or higher | Central thesis + single most important finding |
| "Key points" / "brief summary" | 10:1 | Thesis + top 3-5 claims with headline evidence |
| "Summary" (default) | 5:1 | Full argument map preserved; Tier 1 + select Tier 2 details |
| "Detailed summary" | 3:1 | All Tier 1 + Tier 2 details; methodology included |
| "Executive briefing" | 5:1 | Thesis + implications + recommended actions; omit methodology |

## Output Formatting Best Practices

### For Structured Output
- Lead with a one-sentence thesis summary
- Use bullet points for key findings (one bullet per claim)
- Group related findings under thematic headings
- End with implications or open questions

### For Prose Output
- Open with the central finding or conclusion (inverted pyramid)
- Support with evidence in descending order of importance
- Close with caveats, limitations, or open questions
- Keep paragraphs to 3-4 sentences maximum

### Source Traceability
- Annotate key claims with source references: [Source: section/paragraph]
- For multi-document summaries, attribute each claim to its source
- This enables the user to verify any claim against the original material
