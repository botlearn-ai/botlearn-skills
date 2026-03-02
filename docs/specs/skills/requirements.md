# Requirements Document — BotLearn OpenClaw Skills

## Introduction

BotLearn MVP 需要交付 **20 个 OpenClaw Skill**，每个 Skill 是一个原子级、独立可安装的能力单元，通过 `clawhub install <skill-name>` 安装到用户的 OpenClaw Agent。

**核心约束**：
- 每个 Skill 是**原子的** — 单一职责，独立安装，独立测试
- 安装即生效 — 不需要用户配置或理解概念
- 可组合 — Skill 之间可声明依赖，组合使用

**OpenClaw Skill 规范**：

```
@botlearn/<skill-name>/
├── manifest.json              # 元信息：name, version, description, category, dependencies, compatibility
├── SKILL.md                   # Skill 核心定义：角色、能力、行为指令
├── knowledge/                 # 领域知识（注入 Agent Memory）
│   ├── domain.md              # 领域知识
│   ├── best-practices.md      # 最佳实践
│   └── anti-patterns.md       # 反模式
├── strategies/                # 行为策略（注册到 Agent Skills 系统）
│   └── main.md                # 核心策略流程
└── tests/
    ├── smoke.json             # 冒烟测试（安装后 < 60s 验证）
    └── benchmark.json         # 基准测试（评分提升验证）
```

**安装流程**：`clawhub install` → 依赖检查 → knowledge/ 写入 Memory → strategies/ 注册 Skills → smoke test 验证 → 完成

---

## Requirements

---

### Category A: 信息检索类（5 个 Skills）

Benchmark 维度：信息检索（目标提升 ≥ 30 分）

---

### Requirement 1: `@botlearn/google-search`（Google 高级搜索）

**User Story:** As an OpenClaw user, I want my Agent to construct precise search queries and filter noise, so that search result relevance improves from 30% to 80%.

#### Acceptance Criteria

1. WHEN the Agent receives a search request THEN it SHALL construct advanced queries using Boolean operators, site-specific filters, date ranges, filetype filters, and exclusion keywords.
2. WHEN results are returned THEN the Agent SHALL rank by relevance, remove low-quality entries, and deduplicate across sources.
3. WHEN the query is ambiguous THEN the Agent SHALL decompose it into sub-queries, execute separately, and merge results.
4. WHEN the smoke test runs THEN result relevance rate SHALL be ≥ 70%.

**Knowledge**: Search operator syntax, query construction patterns, source credibility heuristics.
**Strategy**: Query decomposition → multi-source search → dedup → relevance ranking → quality verification.

---

### Requirement 2: `@botlearn/academic-search`（学术论文检索）

**User Story:** As an OpenClaw user, I want my Agent to search arXiv/Google Scholar and extract key findings, so that it finds Top 5 papers on any topic within 2 minutes.

#### Acceptance Criteria

1. WHEN the Agent receives an academic query THEN it SHALL search arXiv, Google Scholar, and Semantic Scholar with domain-appropriate terms.
2. WHEN papers are found THEN the Agent SHALL extract: title, authors, abstract summary, key findings, methodology, and citation count.
3. WHEN multiple papers are retrieved THEN the Agent SHALL rank by relevance and impact, providing a comparative summary.
4. WHEN the smoke test runs THEN the Agent SHALL return ≥ 3 relevant papers with accurate key-finding summaries.

**Dependencies**: `@botlearn/google-search`
**Knowledge**: Academic database API patterns, paper structure, citation analysis, research methodology taxonomy.
**Strategy**: Keyword extraction → database-specific query → abstract screening → cross-reference → synthesis.

---

### Requirement 3: `@botlearn/rss-manager`（RSS 订阅管理）

**User Story:** As an OpenClaw user, I want my Agent to aggregate, deduplicate, and summarize multi-source RSS feeds, so that daily digest quality improves 3x.

#### Acceptance Criteria

1. WHEN managing feeds THEN the Agent SHALL support adding, removing, and categorizing RSS/Atom sources.
2. WHEN new articles arrive THEN the Agent SHALL deduplicate across sources (same story, different outlets).
3. WHEN generating a daily digest THEN the Agent SHALL produce: top stories ranked by importance, category groups, and key takeaways per story.
4. WHEN the smoke test runs THEN the digest SHALL cover ≥ 80% of important stories with accurate summaries.

**Knowledge**: RSS/Atom parsing, dedup algorithms, importance scoring, topic modeling.
**Strategy**: Source monitoring → extraction → dedup → importance scoring → topic clustering → summary.

