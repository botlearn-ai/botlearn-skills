---
domain: sentiment-analyzer
topic: anti-patterns
priority: medium
ttl: 30d
---

# Sentiment Analysis — Anti-Patterns

## Polarity Classification Anti-Patterns

### 1. Binary Sentiment Trap
- **Problem**: Reducing all sentiment to just positive or negative, losing nuance and gradation
- **Fix**: Always use a fine-grained scale (7-point: strongly negative through strongly positive). "Okay" is not positive. "Not terrible" is not the same as "good". Capture the full spectrum including slightly positive/negative and neutral.

### 2. Ignoring Negation and Valence Shifters
- **Problem**: Treating "not good" as positive because "good" is in the sentiment lexicon, or ignoring "barely", "hardly", "never" as modifiers
- **Fix**: Always parse for negation markers (not, no, never, neither, un-, in-, -less) BEFORE assigning polarity. Apply negation scope rules: negation inverts the next sentiment expression within the same clause. Process valence shifters in order: negation first, then intensifiers/diminishers.

### 3. Ignoring Intensifiers and Diminishers
- **Problem**: Treating "excellent" and "somewhat good" as the same strength of positive sentiment
- **Fix**: Apply intensity multipliers. Intensifiers (very, extremely, incredibly) amplify by 1.25-1.5x. Diminishers (somewhat, slightly, a bit) reduce by 0.5-0.75x. Stack multipliers when multiple modifiers are present ("really very good" = double intensification).

### 4. Context-Free Lexicon Lookup
- **Problem**: Assigning fixed sentiment scores from a general lexicon without considering domain context. "Sick" is negative in health context but positive in slang ("that's sick!").
- **Fix**: Detect the text domain first. Apply domain-specific sentiment adjustments. Maintain override lists for domain-dependent terms. When domain is uncertain, flag the term and provide both interpretations.

### 5. Averaging Away Mixed Sentiment
- **Problem**: A review that says "Amazing camera but horrible battery" gets averaged to "neutral", losing the actionable insight that two distinct aspects have opposite sentiments
- **Fix**: Report aspect-level sentiments separately. Document-level should be labeled "mixed" rather than averaged to neutral. Always preserve the aspect-level detail that reveals what specifically is positive or negative.

## Sarcasm and Irony Anti-Patterns

### 6. Missing Sarcasm and Irony
- **Problem**: Taking sarcastic statements at face value. "Great, another update that broke everything" is classified as positive because of "great"
- **Fix**: Check for incongruity between sentiment words and context (complaints, low ratings, negative events). Look for hyperbole, excessive punctuation, and known sarcasm markers. When sarcasm is detected, invert the polarity. Flag uncertainty when sarcasm detection is ambiguous.

### 7. Over-Detecting Sarcasm
- **Problem**: Flagging every positive statement in a negative context as sarcastic, even when the author is genuinely acknowledging a positive aspect
- **Fix**: Require multiple sarcasm signals before inverting. A single positive word in a negative review is not necessarily sarcastic ("The packaging was nice but the product was broken" — "nice" is genuine). Only invert when there is strong incongruity evidence (e.g., star rating contradicts text, extreme hyperbole).

### 8. Ignoring Quoted or Reported Sarcasm
- **Problem**: Treating sarcasm in reported speech the same as the author's own sarcasm. "My friend said 'oh how wonderful' when the flight was cancelled" — the author is reporting, not being sarcastic themselves.
- **Fix**: Identify the opinion holder. Apply sarcasm detection only to the expressed opinion of the correct holder. The author's sentiment about the reported sarcasm may differ from the sarcasm itself.

## Scope and Granularity Anti-Patterns

### 9. Sentence-Level Assumption
- **Problem**: Assuming each sentence has exactly one sentiment, when a single sentence can contain multiple aspects with different sentiments: "The food was delicious but overpriced"
- **Fix**: Perform clause-level or aspect-level analysis within sentences. Split on conjunctions (but, however, although, yet, while) that signal sentiment shifts. Each clause may have an independent polarity.

### 10. Ignoring Implicit Aspects
- **Problem**: Only extracting explicit aspect nouns ("battery", "screen") and missing implicit aspects. "It's too heavy" implies the WEIGHT aspect without naming it.
- **Fix**: Maintain an implicit aspect mapping: adjective/property to aspect category. "Heavy" maps to WEIGHT, "slow" maps to PERFORMANCE, "expensive" maps to PRICE. Train on domain-specific implicit aspect patterns.

### 11. Entity Confusion
- **Problem**: Misattributing sentiment to the wrong entity. "I returned the Samsung because the Apple was better" — sentiment toward Samsung is negative, Apple is positive, but a naive approach might reverse this.
- **Fix**: Parse sentence structure to correctly bind sentiment expressions to their targets using dependency parsing or proximity rules. Track entity mentions and their co-occurring sentiment expressions separately.

## Confidence and Output Anti-Patterns

### 12. Overconfident Neutral
- **Problem**: Assigning high confidence (>0.90) to "neutral" when the text is actually ambiguous, mixed, or contains sentiment that was not detected
- **Fix**: Reserve high-confidence neutral for genuinely objective/factual text ("The meeting is at 3 PM"). For ambiguous text, assign lower confidence neutral (0.40-0.60) and flag as "potentially ambiguous". Run a second pass specifically looking for implicit sentiment.

### 13. Ignoring Opinion Holder
- **Problem**: Treating all sentiment in a text as the author's opinion, even when some is reported speech, quotes, or hypothetical
- **Fix**: Distinguish between the author's own sentiment, reported sentiment from others, and hypothetical/conditional sentiment. Tag each opinion with its holder: author, quoted source, or hypothetical.

### 14. No Uncertainty Communication
- **Problem**: Always presenting a single definitive sentiment label without indicating when the analysis is uncertain or when multiple interpretations are plausible
- **Fix**: Always include confidence scores. When confidence is below 0.60, present multiple possible interpretations ranked by likelihood. Explicitly flag when sarcasm detection is uncertain, when domain is ambiguous, or when signals conflict.

### 15. Temporal Sentiment Blindness
- **Problem**: Ignoring how sentiment evolves within a text. A review might start positive ("I was excited to receive this") and end negative ("but after a week it completely fell apart"). The final sentiment matters most.
- **Fix**: Track sentiment trajectory across the document. Weight later sentences more heavily for document-level sentiment (recency bias aligns with the author's final judgment). Flag sentiment shifts and report them explicitly.

## Data Quality Anti-Patterns

### 16. Emoji and Emoticon Blindness
- **Problem**: Ignoring emoji or emoticons that carry significant sentiment signal, especially in social media and messaging
- **Fix**: Include emoji sentiment mappings in the lexicon. Common mappings: positive (thumbs up, heart, laughing, fire), negative (thumbs down, angry, crying, broken heart), sarcastic (eye-roll, upside-down smile). Emoji can override or reinforce textual sentiment.

### 17. Treating All Text Sources Equally
- **Problem**: Applying the same analysis parameters to a tweet, a product review, a news article, and a legal document
- **Fix**: Detect text source/register and adjust analysis accordingly. Tweets: expect abbreviations, emoji, hashtags. Product reviews: expect star ratings as anchors. News: distinguish editorial from reported content. Legal: formal negation, not sentiment-bearing.
