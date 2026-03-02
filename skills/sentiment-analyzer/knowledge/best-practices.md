---
domain: sentiment-analyzer
topic: multi-level-analysis-and-calibration
priority: high
ttl: 30d
---

# Sentiment Analysis — Best Practices

## Multi-Level Analysis

### 1. Document-Level vs. Sentence-Level vs. Aspect-Level
Always analyze at the most granular level appropriate for the task, then aggregate upward:

- **Aspect-level** — Most granular: identifies sentiment toward specific features or entities
- **Sentence-level** — Each sentence gets an independent polarity label
- **Document-level** — Overall sentiment, aggregated from lower levels

**Aggregation rule**: Document sentiment is NOT simply the average of sentence sentiments. Weight by:
1. **Position** — Concluding sentences carry more weight (recency effect)
2. **Emphasis** — Sentences with intensifiers or exclamation carry more weight
3. **Aspect importance** — Core aspects (e.g., food in a restaurant review) weigh more than peripheral ones (e.g., parking)
4. **Explicit summary signals** — Phrases like "overall", "in summary", "all in all" anchor the document-level sentiment

### 2. Sentence-Level Analysis Pipeline
For each sentence:
1. Identify opinion targets (explicit or implicit aspects)
2. Locate sentiment expressions (adjectives, adverbs, verbs, phrases)
3. Detect valence shifters (negation, intensifiers, diminishers)
4. Compute modified polarity: `base_polarity * shifter_multiplier`
5. Assign confidence based on signal strength

### 3. Cross-Sentence Sentiment Flow
Sentiment can span multiple sentences:
- "The screen is gorgeous. Colors are vibrant and the resolution is sharp." — all three sentences express positive sentiment toward the DISPLAY aspect
- Track aspect continuity across sentences using coreference: "The laptop... It... This device..."
- Contrastive conjunctions signal sentiment shifts: "The food was great. However, the service was terrible."

## Sarcasm and Irony Detection

### Indicators of Sarcasm
Sarcasm detection requires looking beyond lexical sentiment. Key signals:

1. **Hyperbole** — Excessive praise or criticism that doesn't match context:
   - "Oh sure, waiting 3 hours for a table is just DELIGHTFUL"
2. **Incongruity** — Positive words in objectively negative situations:
   - "Love how my flight got cancelled for the third time this month"
3. **Punctuation patterns** — Ellipsis, excessive exclamation, quotes:
   - "The 'premium' service was truly... something"
4. **Contextual mismatch** — Sentiment contradicts known facts:
   - Rating: 1/5 stars. Text: "Best experience ever!"
5. **Universal quantifiers with negative context** — "Everything" + "perfect" when listing complaints:
   - "Everything about this product is absolutely perfect (if you enjoy things that break immediately)"
6. **Hashtags and tags** (social media): `#sarcasm`, `#not`, `/s`

### Sarcasm Handling Strategy
- IF sarcasm is detected THEN invert the surface sentiment polarity
- Assign lower confidence (0.60-0.75) to sarcasm-inverted sentiments since sarcasm detection is inherently uncertain
- Flag the output as sarcasm-detected so downstream consumers are aware
- When uncertain whether text is sarcastic, report BOTH literal and sarcastic interpretations with respective confidence scores

### Irony vs. Sarcasm
- **Sarcasm** — Intentionally saying the opposite of what is meant, usually to mock or criticize
- **Irony** — A broader concept where reality contradicts expectations (not always mocking)
- **Situational irony** in text: "The fire station burned down" — neutral/objective sentiment despite ironic content
- Only invert sentiment for **verbal irony/sarcasm**, not situational irony

## Domain Calibration

### Why Domain Matters
The same word carries different sentiment weight depending on context:

| Word | Product Reviews | Medical Text | Financial Text | Sports |
|------|----------------|-------------|----------------|--------|
| aggressive | -0.4 | -0.2 | +0.3 | +0.4 |
| stable | +0.3 | +0.6 | +0.5 | +0.1 |
| volatile | -0.5 | -0.3 | -0.6 | +0.2 |
| critical | -0.5 | -0.7 | -0.4 | +0.1 |
| positive | +0.5 | +0.8 | +0.6 | +0.3 |
| sharp | +0.3 | -0.3 | -0.4 | +0.4 |

### Domain Detection Heuristics
Before starting analysis, identify the text domain:
1. Check for domain-specific vocabulary (medical terms, financial jargon, product categories)
2. Identify the text source if available (Amazon review, tweet, news article, clinical note)
3. Look for structural cues (star ratings, review headings, formal structure)
4. Apply the appropriate domain-specific sentiment adjustments from the lexicon

### Calibration Rules
- **Product reviews** — Star ratings (if available) serve as ground truth anchors; calibrate text analysis to align with explicit ratings
- **Social media** — Short, informal, heavy slang/emoji usage; expand lexicon to include platform-specific terms
- **News articles** — More objective tone; distinguish between reported sentiment (what sources said) and editorial sentiment
- **Academic/technical text** — Hedged language is standard, not an indicator of negativity; "may", "could", "suggests" are neutral
- **Legal/regulatory text** — Formal negation patterns; "shall not" is a directive, not sentiment

## Confidence Scoring

### Calibrated Confidence Guidelines

| Signal Strength | Confidence Range | Example |
|----------------|-----------------|---------|
| Strong explicit + consistent | 0.90 - 1.00 | "Absolutely love it, best purchase ever!" |
| Clear sentiment, single aspect | 0.80 - 0.89 | "The battery life is disappointing" |
| Sentiment with hedging | 0.65 - 0.79 | "It seems fairly good, though I'm not sure yet" |
| Mixed/conflicting signals | 0.50 - 0.64 | "Great features but terrible reliability" |
| Sarcasm-inverted | 0.55 - 0.75 | "Oh wonderful, another crash" (detected as sarcasm) |
| Ambiguous/insufficient data | 0.30 - 0.49 | "It is what it is" |

### Confidence Penalties
Apply confidence reductions for:
- **Short text** (< 10 words): -0.10 (less context for disambiguation)
- **No explicit sentiment words**: -0.15 (relying on implicit sentiment)
- **Domain mismatch** (uncertain domain): -0.10
- **Sarcasm uncertainty**: -0.15 to -0.25
- **Multiple conflicting aspects**: -0.05 per conflicting pair (for document-level confidence only)

## Output Formatting

### Structured Sentiment Report
Always output in a structured format:

```
Document-Level Summary:
  Overall Polarity: [label] ([score])
  Confidence: [0.00 - 1.00]
  Dominant Emotion: [if applicable]

Aspect-Level Detail:
  [Aspect 1]:
    Polarity: [label] ([score])
    Opinion Expression: "[quoted text]"
    Valence Shifters: [none | negation | intensifier | diminisher]
    Confidence: [0.00 - 1.00]
  [Aspect 2]:
    ...

Flags:
  Sarcasm Detected: [yes/no]
  Mixed Sentiment: [yes/no]
  Domain: [detected domain]
  Low Confidence Aspects: [list]
```

### Handling Edge Cases
- **Purely factual text**: Label as "neutral/objective" with a note that no opinion was expressed
- **Mixed sentiment**: Report both the positive and negative aspects separately; document-level is "mixed" not an average
- **Non-English text**: Note the language limitation; apply analysis only if the language is within capability
- **Very short text** (< 5 words): Analyze but flag low confidence; avoid over-interpreting