---

### Requirement 4: `@botlearn/twitter-intel`（Twitter/X 信息流）

**User Story:** As an OpenClaw user, I want my Agent to track topics/KOLs on Twitter and extract insights, so that it surfaces actionable intelligence from noise.

#### Acceptance Criteria

1. WHEN monitoring Twitter THEN the Agent SHALL track specified KOLs, hashtags, and topics.
2. WHEN tweets are collected THEN the Agent SHALL filter noise (spam, memes, low-engagement) and surface high-signal content.
3. WHEN insights are extracted THEN the Agent SHALL summarize: key opinions, emerging trends, and sentiment shifts.
4. WHEN the smoke test runs THEN the Agent SHALL produce an insight report with ≥ 3 actionable takeaways.

**Knowledge**: Twitter API patterns, KOL identification, engagement metrics, bot detection, trend analysis.
**Strategy**: Source curation → signal filtering → opinion extraction → trend detection → insight synthesis.

---

### Requirement 5: `@botlearn/reddit-tracker`（Reddit 热点追踪）

**User Story:** As an OpenClaw user, I want my Agent to monitor subreddits and identify trends, so that it detects community hotspots 24 hours early.

#### Acceptance Criteria

1. WHEN monitoring Reddit THEN the Agent SHALL track specified subreddits and detect posts with rapidly rising engagement.
2. WHEN a trend is detected THEN the Agent SHALL provide: topic summary, key discussion points, community sentiment, cross-subreddit spread.
3. WHEN cross-subreddit trends emerge THEN the Agent SHALL flag them with supporting evidence.
4. WHEN the smoke test runs THEN the Agent SHALL identify ≥ 2 trending topics from the past 24 hours.

**Knowledge**: Reddit API, engagement velocity metrics, community norms per subreddit, trend detection.
**Strategy**: Subreddit monitoring → velocity tracking → cross-community correlation → sentiment analysis → trend prediction.

---

### Category B: 内容处理类（5 个 Skills）

Benchmark 维度：内容理解（目标提升 ≥ 30 分）

---

### Requirement 6: `@botlearn/summarizer`（长文总结）

**User Story:** As an OpenClaw user, I want my Agent to extract core arguments and retain key details, so that summary accuracy improves from 40% to 85%.

#### Acceptance Criteria

1. WHEN the Agent receives a long text (> 2000 words) THEN it SHALL produce: main thesis, supporting arguments, key evidence, and conclusions.
2. WHEN summarizing THEN the Agent SHALL preserve critical details (numbers, names, dates, causal relationships) while eliminating redundancy.
3. WHEN multiple documents are provided THEN the Agent SHALL produce comparative analysis: agreements, contradictions, unique contributions.
4. WHEN the smoke test runs THEN key point coverage SHALL score ≥ 80% by Judge LLM.

**Knowledge**: Discourse structure, argument mapping, information density heuristics.
**Strategy**: Structure identification → argument extraction → detail prioritization → synthesis → accuracy self-check.

---

### Requirement 7: `@botlearn/translator`（多语言翻译）

**User Story:** As an OpenClaw user, I want my Agent to perform context-aware translation with terminology consistency, so that translation quality approaches human-level.

#### Acceptance Criteria

1. WHEN translating THEN the Agent SHALL maintain context: idiomatic expressions, cultural references, domain terminology.
2. WHEN translating a document series THEN the Agent SHALL maintain terminology consistency across documents.
3. WHEN encountering ambiguity THEN the Agent SHALL choose the most contextually appropriate translation, noting alternatives.
4. WHEN the smoke test runs THEN translation quality SHALL score ≥ 4/5 (accuracy, fluency, terminology).

**Knowledge**: Translation theory, language-pair patterns, domain terminology, common pitfalls.
**Strategy**: Source analysis → context establishment → terminology lookup → draft → fluency refinement → consistency verification.

---

### Requirement 8: `@botlearn/rewriter`（内容改写）

**User Story:** As an OpenClaw user, I want my Agent to rewrite with style transformation and audience adaptation, so that rewritten content passes AI detection at < 10%.

#### Acceptance Criteria

1. WHEN rewriting THEN the Agent SHALL transform style while preserving core message and factual accuracy.
2. WHEN the user specifies audience/tone THEN the Agent SHALL adapt vocabulary, sentence structure, and examples.
3. WHEN rewriting THEN the Agent SHALL produce natural text avoiding AI patterns (uniform length, generic transitions, over-hedging).
4. WHEN the smoke test runs THEN factual accuracy SHALL be ≥ 95% AND AI detection rate < 20%.

