---
strategy: rewriter
version: 1.0.0
steps: 6
---

# Content Rewriting Strategy

## Step 1: Source Analysis
- Parse the source text to identify: **style** (academic, journalistic, conversational, technical, literary, marketing), **register** (frozen/formal/consultative/casual/intimate), **tone** (warmth, authority, energy, objectivity axes), and **audience** (expert, practitioner, general, youth, executive)
- Use @botlearn/summarizer to extract the semantic core: key claims, factual data, logical structure, and authorial intent
- Build a **claim inventory**: list every verifiable fact, statistic, named entity, quotation, causal claim, and temporal relationship
- Measure source text characteristics: average sentence length, vocabulary complexity (Flesch-Kincaid estimate), paragraph structure patterns
- IF the user has not specified a target style or audience THEN infer from context or ask one clarifying question before proceeding
- Identify elements that must remain unchanged: proper nouns, direct quotations, technical terms with no equivalent, numerical data

## Step 2: Audience Profiling
- Determine the target audience from the user's request (explicit) or from the target platform/context (implicit)
- Map the audience to the audience type taxonomy in knowledge/domain.md: Expert, Practitioner, General, Youth, Executive
- Define adaptation parameters:
  - **Reading level**: Target Flesch-Kincaid score for the audience
  - **Assumed knowledge**: What concepts can be referenced without explanation?
  - **Vocabulary ceiling**: Maximum complexity of word choice
  - **Evidence expectations**: What kind of proof does this audience value?
  - **Engagement style**: Does this audience prefer data, narrative, authority, or relatability?
- IF the source audience matches the target audience THEN focus adaptation on style and tone rather than knowledge-level adjustment
- IF the target audience has lower domain knowledge than the source THEN identify all jargon and technical terms requiring simplification or explanation

## Step 3: Style Mapping
- Identify the source-to-target transformation pair using the Style Transformation Matrix in knowledge/domain.md
- Define the transformation axes:
  - **Vocabulary changes**: Words to replace, register-appropriate alternatives, jargon handling
  - **Sentence structure changes**: Active/passive shifts, sentence length targets, complexity adjustments
  - **Paragraph structure changes**: Information order, paragraph length variation, use of topic sentences
  - **Tone shifts**: Adjustments on warmth, authority, energy, and objectivity axes
  - **Register adjustments**: Formality markers to add or remove (contractions, person, address mode)
- Plan the macro-structure of the rewrite:
  - IF the target style uses a specific structure (e.g., inverted pyramid for journalistic) THEN reorganize the content to match
  - IF the source structure is adequate for the target style THEN preserve it to minimize unnecessary changes
- Pre-select naturalness techniques from knowledge/best-practices.md to apply during rewriting:
  - Sentence length variation targets (Section 5)
  - Opening word diversity strategy (Section 6)
  - Paragraph structure variation plan (Section 7)

## Step 4: Rewrite with Variation
- Execute the rewrite section by section, applying the mapped transformations:
  - Transform vocabulary according to target register and audience reading level
  - Restructure sentences to match target style patterns
  - Adjust tone markers (hedging, directness, warmth, authority)
  - Reorganize information flow if the target style demands it
- APPLY variation patterns throughout (from knowledge/best-practices.md):
  - Vary sentence length: enforce the 4-8 / 9-18 / 19-35 / 36+ word distribution
  - Rotate opening words: no more than 2 of 10 consecutive sentences starting with the same part of speech
  - Mix syntactic patterns: simple, compound, complex, compound-complex, fragments, inversions
  - Vary paragraph length: mix 2-sentence, 3-4 sentence, and 5-6 sentence paragraphs
- AVOID AI-tell vocabulary from knowledge/anti-patterns.md (Section 4): do not use "delve," "landscape" (metaphorical), "multifaceted," "pivotal," "tapestry," "robust," "comprehensive," "cutting-edge," or other flagged terms
- AVOID over-hedging (Section 5): strip unnecessary qualifiers; reserve hedging for genuinely uncertain claims
- AVOID formulaic openings and closings (Section 9): no "In today's rapidly evolving world," no "In conclusion, it is clear that"
- IF the source contains lists or bullet points AND the target style is prose THEN integrate items into flowing sentences with varied rhetorical relationships, not additive transitions

## Step 5: Naturalness Check
- Perform an AI-detection resistance review:
  - **Perplexity check**: Read through the output and identify any passages where the next word feels highly predictable; inject unexpected but valid word choices or restructure
  - **Burstiness check**: Verify that complexity alternates — analytical passages should be followed by simpler ones; ensure "energy" ebbs and flows
  - **Sentence length distribution**: Calculate approximate word counts; ensure standard deviation > 6 across paragraphs
  - **Opening word audit**: Verify no more than 2 of 10 consecutive sentences start with the same word or part of speech
  - **AI-tell scan**: Search the output for any words from the anti-patterns vocabulary list (knowledge/anti-patterns.md, Section 4); replace any found
  - **Hedge audit**: Count hedging phrases per paragraph; if more than 2, remove or rephrase
  - **Transition audit**: Check for mechanical transition words ("Furthermore," "Additionally," "Moreover"); replace with organic connectors or restructure
- IF any check fails THEN revise the specific passage and re-check
- Perform a **register consistency pass**: read the output in the voice of the target audience; flag any word or phrase that feels out of place for the target register
- Target: AI-detection rate < 20% as measured by standard detection tools

## Step 6: Accuracy Verification
- Compare the rewritten text against the claim inventory from Step 1:
  - **Named entities**: Every proper noun must appear correctly (spelling, context, attribution)
  - **Numeric data**: Every statistic, date, measurement, and percentage must be numerically identical to the source
  - **Causal relationships**: Verify that cause-effect directionality is preserved (no reversal through paraphrase)
  - **Negations**: Verify that all negations survive the rewrite ("does not" must not become "does" through restructuring)
  - **Qualifiers**: Check that scope qualifiers are preserved ("some studies" must not become "studies" or "all studies")
  - **Quotations**: Direct quotes must remain verbatim; paraphrased quotes must be clearly marked as paraphrased
  - **Temporal relationships**: "Before," "after," "during," and "while" relationships must match the source
- IF any factual discrepancy is found THEN correct the rewritten passage and re-verify
- Estimate factual accuracy percentage: target >= 95%
- SELF-CHECK before output:
  - Does the rewrite match the requested target style and audience?
  - Is the tone consistent throughout and appropriate for the target?
  - Are all factual claims accurate and traceable to the source?
  - Does the text read naturally and avoid AI-detection patterns?
  - IF any check fails THEN loop back to the relevant step (Step 4 for style/variation issues, Step 5 for naturalness issues)
- Output the rewritten text with a brief **transformation summary**:
  - Source style/register/audience -> Target style/register/audience
  - Key adaptations made (vocabulary level, structure changes, tone shifts)
  - Factual accuracy confidence (percentage of claims verified)
  - Any caveats (emphasis shifts, simplifications that reduced nuance, terms left untranslated)
