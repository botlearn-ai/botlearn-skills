---
domain: keyword-extractor
topic: multi-level-extraction-and-scoring
priority: high
ttl: 30d
---

# Keyword Extraction — Best Practices

## Multi-Level Extraction

### 1. Lexical Level (Surface Terms)
- Extract individual tokens after stopword removal and normalization
- Apply lemmatization to group inflected forms: "running", "runs", "ran" -> "run"
- Preserve case for proper nouns and acronyms: "API", "JavaScript", "NATO"
- Retain domain-specific compound terms: "machine-learning", "open-source"

### 2. Phrasal Level (Multi-Word Expressions)
- Extract n-grams (bigrams, trigrams) that co-occur more frequently than expected by chance
- Use Pointwise Mutual Information (PMI) to identify statistically significant phrases:
  - PMI(x, y) = log2(P(x, y) / (P(x) * P(y)))
  - PMI > 3.0 indicates a meaningful phrase
- Preserve noun phrases identified by POS patterns: ADJ* NOUN+ (e.g., "deep neural network")
- Named entities are automatically phrasal keywords — never split them

### 3. Semantic Level (Latent Concepts)
- Identify concepts implied but not explicitly stated
- Example: a text discussing "gradient descent", "loss function", and "epochs" implies the concept "model training"
- Use embedding similarity to surface these implicit topic markers
- Assign lower confidence scores to inferred concepts vs. explicit terms

## Contextual Scoring

### Composite Score Formula
```
Score(keyword) = w1*StatScore + w2*SemScore + w3*PosScore + w4*DomScore
```

| Component | Weight (w) | Description |
|-----------|-----------|-------------|
| StatScore | 0.30 | TF-IDF or BM25 statistical significance |
| SemScore  | 0.30 | Semantic centrality in the keyword graph |
| PosScore  | 0.20 | Positional weight (title > first paragraph > body > footnotes) |
| DomScore  | 0.20 | Domain relevance — how central is this term to the detected domain? |

### Positional Weight Table

| Position | Weight Multiplier | Rationale |
|----------|------------------|-----------|
| Title / Heading | 3.0x | Titles contain the most important terms |
| First paragraph / Abstract | 2.0x | Introductions state the core topic |
| Section headings | 2.5x | Sub-topics are signaled by headings |
| Body text | 1.0x | Baseline weight |
| Lists and enumerations | 1.5x | Structured content highlights key items |
| Captions and labels | 1.2x | Annotated content carries keyword signal |
| Footnotes and references | 0.5x | Supporting material, lower priority |

### Score Normalization
- Normalize final scores to 0-100 scale for readability
- Top keyword = 100; all others scaled proportionally
- Report scores rounded to 1 decimal place

## Cluster Formation

### Topic Cluster Construction
1. Compute pairwise semantic similarity between all extracted keywords
2. Apply agglomerative clustering with a similarity threshold of 0.65
3. Name each cluster using the highest-scoring keyword within the cluster
4. Limit cluster count based on text length (see knowledge/domain.md, Topic Modeling section)

### Cluster Quality Checks
- **Minimum size**: Clusters with only 1 keyword should be merged into the nearest cluster or flagged as standalone terms
- **Maximum size**: Clusters with 15+ keywords should be examined for sub-topic splitting
- **Coherence**: All keywords in a cluster should have pairwise similarity > 0.5; outliers should be reassigned
- **Coverage**: The union of all cluster keywords should cover at least 80% of the text's core content

### Cluster Hierarchy
- Support 2-level hierarchy: primary clusters (broad topics) and sub-clusters (specific aspects)
- Example:
  - Primary: "Machine Learning"
    - Sub-cluster: "Neural Networks" (deep learning, CNN, RNN, transformer)
    - Sub-cluster: "Training" (gradient descent, loss function, optimizer, epoch)
    - Sub-cluster: "Evaluation" (accuracy, F1, precision, recall, ROC)

## Optimal Keyword Count

| Text Length | Recommended Keywords | Max Topics |
|------------|---------------------|------------|
| < 200 words | 5-8 | 2-3 |
| 200-500 words | 8-12 | 3-5 |
| 500-1500 words | 12-20 | 4-7 |
| 1500-5000 words | 15-30 | 5-10 |
| 5000+ words | 20-40 | 7-12 |

### Primary vs. Secondary Keywords
- **Primary keywords** (top 30%): Directly represent the text's main thesis or topic — always include in output
- **Secondary keywords** (next 40%): Supporting concepts that elaborate on primary topics — include by default
- **Tertiary keywords** (bottom 30%): Peripheral or contextual terms — include only when comprehensive extraction is requested

## Output Format Best Practices

### Structured Output
Each keyword entry should include:
- **term**: The keyword or phrase
- **score**: Normalized relevance score (0-100)
- **level**: lexical / phrasal / semantic
- **cluster**: Topic cluster assignment
- **type**: entity type (if NER-detected) or "concept"
- **confidence**: Extraction confidence (high / medium / low)

### Grouping
- Present keywords grouped by cluster, not as a flat list
- Within each cluster, sort by score descending
- Provide a cluster summary sentence describing the sub-topic