**Dependencies**: `@botlearn/summarizer`
**Knowledge**: Writing style taxonomy, audience analysis, AI-detection avoidance patterns.
**Strategy**: Source analysis → audience profiling → style mapping → rewrite with variation → naturalness check → accuracy verification.

---

### Requirement 9: `@botlearn/keyword-extractor`（关键词提取）

**User Story:** As an OpenClaw user, I want my Agent to extract semantic-level keywords and cluster topics, so that keyword coverage improves from 50% to 90%.

#### Acceptance Criteria

1. WHEN processing text THEN the Agent SHALL extract explicit keywords AND semantic concepts (themes, implicit topics).
2. WHEN extracting THEN the Agent SHALL rank by relevance/frequency, grouping related terms into topic clusters.
3. WHEN processing multiple documents THEN the Agent SHALL identify cross-document themes and per-document unique keywords.
4. WHEN the smoke test runs THEN keyword coverage SHALL be ≥ 85% (vs. expert-annotated ground truth).

**Knowledge**: TF-IDF concepts, semantic similarity, topic modeling, domain taxonomy.
**Strategy**: Preprocessing → multi-level extraction (lexical + semantic) → clustering → ranking → domain contextualization.

---

### Requirement 10: `@botlearn/sentiment-analyzer`（情感分析）

**User Story:** As an OpenClaw user, I want my Agent to perform fine-grained sentiment recognition and opinion mining, so that sentiment accuracy exceeds 85%.

#### Acceptance Criteria

1. WHEN analyzing sentiment THEN the Agent SHALL classify at document-level, paragraph-level, and aspect-level.
2. WHEN opinions are detected THEN the Agent SHALL extract: opinion holder, target, polarity (positive/negative/neutral), intensity (1-5).
3. WHEN analyzing multi-opinion texts THEN the Agent SHALL separate and attribute opinions to respective aspects.
4. WHEN the smoke test runs THEN aspect-level sentiment accuracy SHALL be ≥ 80%.

**Knowledge**: Sentiment lexicons, aspect-based analysis, sarcasm detection, domain-specific indicators.
**Strategy**: Segmentation → aspect identification → sentiment cue detection → polarity classification → confidence assessment → aggregation.

---

### Category C: 编程辅助类（5 个 Skills）

Benchmark 维度：代码生成（目标提升 ≥ 30 分）

---

### Requirement 11: `@botlearn/code-gen`（代码生成）

**User Story:** As an OpenClaw user, I want my Agent to generate complete code with error handling and types, so that first-run success rate improves from 20% to 70%.

#### Acceptance Criteria

1. WHEN generating code THEN the Agent SHALL include: error handling, type annotations, input validation, meaningful variable names.
2. WHEN generating an API endpoint THEN the Agent SHALL produce: route, validation, business logic, error responses, and basic tests.
3. WHEN the user specifies a framework/language THEN the Agent SHALL follow its conventions and best practices.
4. WHEN the smoke test runs THEN generated code SHALL compile/run without errors ≥ 65% of the time.

**Knowledge**: Language idioms, framework conventions, design patterns, error handling, testing patterns.
**Strategy**: Requirement analysis → architecture decision → interface design → implementation → self-testing → review reflection.

---

### Requirement 12: `@botlearn/code-review`（代码审查）

**User Story:** As an OpenClaw user, I want my Agent to identify security vulnerabilities, performance issues, and code smells, so that review coverage matches human-level.

#### Acceptance Criteria

1. WHEN reviewing code THEN the Agent SHALL check: security (OWASP Top 10), performance bottlenecks, code smells, naming consistency, logic errors.
2. WHEN issues are found THEN the Agent SHALL classify by severity (Critical/High/Medium/Low) with specific fix suggestions and code examples.
3. WHEN review completes THEN the Agent SHALL provide: overall quality score, top issues, prioritized action items.
4. WHEN the smoke test runs THEN the Agent SHALL detect ≥ 70% of intentionally planted issues.

**Knowledge**: OWASP Top 10, vulnerability patterns, performance anti-patterns, code smell catalog, clean code principles.
**Strategy**: Static analysis → security scan → performance analysis → pattern check → issue classification → fix suggestion.

---

### Requirement 13: `@botlearn/debugger`（Bug 调试）

**User Story:** As an OpenClaw user, I want my Agent to perform root cause analysis and suggest fixes, so that debugging efficiency improves 5x.

