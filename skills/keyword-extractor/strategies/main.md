---
strategy: keyword-extractor
version: 1.0.0
steps: 5
---

# Keyword Extraction Strategy

## Step 1: Preprocessing & Domain Detection
- Receive the input text and determine its **length**, **structure** (plain text / structured document / code), and **language**
- Detect the document domain by analyzing high-frequency terms and named entities against known domain vocabularies:
  - IF technical terms dominate (API, function, deploy) THEN domain = "technology"
  - IF financial terms dominate (revenue, equity, margin) THEN domain = "finance"
  - IF medical terms dominate (diagnosis, treatment, symptom) THEN domain = "healthcare"
  - IF no clear domain signal THEN domain = "general"
- Normalize the text:
  - Convert to consistent Unicode encoding (NFC normalization)
  - Preserve original casing for NER but create a lowercased copy for statistical analysis
  - Remove boilerplate elements: headers, footers, navigation text, disclaimers, copyright notices
  - Segment into sentences for positional analysis
- Build a stopword filter:
  - Start with standard stopword list (language-specific)
  - EXTEND with domain-specific function words (e.g., "et al.", "ibid." for academic; "herein", "whereas" for legal)
  - Never include domain-specific technical terms in the stopword list
- Identify text structure:
  - Map title, headings, paragraphs, lists, captions, footnotes
  - Assign positional weight multipliers from knowledge/best-practices.md

## Step 2: Multi-Level Extraction
- **Lexical extraction**:
  - Tokenize the text and remove stopwords
  - Apply lemmatization to group inflected forms
  - Calculate TF-IDF scores for each unique term using knowledge/domain.md formulas
  - IF no reference corpus is available THEN use sentence-level TF-IDF (each sentence = one document)
  - Retain terms with TF-IDF score above the 60th percentile
- **Phrasal extraction**:
  - Extract bigrams and trigrams using a sliding window
  - Score multi-word expressions using PMI (retain PMI > 3.0)
  - Apply POS pattern matching for noun phrases: (ADJ)* (NOUN)+
  - Merge overlapping n-grams into the longest meaningful phrase
- **Named entity extraction**:
  - Run NER to identify PERSON, ORGANIZATION, LOCATION, TECHNOLOGY, EVENT, CONCEPT, PRODUCT entities
  - Lock entity spans as atomic keyword units — do not split
  - Assign entity type metadata to each extracted entity keyword
- **Semantic extraction**:
  - Generate embeddings for all candidate keywords
  - Identify implicit concepts by finding high-centrality nodes in the keyword similarity graph
  - IF a concept is implied by 3+ explicit keywords (similarity > 0.7) but not stated THEN add as a semantic-level keyword with confidence = "medium"
  - Check for negation context: IF keyword appears in a negated clause THEN flag as "negated" and reduce score by 50%

## Step 3: Clustering & Topic Assignment
- Build a keyword similarity matrix using embedding cosine similarity
- Apply agglomerative clustering with similarity threshold 0.65:
  - Each keyword starts as its own cluster
  - Iteratively merge the two most similar clusters until no pair exceeds the threshold
- Post-process clusters:
  - IF cluster size = 1 AND keyword score < 50 THEN merge into the nearest cluster
  - IF cluster size > 15 THEN attempt to split into sub-clusters at threshold 0.75
  - IF two clusters share > 50% of their top-5 keywords THEN merge them
- Name each cluster:
  - Primary label = highest-scoring keyword in the cluster
  - Secondary label = second-highest-scoring keyword (provides disambiguation)
- Assign topic hierarchy:
  - Map cluster labels to domain taxonomy paths from knowledge/domain.md
  - IF taxonomy match confidence < 0.5 THEN label as "uncategorized" with nearest taxonomy suggestion
- Validate coverage:
  - Compute what percentage of the text's sentences contain at least one keyword from any cluster
  - IF coverage < 80% THEN re-examine uncovered sentences for missed keywords and add them

## Step 4: Ranking & Scoring
- Compute the composite score for each keyword using the formula from knowledge/best-practices.md:
  ```
  Score(keyword) = 0.30*StatScore + 0.30*SemScore + 0.20*PosScore + 0.20*DomScore
  ```
  - **StatScore**: TF-IDF normalized to 0-1 range
  - **SemScore**: Graph centrality score (eigenvector centrality) normalized to 0-1
  - **PosScore**: Maximum positional weight multiplier for any occurrence of the keyword
  - **DomScore**: 1.0 if the keyword matches a domain taxonomy term, 0.5 if partial match, 0.2 if no match
- Normalize all scores to 0-100 scale (top keyword = 100)
- Classify keywords:
  - **Primary** (score >= 70): Core topic keywords — always included in output
  - **Secondary** (score 40-69): Supporting concepts — included by default
  - **Tertiary** (score < 40): Peripheral terms — included only on request
- Apply semantic deduplication:
  - IF two keywords have embedding similarity > 0.85 THEN merge under the more specific or more frequent form
  - Preserve the merged term as an alias in the output
- Re-rank within each cluster by score descending
- Verify keyword count against guidelines from knowledge/best-practices.md:
  - IF count exceeds the recommended maximum THEN prune lowest-scoring tertiary keywords
  - IF count is below the recommended minimum THEN lower the extraction threshold and re-extract

## Step 5: Domain Contextualization & Output
- For each keyword, enrich with domain context:
  - Map to taxonomy path (if available)
  - Note relationships to other keywords: "broader than", "narrower than", "related to"
  - IF the keyword is a named entity THEN include entity type
- Assemble structured output:
  - Group keywords by topic cluster
  - Within each cluster, provide:
    - **Cluster label** and taxonomy path
    - **Cluster summary**: One sentence describing the sub-topic
    - **Keywords**: Ordered by score, each with: term, score, level (lexical/phrasal/semantic), type, confidence
  - After all clusters, provide:
    - **Coverage metric**: Percentage of text content addressed by extracted keywords
    - **Keyword count**: Total primary / secondary / tertiary breakdown
- SELF-CHECK against knowledge/anti-patterns.md:
  - Are there any stopwords in the output? IF yes THEN remove
  - Are any named entities fragmented? IF yes THEN reassemble
  - Are there synonym duplicates? IF yes THEN merge
  - Is the output a flat list without clustering? IF yes THEN re-cluster
  - Are scores included for all keywords? IF no THEN add scores
  - Is coverage below 80%? IF yes THEN loop back to Step 2 with lower thresholds
  - IF any check fails THEN fix the issue before presenting output
