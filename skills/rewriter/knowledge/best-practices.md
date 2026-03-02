---
domain: rewriter
topic: style-adaptation-variation-naturalness
priority: high
ttl: 30d
---

# Content Rewriting — Best Practices

## Style Adaptation Techniques

### 1. Semantic Core Extraction
Before rewriting, isolate the semantic core — the irreducible meaning that must survive transformation:
- **Factual claims**: Named entities, statistics, causal relationships, temporal sequences
- **Logical structure**: Argument flow, premise-conclusion chains, conditional relationships
- **Intent signals**: What the author wants the reader to think, feel, or do after reading
- Use @botlearn/summarizer to generate a structured summary as the rewrite anchor

### 2. Register Shifting
When moving between formality levels:
- **Upward shift** (casual -> formal): Replace contractions, eliminate slang, convert fragments to complete sentences, switch to third person, add explicit logical connectors
- **Downward shift** (formal -> casual): Introduce contractions, replace Latinate words with Anglo-Saxon equivalents, add direct address ("you"), break long sentences into conversational fragments, use rhetorical questions
- **Preserve one register marker** from the source to maintain continuity (e.g., keep a technical term even in casual rewrite, defined parenthetically)

### 3. Vocabulary Calibration
- Match vocabulary to target audience reading level (see knowledge/domain.md audience types)
- Replace jargon with plain-language equivalents when writing for general audiences; add a brief parenthetical explanation if the term must remain
- For expert audiences, elevate vocabulary precision: prefer "ameliorate" over "improve" only when the nuance matters
- Maintain consistent vocabulary within a single rewrite — do not oscillate between registers

### 4. Sentence Architecture Transformation
- **Academic -> Journalistic**: Split compound-complex sentences; front-load the subject and verb; move qualifiers to follow-up sentences
- **Technical -> Conversational**: Convert passive constructions to active; replace "It should be noted that X" with "X" directly; use "you" as subject
- **Any -> Literary**: Vary sentence length deliberately (short for impact, long for immersion); embed sensory detail; replace abstract nouns with concrete images

## Variation Patterns for Naturalness

### 5. Sentence Length Variation
Natural human writing follows an irregular rhythm. Target these distributions:

| Sentence Type | Word Count | Frequency in Output |
|---------------|-----------|-------------------|
| Short (punchy) | 4-8 words | 15-25% |
| Medium | 9-18 words | 40-55% |
| Long (complex) | 19-35 words | 20-30% |
| Very long | 36+ words | 0-5% (use sparingly) |

- Never produce 3+ consecutive sentences of similar length
- After a long sentence, follow with a short one for rhythm
- Use single-sentence paragraphs occasionally for emphasis (but not predictably)

### 6. Opening Word Diversity
Avoid starting consecutive sentences with the same word or pattern. Rotate through:
- Subject-first: "The researchers found..."
- Prepositional phrase: "In a 2024 study,..."
- Adverbial: "Surprisingly, the data showed..."
- Participial: "Building on earlier work,..."
- Temporal: "After three years of trials,..."
- Transitional: "Yet the implications extend..."
- Conditional: "If these trends continue,..."
- Demonstrative: "This finding challenges..."

Rule: No more than 2 of 10 consecutive sentences should start with the same part of speech.

### 7. Paragraph Structure Variation
- Vary paragraph length: mix 2-sentence, 3-4 sentence, and occasional 5-6 sentence paragraphs
- Do not follow a predictable pattern (e.g., always short-long-short)
- Occasionally use a single-sentence paragraph for rhetorical emphasis
- Vary paragraph openings: not every paragraph should start with a topic sentence; sometimes lead with evidence or a question

### 8. Lexical Variation
- Do not repeat the same word more than twice per paragraph (excluding articles, prepositions, and structural words)
- Use synonyms and near-synonyms, but ensure each synonym carries the correct connotation for context
- Mix Latinate and Anglo-Saxon vocabulary for texture: "begin/commence," "ask/inquire," "end/conclude"
- Vary transition words: do not overuse any single connector ("however," "moreover," "furthermore")

### 9. Syntactic Variation
Rotate through syntactic patterns within each section:
- Simple sentence: Subject + Verb + Object
- Compound: Independent clause + coordinating conjunction + independent clause
- Complex: Dependent clause + independent clause (or reversed)
- Compound-complex: Combination
- Fragment (deliberate): For emphasis or conversational tone
- Inverted: Object or adverb fronted for emphasis ("Never before had the data been so clear.")
- Parenthetical insertion: "The results — and this surprised everyone — exceeded projections."

### 10. Discourse Marker Naturalness
Replace mechanical transition words with organic connectors:

| Avoid (mechanical) | Prefer (natural) |
|-------------------|-----------------|
| "Furthermore," | Weave the connection into the sentence logic |
| "In conclusion," | "What this adds up to is..." or simply state the conclusion |
| "It is worth noting that" | State the thing directly |
| "Additionally," | Use a colon, semicolon, or restructure to embed the addition |
| "On the other hand," | "But" (simple, effective), or restructure as contrast within the sentence |

## Factual Accuracy Preservation

### 11. Claim Inventory
Before rewriting, create a mental inventory of all verifiable claims:
- Named entities (people, organizations, places)
- Numeric data (statistics, dates, measurements, percentages)
- Causal claims ("X causes Y," "X leads to Y")
- Quotations and attributed statements
- Temporal relationships ("before," "after," "during")

### 12. Post-Rewrite Accuracy Check
After rewriting, verify each claim against the inventory:
- Every named entity must appear correctly (spelling, context)
- Every statistic must be numerically identical
- Causal direction must be preserved (do not reverse cause and effect)
- Quotations must remain verbatim (or clearly marked as paraphrased)
- No new claims should be introduced that were not in the source

### 13. Meaning Drift Detection
Watch for subtle meaning changes during rewriting:
- **Strength drift**: "may contribute to" becoming "causes" (hedging removed)
- **Scope drift**: "in some studies" becoming "research shows" (overgeneralization)
- **Attribution drift**: A specific researcher's claim becoming a general consensus
- **Temporal drift**: A historical finding presented as current without qualification
- IF any drift is detected THEN correct and re-verify

## AI-Detection Avoidance Techniques

### 14. Perplexity Management
AI-generated text tends toward low perplexity (highly predictable next-token sequences). Increase perplexity naturally by:
- Using unexpected but contextually valid word choices
- Employing idiomatic expressions and colloquialisms appropriate to the register
- Introducing deliberate imperfection: a mild digression, an aside, an incomplete thought that resolves later
- Varying information density: some sentences are content-dense, others are transitional or reflective

### 15. Burstiness
Human writing is "bursty" — it alternates between simple and complex passages. AI text tends toward uniform complexity.
- Follow a technical explanation with a plainly stated summary
- Mix analytical passages with anecdotal or illustrative ones
- Allow the "energy" of the writing to ebb and flow rather than maintaining a constant level

### 16. Personal Voice Injection (When Appropriate)
For non-formal registers, inject markers of personal voice:
- Parenthetical asides that reveal thought process
- Qualified opinions ("I'd argue that..." or "The more compelling reading is...")
- Specific, non-generic examples drawn from plausible real-world scenarios
- Occasional self-correction ("Or rather, the more precise way to frame this is...")

### 17. Structural Unpredictability
- Do not always follow the same macro-structure (intro-body-conclusion)
- Vary where the thesis or key point appears (first, middle, or end of section)
- Use different organizational patterns: chronological, spatial, problem-solution, comparison, cause-effect
- Occasionally break a "rule" of writing deliberately and purposefully (a one-word paragraph, a question left unanswered, a list that ends on an odd number)
