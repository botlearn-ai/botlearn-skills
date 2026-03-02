---
domain: rewriter
topic: anti-patterns
priority: medium
ttl: 30d
---

# Content Rewriting — Anti-Patterns

## Sentence-Level Anti-Patterns

### 1. Uniform Sentence Length
- **Problem**: AI-generated rewrites often produce sentences of near-identical length (15-20 words), creating a metronomic rhythm that human readers and detection tools both flag
- **Detection signal**: Standard deviation of sentence word counts < 4 across a paragraph
- **Fix**: Deliberately vary sentence length. Follow a 25-word sentence with a 6-word one. Break or combine sentences until the standard deviation exceeds 6. Short hits. Then stretch out with something more complex that winds through a subordinate clause before arriving at its point.

### 2. Predictable Sentence Openers
- **Problem**: Starting 3+ consecutive sentences with "The," "This," "It," or a subject-verb pattern; AI text is notorious for "The [noun] [verb]" repetition
- **Detection signal**: More than 30% of sentences in a passage begin with the same word or part of speech
- **Fix**: Rotate openers across prepositional phrases, adverbs, participial phrases, dependent clauses, and inverted structures (see knowledge/best-practices.md, Section 6)

### 3. Parallel Construction Overuse
- **Problem**: Rewriting every item in a list or series using identical grammatical structure ("X enables Y. X facilitates Z. X promotes W."). Human writers use parallelism selectively, not exhaustively.
- **Detection signal**: Three or more consecutive sentences with identical syntactic templates
- **Fix**: Break the pattern — vary one item's structure, embed one as a subordinate clause, or merge two items into a compound sentence

## Word-Choice Anti-Patterns

### 4. AI-Tell Vocabulary
- **Problem**: Certain words and phrases appear with disproportionate frequency in AI-generated text, creating a recognizable statistical fingerprint
- **High-frequency AI tells to avoid or minimize**:
  - "delve" / "delve into" — rarely used in natural human writing
  - "landscape" (metaphorical: "the AI landscape") — overused as a framing device
  - "navigate" (metaphorical: "navigate the complexities") — AI default for "deal with"
  - "nuanced" / "nuances" — AI hedging word for acknowledging complexity
  - "multifaceted" — AI synonym for "complex"
  - "pivotal" — AI intensifier, rarely chosen by humans naturally
  - "foster" (as in "foster innovation") — formal/corporate AI default
  - "underscores" — AI attribution verb ("This underscores the importance of...")
  - "realm" — AI metaphor for "area" or "field"
  - "tapestry" — AI metaphor for "mix" or "combination"
  - "leverage" (verb) — corporate AI default for "use"
  - "robust" — AI adjective for "strong" or "thorough"
  - "comprehensive" — AI filler adjective
  - "cutting-edge" — AI default for "new" or "advanced"
- **Fix**: Replace with less predictable alternatives or restructure to eliminate the need for the word entirely. "Delve into the nuances" -> "look more closely at the details" or simply get specific about which details.

### 5. Over-Hedging
- **Problem**: Inserting excessive qualification and hedging language that the source material does not warrant. AI text defaults to cautious phrasing: "It is important to note that," "It should be mentioned that," "One could argue that"
- **Detection signal**: More than 2 hedging phrases per paragraph in text that makes direct claims
- **Common over-hedges**:
  - "It is important to note that..." — almost always deletable; just state the thing
  - "It is worth mentioning that..." — if it is worth mentioning, mention it directly
  - "It should be noted that..." — passive hedge; say it or don't
  - "One might argue that..." — if you are making the argument, own it
  - "There are various factors that..." — name the factors instead
  - "In today's rapidly evolving world..." — content-free throat-clearing
  - "This is a complex issue with many dimensions..." — either show the complexity or don't announce it
- **Fix**: Delete the hedging wrapper and state the content directly. Reserve hedging for genuinely uncertain claims where the source material itself hedges.

### 6. Hollow Intensifiers
- **Problem**: Padding text with intensifiers that add no information: "very," "extremely," "incredibly," "highly," "truly," "really"
- **Detection signal**: More than 1 hollow intensifier per 100 words
- **Fix**: Remove the intensifier and choose a more precise word. "Very large" -> "massive" or simply provide the number. "Extremely important" -> explain why it matters.

## Structural Anti-Patterns

