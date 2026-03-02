---
strategy: summarizer
version: 1.0.0
steps: 5
---

# Content Summarization Strategy

## Step 1: Structure Identification
- Read the full source material before beginning summarization — never summarize while reading for the first time
- Classify the discourse type: argumentative / expository / narrative / descriptive / procedural (see knowledge/domain.md)
- Identify the document's structural skeleton:
  - IF argumentative THEN locate thesis, claims, evidence blocks, counter-arguments, conclusion
  - IF expository THEN locate topic statement, category headings, detail sections, synthesis
  - IF narrative THEN locate setting, key actors, initiating event, turning points, resolution
  - IF descriptive THEN locate subject overview, feature enumerations, comparative sections
  - IF procedural THEN locate goal statement, prerequisites, step sequence, warnings, verification
- Determine the total length and estimate a target compression ratio based on user intent:
  - "TLDR" / "one-liner" → 20:1+
  - "key points" / "brief" → 10:1
  - "summary" (default) → 5:1
  - "detailed summary" → 3:1
- IF the source is multi-document THEN note the number of documents and scan for thematic overlap before proceeding

## Step 2: Argument Extraction
- Build a claim-evidence hierarchy using the argument mapping framework from knowledge/domain.md:
  - Central thesis → supporting claims → evidence for each claim → qualifiers and counter-arguments
- For each claim identified, record:
  - The claim statement
  - The type and strength of its evidence (quantitative data, case study, expert opinion, logical reasoning)
  - Any qualifiers or conditions limiting the claim's scope
  - Any counter-evidence or objections acknowledged by the source
- Rank claims by argument strength:
  - **Strong**: Multiple independent evidence sources + qualifiers acknowledged
  - **Moderate**: Single evidence source or logical reasoning only
  - **Weak**: Assertion without evidence or anecdotal support only
  - **Contested**: Counter-evidence presented — both sides must appear in summary
- IF the source is multi-document THEN merge argument maps:
  - Corroborated claims (multiple sources) → high confidence
  - Contradictory claims → flag with attribution to each source
  - Unique claims (single source) → note as "according to [source]"

## Step 3: Detail Prioritization
- Score each extracted detail by information density (see knowledge/domain.md):
  - **Score 3**: Quantitative data + causal claim + named entity (always include)
  - **Score 2**: Novel claim or key evidence (include in standard+ summaries)
  - **Score 1**: Contextual elaboration (include only in detailed summaries)
  - **Score 0**: Transitional, redundant, or common knowledge (exclude)
- Apply the detail preservation tiers from knowledge/best-practices.md:
  - **Tier 1 — Must Preserve**: Central thesis, quantitative results, key named entities, causal claims with evidence, contradictions and caveats
  - **Tier 2 — Space Permitting**: Strongest example per claim, methodology details, secondary reinforcing claims, historical context
  - **Tier 3 — Safe to Omit**: Repeated examples, author credentials, acknowledgments, detailed literature reviews
- Cross-check against anti-patterns from knowledge/anti-patterns.md:
  - Am I dropping any numbers or dates? → Restore them
  - Am I stripping proper nouns? → Restore attribution
  - Am I over-generalizing specific lists? → Name the top items explicitly
  - Am I showing position bias? → Verify coverage spans the full document

## Step 4: Synthesis
- Construct the summary using the hybrid approach from knowledge/best-practices.md:
  - **Abstractive**: Use for narrative flow, transitions, and structural framing
  - **Extractive**: Use for quantitative data, direct quotes, and precise technical claims (mark with source references)
- Structure the output based on user intent:
  - IF "TLDR" THEN one sentence: thesis + most important finding
  - IF "key points" THEN bullet list: thesis + top 3-5 claims with headline evidence
  - IF "summary" THEN structured prose: full argument skeleton with Tier 1 details
  - IF "detailed summary" THEN section-by-section: all Tier 1 + Tier 2 details with source annotations
  - IF multi-document THEN organize by theme, not by source
- Apply formatting best practices:
  - Lead with the central conclusion (inverted pyramid)
  - One idea per bullet point or paragraph
  - Use headings or numbered lists for multi-part summaries
  - Add source traceability markers for key claims

## Step 5: Accuracy Self-Check
- Perform a systematic verification pass before outputting the summary:
  1. **Fact check**: For every number, date, percentage, and proper noun in the summary, verify it appears in the source material — if it does not, remove or correct it
  2. **Claim fidelity**: For every causal or evaluative statement, verify the source makes the same claim at the same strength — if the summary says "causes" but the source says "correlates with", downgrade the language
  3. **Attribution check**: For every attributed claim ("X said", "according to Y"), verify the attribution is correct and not confused with another entity
  4. **Completeness check**: Review the argument map — is any strong or contested claim missing from the summary? If yes and space permits, add it
  5. **Position bias check**: Does the summary draw from all sections of the source, or only the beginning? If the final third is unrepresented, reassess
  6. **Anti-pattern scan**: Run through the 12 anti-patterns in knowledge/anti-patterns.md — does the summary violate any?
- IF any check fails THEN revise the summary and re-run the verification
- State the compression ratio in the output: "[Original: ~X words → Summary: ~Y words, compression ratio Z:1]"
- IF the target compression risks losing Tier 1 details THEN warn the user: "Note: The requested length requires omitting [specific detail]. Expand to [length] for full coverage."