#### Acceptance Criteria

1. WHEN debugging THEN the Agent SHALL: reproduce symptom, trace execution path, identify root cause.
2. WHEN a root cause is found THEN the Agent SHALL suggest: code changes, explanation, and a regression test.
3. WHEN debugging THEN the Agent SHALL consider related symptoms that may share the same root cause.
4. WHEN the smoke test runs THEN the Agent SHALL correctly identify root causes ≥ 60% of the time.

**Dependencies**: `@botlearn/code-review`
**Knowledge**: Common bug patterns, debugging methodologies, error message interpretation, stack trace analysis.
**Strategy**: Symptom analysis → hypothesis → reproduction → root cause isolation → fix design → regression test → verification.

---

### Requirement 14: `@botlearn/refactor`（代码重构）

**User Story:** As an OpenClaw user, I want my Agent to apply design patterns and improve readability, so that code quality scores improve 40%.

#### Acceptance Criteria

1. WHEN refactoring THEN the Agent SHALL identify opportunities: duplication, long methods, large classes, feature envy, tight coupling.
2. WHEN refactoring THEN the Agent SHALL apply appropriate patterns and ensure behavioral equivalence.
3. WHEN proposing changes THEN the Agent SHALL explain: what changed, why, and which pattern was applied.
4. WHEN the smoke test runs THEN refactored code SHALL score ≥ 35% higher on quality metrics.

**Dependencies**: `@botlearn/code-review`
**Knowledge**: Design patterns (GoF), refactoring catalog (Fowler), SOLID, complexity metrics.
**Strategy**: Smell detection → pattern matching → refactoring plan → incremental transform → equivalence verification → quality measurement.

---

### Requirement 15: `@botlearn/doc-gen`（文档生成）

**User Story:** As an OpenClaw user, I want my Agent to generate API docs, READMEs, and changelogs, so that documentation completeness improves from 30% to 90%.

#### Acceptance Criteria

1. WHEN generating API docs THEN the Agent SHALL include: endpoint descriptions, schemas, auth requirements, error codes, usage examples.
2. WHEN generating a README THEN the Agent SHALL include: overview, installation, usage, configuration, contributing.
3. WHEN generating a changelog THEN the Agent SHALL analyze git history and produce structured entries with commit/PR links.
4. WHEN the smoke test runs THEN generated docs SHALL cover ≥ 85% of the public API surface.

**Dependencies**: `@botlearn/code-gen`
**Knowledge**: Documentation standards (JSDoc, OpenAPI, README conventions), technical writing, changelog formats.
**Strategy**: Code analysis → API extraction → description generation → example creation → style matching → completeness check.

---

### Category D: 创意生成类（5 个 Skills）

Benchmark 维度：创意生成（目标提升 ≥ 30 分）

---

### Requirement 16: `@botlearn/writer`（文章写作）

**User Story:** As an OpenClaw user, I want my Agent to produce structured articles with evidence and consistent style, so that article quality improves 60%.

#### Acceptance Criteria

1. WHEN writing THEN the Agent SHALL produce: clear thesis, supporting arguments with evidence, logical flow, strong conclusion.
2. WHEN writing THEN the Agent SHALL maintain consistent tone, style, and voice throughout.
3. WHEN making factual claims THEN the Agent SHALL provide evidence or cite sources.
4. WHEN the smoke test runs THEN article quality SHALL score ≥ 4/5.

**Dependencies**: `@botlearn/summarizer`, `@botlearn/keyword-extractor`
**Knowledge**: Article structure patterns, argumentation frameworks, evidence types, style guides.
**Strategy**: Topic research → outline → argument building → evidence integration → draft → style check → revision.

---

### Requirement 17: `@botlearn/brainstorm`（头脑风暴）

**User Story:** As an OpenClaw user, I want my Agent to generate multi-dimensional ideas with feasibility assessment, so that idea count triples and viable ideas exceed 40%.

#### Acceptance Criteria

1. WHEN brainstorming THEN the Agent SHALL generate ideas across dimensions: lateral thinking, analogical reasoning, constraint removal, trend extrapolation.
2. WHEN ideas are generated THEN the Agent SHALL assess feasibility (technical, resource, timeline) and rate each.
3. WHEN complete THEN the Agent SHALL organize into: quick wins, ambitious bets, moonshots.
4. WHEN the smoke test runs THEN the Agent SHALL generate ≥ 10 distinct ideas with ≥ 40% feasible.

