---
domain: summarizer
topic: discourse-structure-and-argument-mapping
priority: high
ttl: 30d
---

# Content Summarization — Discourse Types, Argument Mapping & Information Density

## Discourse Types

Understanding the discourse type of a source document is the foundation of effective summarization. Each type has a distinct internal structure that dictates where core information resides and how it should be compressed.

### 1. Argumentative Discourse
- **Structure**: Thesis → Supporting claims → Evidence → Counter-arguments → Conclusion
- **Key signal words**: "therefore", "however", "because", "despite", "in contrast", "evidence suggests"
- **Summarization focus**: Preserve the thesis, the strongest supporting claims, key evidence (especially quantitative), and any concessions or counter-arguments acknowledged by the author
- **Compression target**: Thesis and top 2-3 supporting claims with their strongest evidence

### 2. Expository Discourse
- **Structure**: Topic introduction → Categorical breakdown → Details per category → Synthesis
- **Key signal words**: "first", "second", "in addition", "for example", "such as", "specifically"
- **Summarization focus**: Preserve the categorical structure; for each category, retain the defining characteristic and one concrete example
- **Compression target**: Topic + category headings + key differentiator per category

### 3. Narrative Discourse
- **Structure**: Setting → Rising action → Climax → Falling action → Resolution
- **Key signal words**: "then", "next", "suddenly", "as a result", "finally", "meanwhile"
- **Summarization focus**: Preserve the causal chain — what happened, why, and what resulted; retain key actors and turning points
- **Compression target**: Who + initiating event + key turning points + outcome

### 4. Descriptive Discourse
- **Structure**: Overview → Feature-by-feature detail → Comparative context
- **Key signal words**: "characterized by", "consists of", "appears as", "resembles", "differs from"
- **Summarization focus**: Capture the entity's defining features and any comparative positioning; omit redundant descriptive detail
- **Compression target**: Entity + 3-5 distinguishing features + comparative positioning

### 5. Procedural Discourse
- **Structure**: Goal statement → Prerequisites → Sequential steps → Verification
- **Key signal words**: "first", "then", "next", "ensure that", "before", "after", "warning"
- **Summarization focus**: Preserve the goal, critical prerequisites, step order, and any warnings or failure conditions; minor sub-steps can be collapsed
- **Compression target**: Goal + prerequisites + collapsed step sequence + critical warnings

## Argument Mapping

Argument mapping is the process of identifying the logical structure within a document. This is critical for producing summaries that preserve the author's reasoning rather than just surface-level facts.

### Claim-Evidence Hierarchy

```
Central Thesis
├── Claim 1 (supports thesis)
│   ├── Evidence 1a (data, statistic, citation)
│   ├── Evidence 1b (example, case study)
│   └── Qualifier (conditions under which claim holds)
├── Claim 2 (supports thesis)
│   ├── Evidence 2a
│   └── Counter-evidence (acknowledged weakness)
├── Counter-Argument (opposing view)
│   ├── Evidence for counter-argument
│   └── Author's rebuttal
└── Conclusion (restated thesis + implications)
```

### Identifying Claims vs. Evidence

| Type | Characteristics | Examples |
|------|----------------|---------|
| **Claim** | Assertive, debatable, evaluative | "Remote work increases productivity", "Policy X is ineffective" |
| **Evidence** | Factual, verifiable, specific | "A 2024 Stanford study found 13% productivity increase", "$2.3 billion in losses" |
| **Qualifier** | Conditional, limiting scope | "In knowledge-work sectors", "When implemented with proper tooling" |
| **Warrant** | Implicit assumption linking evidence to claim | "Because productivity correlates with employee satisfaction" |

### Argument Strength Assessment

When multiple claims compete for inclusion in a summary, prioritize by argument strength:

1. **Strong**: Claim + multiple independent evidence sources + acknowledged qualifiers
2. **Moderate**: Claim + single evidence source or claim + logical reasoning without empirical data
3. **Weak**: Claim with no evidence, appeal to authority alone, or anecdotal support
4. **Contested**: Claim with counter-evidence presented — must include both sides

## Information Density Analysis

Not all sentences carry equal information value. Information density determines which content survives compression.

### High-Density Signals (Preserve)
- **Quantitative data**: Percentages, dollar amounts, dates, counts, measurements
  - Example: "Revenue grew 34% year-over-year to $4.2B in Q3 2024"
- **Proper nouns**: People, organizations, places, product names
  - Example: "CEO Maria Chen announced the partnership with Anthropic"
- **Causal relationships**: Explicit cause-effect statements
  - Example: "The tariff increase led to a 15% drop in imports within 6 months"
- **Novel claims**: Information the reader likely does not already know
  - Example: "Contrary to prior research, the study found no correlation between X and Y"
- **Definitions**: First introduction of a key term or concept
  - Example: "Retrieval-augmented generation (RAG) combines a retriever with a generator"

### Low-Density Signals (Compress or Remove)
- **Redundant restatements**: Same idea expressed in different words
- **Background context**: Common knowledge or widely known facts
- **Hedging language**: "It is important to note that", "One might argue"
- **Transitional padding**: "Having examined X, let us now turn to Y"
- **Excessive examples**: When one example suffices to illustrate a point, additional examples can be dropped

### Density Scoring Heuristic

For each sentence, assign a density score (0-3):
- **3**: Contains quantitative data + causal claim + proper noun
- **2**: Contains a novel claim or key evidence
- **1**: Provides context or elaboration on a higher-density sentence
- **0**: Transitional, redundant, or common knowledge

Sentences scoring 2-3 are primary candidates for summary inclusion. Sentences scoring 1 are included only if the summary length permits. Sentences scoring 0 are excluded.
