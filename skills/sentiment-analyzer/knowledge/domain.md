---
domain: sentiment-analyzer
topic: sentiment-polarity-and-opinion-mining
priority: high
ttl: 30d
---

# Sentiment Analysis — Polarity, ABSA, Opinion Mining & Valence Shifters

## Sentiment Polarity Scale

### Fine-Grained Polarity Levels
Sentiment is classified on a 7-point scale rather than a binary positive/negative split:

| Level | Label | Score Range | Example |
|-------|-------|-------------|---------|
| 7 | Strongly Positive | +0.75 to +1.00 | "Absolutely phenomenal — the best I've ever used" |
| 6 | Positive | +0.50 to +0.74 | "I really like this product, it works well" |
| 5 | Slightly Positive | +0.25 to +0.49 | "It's decent, does what it's supposed to" |
| 4 | Neutral | -0.24 to +0.24 | "The device weighs 200 grams and ships in a blue box" |
| 3 | Slightly Negative | -0.25 to -0.49 | "It's okay but nothing special" |
| 2 | Negative | -0.50 to -0.74 | "Disappointed — it broke after a week" |
| 1 | Strongly Negative | -0.75 to -1.00 | "Completely unusable, waste of money, worst purchase ever" |

### Polarity Signals
- **Lexical cues**: Sentiment-bearing words (e.g., "excellent", "terrible", "mediocre")
- **Syntactic patterns**: Comparative structures ("better than", "worse than"), superlatives ("the best", "the worst")
- **Pragmatic cues**: Exclamation marks, ALL CAPS, emoji, rhetorical questions
- **Contextual signals**: Domain-specific terms that carry sentiment only in context (e.g., "unpredictable" is negative for software, neutral for weather description)

## Aspect-Based Sentiment Analysis (ABSA)

### Core Components
ABSA decomposes a text into structured opinion tuples:

```
(aspect_term, aspect_category, sentiment_polarity, opinion_expression, confidence)
```

**Example**:
- Input: "The camera quality is stunning but the battery life is disappointing"
- Tuple 1: ("camera quality", QUALITY, positive, "stunning", 0.92)
- Tuple 2: ("battery life", PERFORMANCE, negative, "disappointing", 0.89)

### Aspect Extraction Methods
1. **Explicit aspects** — Directly mentioned noun phrases: "screen", "battery", "customer service"
2. **Implicit aspects** — Inferred from context: "It's too heavy" implies WEIGHT aspect without naming it
3. **Composite aspects** — Multi-word aspect terms: "noise cancellation", "build quality", "user interface"

### Common Aspect Categories

| Domain | Typical Aspect Categories |
|--------|--------------------------|
| Product Reviews | Quality, Price, Design, Performance, Durability, Usability, Customer Service |
| Restaurant Reviews | Food, Service, Ambiance, Price, Cleanliness, Location, Wait Time |
| Software Reviews | Functionality, Performance, UI/UX, Reliability, Documentation, Support, Pricing |
| Hotel Reviews | Room, Cleanliness, Location, Staff, Amenities, Value, Food |

### Aspect-Sentiment Pairing Rules
- Each aspect can have exactly one polarity (if a text says contradictory things about the same aspect, split into sub-aspects)
- Aspects without a clear sentiment expression are tagged as neutral with low confidence
- An opinion expression can modify multiple aspects: "Both the food and service were excellent"

## Opinion Mining Components

### Opinion Holder Identification
The entity expressing the opinion:
- **First-person**: "I think this is great" — opinion holder is the author
- **Reported speech**: "My colleague says the software is buggy" — opinion holder is the colleague
- **Impersonal**: "This product is considered reliable" — opinion holder is general consensus

### Opinion Expression Types
1. **Direct opinions** — Explicitly stated: "The battery life is excellent"
2. **Comparative opinions** — Relative judgments: "Camera A is better than Camera B"
3. **Suggestive opinions** — Implied through suggestions: "They should improve the packaging"
4. **Conditional opinions** — Dependent on context: "Great if you don't mind the weight"

### Opinion Strength Indicators
- **Intensifiers** (+): very, extremely, incredibly, absolutely, utterly, remarkably
- **Diminishers** (-): somewhat, slightly, a bit, fairly, kind of, sort of, rather
- **Modal hedges** (~): might be, could be, seems, appears to, arguably
- **Superlatives** (++): best, worst, most, least, greatest, finest

## Valence Shifters

Valence shifters are linguistic constructs that alter the base sentiment of a word or phrase.

### Negation
Negation inverts or significantly reduces the polarity of a sentiment expression:

| Negation Type | Examples | Effect |
|---------------|----------|--------|
| Simple negation | not, no, never, neither, nor | Inverts polarity |
| Morphological negation | un-, in-, im-, dis-, -less | Inverts polarity |
| Implicit negation | fail to, lack, absence of, devoid of | Inverts polarity |
| Double negation | "not uncommon", "not without merit" | Weakened positive (litotes) |
| Negation scope | "not only good but great" | Scope ends at "but" — positive |

### Negation Scope Rules
- Negation typically scopes over the **next sentiment-bearing word or phrase**
- Conjunctions (`but`, `however`, `although`) reset negation scope
- Clause boundaries terminate negation scope
- Example: "I don't think the camera is bad" — negation applies to "bad", result is weakly positive

### Intensifiers and Diminishers

**Intensifiers** amplify the existing polarity:
```
"very good"     → more positive than "good"
"very bad"      → more negative than "bad"
"absolutely terrible" → more negative than "terrible"
```

**Diminishers** reduce the magnitude of the existing polarity:
```
"somewhat good"  → less positive than "good"
"slightly bad"   → less negative than "bad"
"fairly decent"  → weakly positive
```

### Irrealis Markers
Words or constructions that indicate the sentiment is hypothetical, wished-for, or counterfactual rather than asserted:

| Marker Type | Examples | Effect |
|-------------|----------|--------|
| Conditional | "if it were better", "would be nice if" | Sentiment is hypothetical, not current |
| Subjunctive | "I wish it were faster" | Implies negative current state |
| Questions | "Is this any good?" | Uncertain — do not classify as asserted sentiment |
| Future/Hope | "hopefully it improves" | Implies negative current state, positive desired state |

## Sentiment Lexicons

### General-Purpose Lexicons
- **VADER** — Valence Aware Dictionary for social media, includes emoji and slang, scores -4 to +4
- **SentiWordNet** — Synset-level scores for WordNet entries (positivity, negativity, objectivity)
- **AFINN** — 2,477 words scored -5 to +5, good for short informal text
- **NRC Emotion Lexicon** — 14,182 words annotated for 8 emotions + positive/negative

### Domain-Specific Adjustments
Words change sentiment valence across domains:
- "unpredictable" — negative (software), neutral/positive (thriller novel), positive (sports)
- "aggressive" — negative (customer service), positive (investment strategy), neutral (medical treatment)
- "volatile" — negative (software), neutral (chemistry), negative (financial markets)
- "intense" — positive (workout), negative (headache), positive (flavor), neutral (light)

### Slang and Informal Expressions
Social media and informal text require expanded lexicons:
- "fire" / "lit" — strongly positive (slang)
- "salty" — negative (slang, meaning bitter or upset)
- "slaps" — strongly positive (slang, meaning excellent)
- "mid" — negative (slang, meaning mediocre)
- "/s" or "not" (sarcasm markers in online text)