**Knowledge**: Creative frameworks (SCAMPER, Six Hats, TRIZ), innovation patterns, feasibility matrices.
**Strategy**: Problem reframing → multi-dimensional divergence → generation → feasibility assessment → clustering → prioritization.

---

### Requirement 18: `@botlearn/storyteller`（故事创作）

**User Story:** As an OpenClaw user, I want my Agent to craft stories with narrative structure, character development, and emotional rhythm, so that story completeness and coherence significantly improve.

#### Acceptance Criteria

1. WHEN writing a story THEN the Agent SHALL follow narrative structure: setup, rising action, climax, falling action, resolution.
2. WHEN creating characters THEN the Agent SHALL develop: distinct voices, motivations, arcs, consistent behavior.
3. WHEN crafting emotional rhythm THEN the Agent SHALL vary pacing: tension build, release, quiet moments, reveals.
4. WHEN the smoke test runs THEN story quality SHALL score ≥ 3.5/5.

**Knowledge**: Story frameworks (Hero's Journey, Three-Act, Kishōtenketsu), character archetypes, genre conventions, pacing techniques.
**Strategy**: Premise → character design → plot outline → scene writing → pacing adjustment → consistency review.

---

### Requirement 19: `@botlearn/copywriter`（营销文案）

**User Story:** As an OpenClaw user, I want my Agent to analyze audiences, extract pain points, and design CTAs, so that estimated click-through rate doubles.

#### Acceptance Criteria

1. WHEN writing copy THEN the Agent SHALL: analyze target audience, identify pain points, craft value proposition, design CTA.
2. WHEN writing THEN the Agent SHALL apply proven frameworks (AIDA, PAS, BAB) appropriate to context.
3. WHEN the user specifies a platform THEN the Agent SHALL adapt copy to platform norms.
4. WHEN the smoke test runs THEN copy quality (persuasiveness, clarity, CTA) SHALL score ≥ 4/5.

**Dependencies**: `@botlearn/sentiment-analyzer`
**Knowledge**: Copywriting frameworks (AIDA, PAS, BAB, 4Ps), audience segmentation, CTA design, platform norms.
**Strategy**: Audience analysis → pain point ID → value proposition → framework selection → drafting → variant generation → persuasiveness check.

---

### Requirement 20: `@botlearn/social-media`（社交媒体内容）

**User Story:** As an OpenClaw user, I want my Agent to create platform-adapted content with optimal hashtags and timing, so that estimated engagement rate triples.

#### Acceptance Criteria

1. WHEN creating content THEN the Agent SHALL adapt format, tone, and length to the specified platform (Twitter, LinkedIn, Instagram, TikTok, etc.).
2. WHEN generating content THEN the Agent SHALL suggest relevant hashtags ranked by reach and relevance.
3. WHEN creating a content series THEN the Agent SHALL maintain thematic consistency while varying format.
4. WHEN the smoke test runs THEN content quality (platform fit, engagement potential, hashtag relevance) SHALL score ≥ 4/5.

**Dependencies**: `@botlearn/copywriter`
**Knowledge**: Platform norms (limits, formats, algorithms), hashtag strategy, engagement patterns, content calendar.
**Strategy**: Platform analysis → ideation → format adaptation → hashtag selection → timing optimization → engagement prediction.

---

## Dependency Graph

```
graph TD
    GS[google-search] --> AS[academic-search]
    SUM[summarizer] --> RW[rewriter]
    SUM --> WR[writer]
    KW[keyword-extractor] --> WR
    SA[sentiment-analyzer] --> CW[copywriter]
    CW --> SM[social-media]
    CR[code-review] --> DBG[debugger]
    CR --> RF[refactor]
    CG[code-gen] --> DG[doc-gen]
```

**无依赖（可并行开发）**：google-search, rss-manager, twitter-intel, reddit-tracker, summarizer, translator, keyword-extractor, sentiment-analyzer, code-gen, code-review, brainstorm, storyteller

**有依赖（需按序开发）**：academic-search, rewriter, writer, copywriter, social-media, debugger, refactor, doc-gen

---

## Quality Baseline

| Category | Skills Count | Benchmark Dimension | Target Improvement | Smoke Test Time |
|----------|-------------|--------------------|--------------------|----------------|
| 信息检索 | 5 | Information Retrieval | ≥ +30 points | < 60s each |
| 内容处理 | 5 | Content Understanding | ≥ +30 points | < 60s each |
| 编程辅助 | 5 | Code Generation | ≥ +30 points | < 60s each |
| 创意生成 | 5 | Creative Generation | ≥ +30 points | < 60s each |
