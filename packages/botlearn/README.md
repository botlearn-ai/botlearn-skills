# botlearn

BotLearn OpenClaw Skills SDK — types, validator, and utilities for `@botlearn/*` skill packages.

## Installation

```bash
# Install the SDK (for building custom skills or tools)
npm install botlearn

# Install individual skills into your Agent
npm install @botlearn/google-search
npm install @botlearn/code-gen
clawhub install @botlearn/google-search
```

## Skills

### Information Retrieval (5)

| Skill | Description | Dependencies |
|-------|-------------|-------------|
| `@botlearn/google-search` | Web search query optimization and result curation | — |
| `@botlearn/academic-search` | Academic paper discovery and literature review | google-search |
| `@botlearn/rss-manager` | RSS/Atom feed monitoring, deduplication, and digest generation | — |
| `@botlearn/twitter-intel` | Twitter/X intelligence gathering and trend analysis | — |
| `@botlearn/reddit-tracker` | Reddit trend detection and cross-subreddit correlation | — |

### Content Processing (5)

| Skill | Description | Dependencies |
|-------|-------------|-------------|
| `@botlearn/summarizer` | Multi-format content summarization with discourse analysis | — |
| `@botlearn/translator` | Context-aware translation with terminology management | — |
| `@botlearn/rewriter` | Audience-adaptive content rewriting and style transformation | summarizer |
| `@botlearn/keyword-extractor` | Multi-layer keyword and keyphrase extraction | — |
| `@botlearn/sentiment-analyzer` | Aspect-level sentiment analysis with sarcasm detection | — |

### Programming Assistance (5)

| Skill | Description | Dependencies |
|-------|-------------|-------------|
| `@botlearn/code-gen` | Multi-language code generation with architecture-aware design | — |
| `@botlearn/code-review` | Security, performance, and quality code review (OWASP Top 10) | — |
| `@botlearn/debugger` | Systematic bug diagnosis and root cause analysis | code-review |
| `@botlearn/refactor` | Design-pattern-driven code refactoring | code-review |
| `@botlearn/doc-gen` | API documentation and README generation | code-gen |

### Creative Generation (5)

| Skill | Description | Dependencies |
|-------|-------------|-------------|
| `@botlearn/brainstorm` | Structured creative ideation (SCAMPER, Six Hats, TRIZ) | — |
| `@botlearn/storyteller` | Narrative craft across genres and structures | — |
| `@botlearn/writer` | Long-form article writing with argument frameworks | summarizer, keyword-extractor |
| `@botlearn/copywriter` | Persuasion-framework-driven marketing copy | sentiment-analyzer |
| `@botlearn/social-media` | Platform-native social media content creation | copywriter |

## Skill Package Structure

Each skill is an independent npm package with a standardized structure:

```
@botlearn/<skill-name>/        # npm package
├── package.json               # npm package config
├── manifest.json              # Skill metadata: category, benchmark dimension
├── SKILL.md                   # Role definition, triggers, activation rules
├── knowledge/
│   ├── domain.md              # Domain expertise
│   ├── best-practices.md      # Quality standards
│   └── anti-patterns.md       # Common mistakes to avoid
├── strategies/
│   └── main.md                # Step-by-step behavioral strategy
└── tests/
    ├── smoke.json             # 1 task, < 60s, pass threshold 60/100
    └── benchmark.json         # 10 tasks (3 easy, 4 medium, 3 hard)
```

## SDK API

```typescript
import { validateManifest } from "botlearn";
import type { SkillManifest, ValidationResult } from "botlearn";

// Validate a manifest
const result: ValidationResult = validateManifest(manifest, knownSkillNames);
console.log(result.valid, result.errors);
```

## Publishing

Each skill is published independently to npm:

```bash
cd packages/skills/google-search
npm publish --access public    # publishes @botlearn/google-search
```

## Compatibility

- OpenClaw Agent: `>=0.5.0`
- Node.js: `>=18`

## License

MIT