### 7. Symmetric Paragraph Structure
- **Problem**: Every paragraph follows the same template: topic sentence, 2-3 supporting sentences, concluding sentence. Human writing varies paragraph structure based on rhetorical purpose.
- **Detection signal**: All paragraphs in a section have the same sentence count (plus or minus 1) and follow topic-evidence-conclusion order
- **Fix**: Mix paragraph types — some open with evidence and end with the claim; some are a single emphatic sentence; some pose a question and answer it in the following paragraph; some use a narrative micro-structure.

### 8. List-to-Prose Conversion Failure
- **Problem**: When rewriting lists or bullet points into prose, producing sentences that are thinly disguised list items connected by "Additionally," "Furthermore," "Moreover"
- **Detection signal**: Paragraph of 4+ sentences where each begins with an additive transition and presents a single independent fact
- **Fix**: Integrate items into genuine flowing prose — group related points, use subordinate clauses, vary the rhetorical relationship between sentences (contrast, cause-effect, example-generalization)

### 9. Formulaic Introductions and Conclusions
- **Problem**: Opening with "In today's [adjective] world..." or "Throughout history..." and closing with "In conclusion, it is clear that..." These are AI defaults.
- **Common formulaic openers to avoid**:
  - "In today's rapidly evolving world..."
  - "In the ever-changing landscape of..."
  - "Throughout history, humans have..."
  - "As technology continues to advance..."
  - "When it comes to [topic]..."
- **Common formulaic closers to avoid**:
  - "In conclusion,"
  - "To sum up,"
  - "All in all,"
  - "In summary, it is evident that..."
  - "Moving forward, it will be important to..."
- **Fix**: Open with a specific detail, a surprising fact, a question, or jump directly into the argument. Close by circling back to a concrete image, posing a forward-looking question, or ending on the strongest piece of evidence.

### 10. Excessive Signposting
- **Problem**: Over-announcing what the text will do: "In this section, we will explore...", "The following paragraphs will discuss...", "Let us now turn to..."
- **Detection signal**: More than 1 meta-commentary sentence per section
- **Fix**: Delete the signpost and just deliver the content. Readers can follow well-organized prose without being told what is coming next. Use structural elements (headings, paragraph breaks) instead of verbal announcements.

## Semantic Anti-Patterns

### 11. Meaning Reversal Through Paraphrase
- **Problem**: In attempting to rephrase, accidentally inverting the meaning. "X does not significantly affect Y" becomes "X has a significant effect on Y" through careless restructuring.
- **Detection signal**: Post-rewrite meaning check reveals negation loss or causal reversal
- **Fix**: After every rewrite, verify that negations, comparatives, and causal relationships match the source exactly. Pay special attention to: "not," "less/fewer," "despite," "although," "except," "unless."

### 12. Generalization Creep
- **Problem**: Specific, qualified claims becoming sweeping generalizations through paraphrase. "A 2023 study of 200 participants found modest improvement" becomes "Research has shown clear benefits."
- **Detection signal**: Loss of specificity markers (dates, sample sizes, qualifiers like "modest," "preliminary," "in some cases")
- **Fix**: Preserve all quantifiers and qualifiers from the source. If simplifying for a general audience, maintain the qualifier even if you simplify the statistic ("early research suggests some improvement" rather than "research shows benefits").

### 13. Tone Contamination
- **Problem**: Elements of the source tone bleeding into a target style where they do not belong. Academic hedging appearing in marketing copy, or marketing urgency appearing in a technical rewrite.
- **Detection signal**: Register-inconsistent words or phrases (e.g., "game-changing" in academic prose, "notwithstanding" in casual blog post)
- **Fix**: After rewriting, do a register-consistency pass: read the output aloud and flag any word or phrase that would surprise a native reader of the target style. Replace with register-appropriate alternatives.

### 14. Synonym Roulette
- **Problem**: Mechanically replacing every content word with a synonym, regardless of connotation or register fit. "Big" becomes "gargantuan," "said" becomes "opined," "house" becomes "domicile."
- **Detection signal**: Unusual or elevated vocabulary that does not match the target register; words that are technically synonymous but connotationally wrong
- **Fix**: Only replace words when the replacement is a natural fit for the target style and audience. Keep simple words simple when the context calls for it. "Said" is almost always better than "opined," "exclaimed," or "articulated."
