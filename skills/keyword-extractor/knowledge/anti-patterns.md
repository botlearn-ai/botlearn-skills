---
domain: keyword-extractor
topic: anti-patterns
priority: medium
ttl: 30d
---

# Keyword Extraction — Anti-Patterns

## Extraction Anti-Patterns

### 1. Surface-Only Extraction
- **Problem**: Extracting only explicitly stated words while ignoring implied concepts, synonyms, and latent topics
- **Symptom**: A text about "convolutional neural networks" yields keywords like "convolutional", "neural", "networks" but misses "deep learning", "image recognition", "computer vision"
- **Fix**: Apply semantic-level extraction using embeddings to discover implicit topic keywords; use topic modeling to surface latent themes; check that extracted keywords cover at least 80% of the text's identifiable topics

### 2. Frequency-Only Ranking
- **Problem**: Ranking keywords solely by how often they appear, causing common-but-generic terms to dominate
- **Symptom**: Words like "system", "data", "process", "method" rank highest even though they carry minimal topic-specific information
- **Fix**: Use TF-IDF or BM25 to discount terms that are frequent across many documents; apply the composite scoring formula from knowledge/best-practices.md that combines statistical, semantic, positional, and domain signals

### 3. Over-Extraction (Keyword Flooding)
- **Problem**: Extracting too many keywords, diluting the signal and overwhelming the consumer of the output
- **Symptom**: A 300-word paragraph produces 40+ keywords; every noun and adjective is treated as a keyword
- **Fix**: Apply the optimal keyword count guidelines from knowledge/best-practices.md; enforce primary/secondary/tertiary classification; default to outputting only primary + secondary keywords

### 4. Stopword Leakage
- **Problem**: Stopwords and function words slip through extraction and appear as keywords
- **Symptom**: Keywords include "the", "however", "various", "also", "including", "such"
- **Fix**: Apply comprehensive stopword filtering in preprocessing; extend standard stopword lists with domain-specific function words (e.g., "et al.", "respectively", "furthermore" in academic text)

### 5. Entity Fragmentation
- **Problem**: Multi-word named entities are split into individual tokens instead of being preserved as single keyword units
- **Symptom**: "United Nations" becomes two keywords: "United" and "Nations"; "New York Times" becomes "New", "York", "Times"
- **Fix**: Run NER before tokenization-based extraction; lock named entity spans as atomic units; apply multi-word expression detection using PMI thresholds

## Ranking Anti-Patterns

### 6. Ignoring Positional Signals
- **Problem**: Treating all keyword occurrences equally regardless of where they appear in the text
- **Symptom**: A term mentioned once in the title is scored lower than a term mentioned three times in footnotes
- **Fix**: Apply positional weight multipliers from knowledge/best-practices.md; title and heading terms receive 2-3x weight; footnote terms receive 0.5x

### 7. Flat Output (No Hierarchy)
- **Problem**: Returning keywords as an unstructured flat list with no grouping, ranking, or topic assignment
- **Symptom**: Output is a comma-separated list: "learning, neural, network, training, data, model, accuracy"
- **Fix**: Always cluster keywords into topic groups; rank within each cluster by score; provide cluster labels and hierarchical structure

### 8. Score Opacity
- **Problem**: Presenting keywords without explaining why they were selected or how they were scored
- **Symptom**: User receives a list of keywords with no scores, no confidence levels, and no extraction method attribution
- **Fix**: Include normalized scores (0-100), confidence levels (high/medium/low), and extraction level (lexical/phrasal/semantic) for each keyword

## Semantic Anti-Patterns

### 9. Synonym Duplication
- **Problem**: Treating synonyms and abbreviations as separate keywords, inflating keyword count without adding information
- **Symptom**: Output includes both "artificial intelligence" and "AI", both "natural language processing" and "NLP", both "machine learning" and "ML"
- **Fix**: Apply semantic deduplication using embedding similarity (threshold > 0.85); merge synonyms under the canonical (most frequent or most specific) form; note alternative forms as aliases

### 10. Over-Generalization
- **Problem**: Replacing specific, informative terms with vague parent categories during taxonomy mapping
- **Symptom**: "TensorFlow" is generalized to "software"; "BERT" becomes "language model"; "gradient descent" becomes "optimization"
- **Fix**: Preserve the original specific term as the keyword; use taxonomy categories only as metadata labels, not as replacements; never lose specificity in the primary keyword

### 11. Context-Blind Extraction
- **Problem**: Extracting keywords without considering the document's domain or the user's intent
- **Symptom**: A legal document's keyword list looks the same as a technical blog post's; domain-specific terms are not prioritized
- **Fix**: Detect the document domain in preprocessing; boost domain-specific terminology using DomScore; suppress cross-domain generic terms that are not informative within the detected domain

### 12. Negation Blindness
- **Problem**: Extracting keywords from negated or hypothetical statements as if they were affirmative
- **Symptom**: "This approach does NOT use reinforcement learning" produces "reinforcement learning" as a positive keyword
- **Fix**: Detect negation patterns ("not", "no", "without", "lacks", "unlike") and either exclude negated terms or flag them as "negated-context" keywords with reduced scores
