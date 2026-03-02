---
domain: keyword-extractor
topic: extraction-methods-and-theory
priority: high
ttl: 30d
---

# Keyword Extraction — Methods, Techniques & Theory

## 1. TF-IDF (Term Frequency-Inverse Document Frequency)

### Core Formula
- **TF(t, d)** = (Number of times term t appears in document d) / (Total number of terms in d)
- **IDF(t, D)** = log(Total number of documents in corpus D / Number of documents containing t)
- **TF-IDF(t, d, D)** = TF(t, d) x IDF(t, D)

### Interpretation
- High TF-IDF = term is frequent in the document but rare across the corpus — strong keyword signal
- Low TF-IDF = term is either rare in the document or common across many documents — weak signal
- Zero TF-IDF = term does not appear in the document

### Variants
- **Sublinear TF**: `1 + log(TF)` — dampens the effect of high-frequency terms
- **Smoothed IDF**: `log(1 + N/df)` — prevents division by zero for new terms
- **BM25 weighting**: Adds document length normalization — preferred for variable-length texts

### Single-Document Application
When no corpus is available (single-document extraction):
- Use a general-purpose reference corpus IDF (e.g., Wikipedia, Common Crawl frequencies)
- Alternatively, use sentence-level TF-IDF: treat each sentence as a "document" within the text
- Compare term frequencies against expected frequencies from domain language models

## 2. Named Entity Recognition (NER)

### Entity Categories for Keyword Extraction
| Entity Type | Examples | Keyword Priority |
|------------|---------|-----------------|
| PERSON | "Elon Musk", "Ada Lovelace" | High — often central to topic |
| ORGANIZATION | "OpenAI", "United Nations" | High — key actors or subjects |
| LOCATION | "Silicon Valley", "European Union" | Medium — contextual anchors |
| TECHNOLOGY | "Kubernetes", "GPT-4", "React" | High — core in technical texts |
| EVENT | "COP28", "Black Friday" | Medium-High — temporal anchors |
| CONCEPT | "machine learning", "supply chain" | High — abstract topic markers |
| PRODUCT | "iPhone 15", "Tesla Model S" | Medium — specific references |
| DATE/TIME | "Q3 2024", "2023 fiscal year" | Low — usually metadata, not keywords |

### NER as Keyword Signal
- Named entities are almost always keywords — they carry high information density
- Multi-word entities (e.g., "natural language processing") should be extracted as single keyword units, not split into individual words
- Entity type provides automatic categorization for topic clustering

### Entity Disambiguation
- "Apple" (company) vs "apple" (fruit) — resolve using surrounding context
- "Python" (language) vs "python" (snake) — use co-occurring terms as disambiguation signals
- When ambiguous, include the entity with its most probable interpretation noted

## 3. Semantic Similarity & Embeddings

### Concept
- Represent words/phrases as dense vectors in a high-dimensional space
- Semantically similar terms have vectors that are close together (high cosine similarity)
- Enables discovery of keywords that are conceptually important but may not appear frequently

### Applications to Keyword Extraction

#### Semantic Deduplication
- "machine learning" and "ML" — cosine similarity > 0.9 → merge as single keyword
- "artificial intelligence" and "AI" — same concept, different surface forms
- Group synonyms and abbreviations under a canonical keyword

#### Concept Expansion
- A text about "neural networks" likely also relates to "deep learning", "backpropagation", "gradient descent"
- Use embedding proximity to identify implicit keywords not explicitly stated in the text
- Threshold: cosine similarity > 0.7 for concept expansion candidates

#### Centrality-Based Ranking
- Build a keyword graph where edge weights = semantic similarity between terms
- Keywords with high graph centrality (many strong connections) are core topics
- Peripheral keywords (few weak connections) are supporting or tangential

### Embedding Models for Keyword Tasks
| Model Type | Best For | Trade-off |
|-----------|---------|-----------|
| Word-level (Word2Vec, GloVe) | Individual term similarity | Fast, but misses phrase-level meaning |
| Sentence-level (SBERT, E5) | Phrase and concept similarity | Better semantics, moderate speed |
| Document-level (Doc2Vec) | Overall topic similarity | Good for clustering, less granular |

## 4. Topic Modeling

### Latent Topic Discovery
- Discover hidden thematic structures that may not be obvious from individual keywords
- Maps documents to a mixture of topics; maps topics to distributions over words

### LDA (Latent Dirichlet Allocation)
- Probabilistic model: each document is a mixture of K topics
- Each topic is a distribution over vocabulary terms
- Top terms per topic become topic-level keywords
- Hyperparameters: K (number of topics), alpha (document-topic density), beta (topic-word density)

### Topic-Keyword Relationship
- Topic model outputs complement TF-IDF extraction:
  - TF-IDF finds **statistically distinctive** terms
  - Topic modeling finds **thematically coherent** term groups
- Use topic assignments to cluster TF-IDF keywords into meaningful groups

### Dynamic Topic Allocation
- For short texts (< 500 words): 2-4 topics maximum
- For medium texts (500-2000 words): 3-7 topics
- For long texts (2000+ words): 5-12 topics
- IF topics overlap significantly (shared top terms > 50%) THEN reduce K

## 5. Domain Taxonomy Mapping

### Purpose
- Map extracted keywords to standardized category hierarchies
- Provides consistent labeling across different texts in the same domain
- Enables cross-document keyword comparison and aggregation

### Common Taxonomies
| Domain | Taxonomy | Example Path |
|--------|----------|-------------|
| Technology | ACM Computing Classification | Computing > AI > Machine Learning > Deep Learning |
| Science | Library of Congress Subject Headings | Science > Computer Science > Algorithms |
| Business | NAICS Industry Codes | Information > Software Publishers |
| Academic | MESH (Medical), JEL (Economics) | Domain-specific controlled vocabularies |

### Mapping Strategy
1. Extract raw keywords from text
2. For each keyword, find the closest match in the domain taxonomy (exact match > partial match > semantic match)
3. Assign the taxonomy path as metadata to the keyword
4. IF no taxonomy match exists THEN flag as "uncategorized" and suggest the nearest taxonomy node
