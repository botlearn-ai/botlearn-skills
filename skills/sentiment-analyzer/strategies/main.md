---
strategy: sentiment-analyzer
version: 1.0.0
steps: 6
---

# Sentiment Analysis Strategy

## Step 1: Segmentation
- Receive the input text and determine its scope: single sentence, paragraph, multi-paragraph document, or structured data (e.g., review with star rating)
- Detect the text **domain** using vocabulary and structural cues:
  - Product review → look for product terms, star ratings, pros/cons structure
  - Social media → short text, emoji, hashtags, informal language, slang
  - News/editorial → formal structure, quotations, byline
  - Technical/academic → hedged language, citations, formal tone
- Segment the text into analyzable units:
  - Split into sentences using punctuation and structural boundaries
  - Within sentences, split on contrastive conjunctions (`but`, `however`, `although`, `yet`, `while`, `on the other hand`) into clauses
  - IF the text contains bullet points, numbered lists, or structured sections THEN treat each item as a separate unit
- Record metadata: total sentence count, detected domain, text register (formal/informal), presence of ratings or structured signals

## Step 2: Aspect Identification
- For each sentence/clause, extract **opinion targets** (aspects):
  - **Explicit aspects**: Noun phrases that are the subject of opinion expressions ("the battery life", "customer support", "build quality")
  - **Implicit aspects**: Infer from adjectives or properties without a named target ("too heavy" → WEIGHT aspect, "overpriced" → PRICE aspect, "slow" → PERFORMANCE aspect)
  - **Composite aspects**: Multi-word targets that should not be split ("noise cancellation", "user interface", "customer service")
- Categorize each aspect into a domain-appropriate category using the taxonomy in knowledge/domain.md
- IF no aspects are identified THEN treat the entire sentence as a single-aspect unit targeting the overall subject
- IF the text mentions multiple entities (e.g., comparing products) THEN tag each aspect with its entity to prevent misattribution
- Build an **aspect inventory**: list all unique aspects found across the document with their source sentences

## Step 3: Sentiment Cue Detection
- For each clause/aspect pair, identify all sentiment-bearing expressions:
  - **Sentiment words**: Adjectives ("excellent", "terrible"), adverbs ("poorly", "beautifully"), verbs ("love", "hate", "enjoy", "struggle"), nouns ("disaster", "delight", "nightmare")
  - **Phrases and idioms**: "fell short of expectations", "blew me away", "left a lot to be desired", "hit it out of the park"
  - **Comparative expressions**: "better than", "worse than", "not as good as", "far superior to"
  - **Emoji and emoticons**: Map to sentiment scores using knowledge/domain.md lexicon entries
- Detect all **valence shifters** in scope:
  - **Negation markers**: not, no, never, neither, hardly, barely, nobody, nothing, un-, in-, im-, dis-, -less
  - **Intensifiers**: very, extremely, incredibly, absolutely, utterly, remarkably, thoroughly, deeply
  - **Diminishers**: somewhat, slightly, a bit, fairly, kind of, sort of, rather, marginally
  - **Irrealis markers**: if, would, could, might, wish, hope, should (indicates hypothetical, not asserted sentiment)
- Determine **negation scope**: negation applies to the next sentiment expression within the same clause; conjunction boundaries and clause boundaries terminate scope
- IF a sentiment word appears but has no clear aspect target THEN check previous sentences for aspect continuity via coreference ("The laptop... It... This device...")

## Step 4: Polarity Classification
- For each aspect-sentiment pair, compute the polarity score:
  1. Start with the **base polarity** of the sentiment expression (from lexicon or contextual analysis)
  2. Apply **domain calibration** — adjust the base score if the word has domain-specific sentiment (see knowledge/domain.md domain-specific adjustments)
  3. Apply **valence shifters** in order:
     - Negation: multiply by -0.8 to -1.0 (not full inversion for nuanced negation like "not bad")
     - Intensifiers: multiply magnitude by 1.25-1.5x
     - Diminishers: multiply magnitude by 0.5-0.75x
     - Double negation: result is weakly positive ("not uncommon" ≈ +0.2 to +0.3)
  4. Apply **irrealis discount**: IF the sentiment is hypothetical/conditional THEN reduce confidence by 0.20 and tag as "non-asserted"
- Map the final score to the 7-point polarity label using the scale in knowledge/domain.md
- IF sarcasm indicators are present (see Step 3 and knowledge/best-practices.md):
  - Check for incongruity: positive words + negative context, or hyperbole + complaint pattern
  - IF sarcasm is confirmed THEN invert polarity and apply confidence penalty (see Step 5)
  - IF sarcasm is uncertain THEN report BOTH literal and inverted interpretations

## Step 5: Confidence Assessment
- Assign a confidence score (0.00 - 1.00) to each aspect-level sentiment based on signal strength:
  - **Start at 0.85** as baseline for clear, unambiguous sentiment
  - **Adjust upward** (+0.05 to +0.15):
    - Multiple reinforcing sentiment cues for the same aspect
    - Star rating aligns with textual sentiment
    - Strong intensifiers with clear targets
  - **Adjust downward** (-0.05 to -0.25):
    - Short text (< 10 words): -0.10
    - No explicit sentiment words (relying on implicit): -0.15
    - Sarcasm detected but uncertain: -0.15 to -0.25
    - Domain uncertain: -0.10
    - Hedging language present: -0.10
    - Conflicting signals within the same aspect: -0.15
- Cap confidence at 1.00 and floor at 0.30
- SELF-CHECK against knowledge/anti-patterns.md:
  - Is any neutral label assigned with confidence > 0.85? → Verify the text is genuinely factual
  - Is any sentiment assigned without an identified aspect? → Reassign to an aspect or flag
  - Has negation been properly accounted for in every case?
  - Has the domain calibration been applied?

## Step 6: Aggregation & Output
- **Aspect-level output**: For each aspect, output the structured tuple:
  ```
  Aspect: [aspect_term] ([category])
  Polarity: [label] ([score])
  Opinion Expression: "[quoted text from source]"
  Valence Shifters: [list or "none"]
  Sarcasm: [detected/not detected/uncertain]
  Confidence: [0.00-1.00]
  ```
- **Sentence-level aggregation**: For sentences with multiple aspects:
  - IF all aspects agree in polarity THEN sentence polarity = the shared direction with averaged magnitude
  - IF aspects disagree THEN sentence polarity = "mixed" with the dominant direction noted
- **Document-level aggregation**: Compute overall sentiment using weighted rollup:
  1. Weight aspects by **importance** (core domain aspects weigh 1.5x; peripheral aspects weigh 0.75x)
  2. Weight by **position** (concluding sentences weigh 1.25x)
  3. Weight by **emphasis** (intensified sentiments weigh 1.15x)
  4. IF explicit summary phrases exist ("overall", "in summary", "all in all") THEN anchor document sentiment to those phrases
  5. IF sentiment is mixed across aspects THEN label document as "mixed" with a breakdown, NOT an averaged neutral
- **Final output**: Produce the complete structured sentiment report following the format in knowledge/best-practices.md:
  - Document-level summary with polarity, confidence, and dominant emotion
  - Aspect-level detail table
  - Flags: sarcasm, mixed sentiment, domain, low-confidence aspects
- SELF-CHECK the complete output:
  - Does the document-level sentiment coherently represent the aspect-level findings?
  - Are all flagged anti-patterns from knowledge/anti-patterns.md avoided?
  - Is every sentiment anchored to a specific aspect or entity?
  - IF any check fails THEN loop back to the relevant step and reprocess
