---
domain: summarizer
topic: anti-patterns
priority: medium
ttl: 30d
---

# Content Summarization — Anti-Patterns

## Detail Loss Anti-Patterns

### 1. Dropping Numbers and Dates
- **Problem**: Replacing specific quantitative data with vague language — e.g., summarizing "Revenue increased 34% to $4.2B in Q3 2024" as "Revenue increased significantly"
- **Impact**: The summary loses verifiability and decision-making value; "significantly" is subjective and unanchored
- **Fix**: Always carry forward key numbers, percentages, dates, and monetary values. If compression requires it, round numbers but never remove them. "$4.2B (up 34%, Q3 2024)" is acceptable compression; "revenue grew" is not

### 2. Stripping Proper Nouns
- **Problem**: Replacing named entities with generic references — e.g., "The company announced" instead of "Anthropic announced"
- **Impact**: Loses attribution and specificity; makes the summary ambiguous when multiple entities are discussed
- **Fix**: Retain proper nouns for all entities central to the argument. Generic references are only acceptable for minor entities mentioned in passing

### 3. Losing Temporal Context
- **Problem**: Omitting dates, time periods, or temporal qualifiers — e.g., "The study found correlation" instead of "A 2024 longitudinal study spanning 5 years found correlation"
- **Impact**: The reader cannot assess recency or relevance; conflates historical and current findings
- **Fix**: Include the year and study duration for research findings; include dates for events; include version numbers for technology

## Structural Anti-Patterns

### 4. Over-Generalization
- **Problem**: Collapsing specific, differentiated claims into a single vague statement — e.g., summarizing three distinct policy recommendations as "Several recommendations were made"
- **Impact**: Destroys the actionable specificity that makes the source valuable
- **Fix**: If the source lists N specific items and the summary can only fit M < N, select the M most important by impact or novelty and state them explicitly. Never replace a list with "several" or "various"

### 5. Position Bias (Lead Bias)
- **Problem**: Over-representing content from the beginning of the document and under-representing content from the middle or end
- **Impact**: Conclusions, counter-arguments, and caveats (which typically appear later) are systematically omitted, producing a misleadingly one-sided summary
- **Fix**: Scan the entire document before summarizing. Use argument mapping to identify structurally important content regardless of position. Explicitly check: "Does my summary include content from the final third of the document?"

### 6. Recency Bias (Tail Bias)
- **Problem**: The opposite of lead bias — over-representing the most recently read content because it is freshest in memory
- **Impact**: The opening thesis and early evidence are underweighted
- **Fix**: Build the argument map before writing the summary. Work from the map, not from memory of the reading order

### 7. Flattening Argument Structure
- **Problem**: Presenting all claims at the same level, losing the hierarchical relationship between main arguments and supporting evidence
- **Impact**: The reader cannot distinguish the central thesis from supporting details; the summary reads as a list of disconnected facts
- **Fix**: Use the claim-evidence hierarchy from knowledge/domain.md. Lead with the thesis, support with top-level claims, and use indentation or explicit markers to show evidence supporting each claim

## Accuracy Anti-Patterns

### 8. Inference Injection
- **Problem**: Adding conclusions or causal claims that the source does not make — e.g., the source says "X and Y are correlated" but the summary says "X causes Y"
- **Impact**: The summary makes stronger claims than the source, potentially misleading the reader
- **Fix**: Preserve the source's hedging language. If the source says "suggests", "may", "correlates with", do not upgrade to "proves", "will", "causes". If you catch yourself adding a causal word not in the source, flag it

### 9. Misattribution
- **Problem**: Attributing a claim to the wrong entity — e.g., attributing a critic's objection to the author, or attributing one researcher's finding to another
- **Impact**: Fundamentally changes the meaning; can misrepresent positions in a debate
- **Fix**: When the source contains multiple voices or perspectives, track attribution explicitly in the argument map. Verify each claim-attribution pair before including in the summary

### 10. False Equivalence in Multi-Document Summaries
- **Problem**: Giving equal weight to a well-evidenced majority view and a poorly supported minority view, or vice versa
- **Impact**: Distorts the landscape of expert consensus; can give fringe positions undue prominence
- **Fix**: Weight claims by evidence quality (see argument strength in knowledge/domain.md). If 8 sources agree and 1 disagrees, state the consensus and note the dissent — do not present them as equally supported

## Output Anti-Patterns

### 11. Wall-of-Text Summaries
- **Problem**: Producing a summary as a single dense paragraph with no structural markers
- **Impact**: Defeats the purpose of summarization; the reader must re-read to find specific points
- **Fix**: Use structural formatting — bullet points, numbered lists, or short paragraphs with clear topic sentences. Match the output structure to the user's likely use case (scanning vs. reading)

### 12. Summary Longer Than Necessary
- **Problem**: Including filler phrases ("It is worth noting that", "In conclusion, it can be said that") or restating the same point in multiple ways
- **Impact**: Inflates the summary length without adding information; wastes the reader's time
- **Fix**: After drafting, apply a self-edit pass: can any sentence be removed without losing information? If yes, remove it. Target zero-filler summaries
