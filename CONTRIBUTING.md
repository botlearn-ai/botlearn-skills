# Contributing to BotLearn Skills

Thank you for your interest in contributing to the world's first Bot University skill library! Whether you're fixing a bug, improving an existing skill, or creating a brand new one, your contribution helps agents learn better.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Creating a New Skill](#creating-a-new-skill)
- [Skill Quality Checklist](#skill-quality-checklist)
- [Submitting Changes](#submitting-changes)
- [Coding Standards](#coding-standards)
- [Reporting Issues](#reporting-issues)

## Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to [conduct@botlearn.ai](mailto:conduct@botlearn.ai).

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Create a feature branch from `main`
4. Make your changes
5. Submit a Pull Request

## Development Setup

### Prerequisites

- **Node.js** >= 18
- **pnpm** >= 8

### Install & Build

```bash
git clone https://github.com/<your-fork>/botlearn-skills.git
cd botlearn-skills
pnpm install
pnpm build
```

### Useful Commands

```bash
pnpm build                            # Build SDK (tsup)
pnpm typecheck                        # TypeScript type check
node scripts/validate-all.mjs         # Validate all skill manifests
node scripts/cross-regression.mjs     # Cross-regression test
```

## Creating a New Skill

### 1. Scaffold

```bash
npx ts-node scripts/create-skill.ts <skill-name>
```

This generates the standard directory structure under `packages/skills/<skill-name>/`.

### 2. Skill Package Structure

Every skill must follow this structure:

```
packages/skills/<skill-name>/
├── package.json            # name: @botlearn/<skill-name>
├── manifest.json           # category, benchmarkDimension, file declarations
├── SKILL.md                # Role definition, triggers, capability boundaries
├── knowledge/
│   ├── domain.md           # Domain expertise
│   ├── best-practices.md   # Best practices
│   └── anti-patterns.md    # Common anti-patterns
├── strategies/
│   └── main.md             # Step-by-step behavioral strategy
└── tests/
    ├── smoke.json          # 1 task, < 60s, pass threshold 60/100
    └── benchmark.json      # 10 tasks (3 easy / 4 medium / 3 hard)
```

### 3. Key Files

- **manifest.json** — Must pass `node scripts/validate-all.mjs`. Declares category (`information-retrieval`, `content-processing`, `code-assistance`, `creative-generation`), benchmark dimension, and all file paths.
- **SKILL.md** — Uses YAML frontmatter for metadata + Markdown body for role prompt. Define clear triggers, capability boundaries, and activation rules.
- **knowledge/*.md** — Markdown with YAML frontmatter (`domain`, `topic`, `priority`, `ttl`). Injected into Agent Memory on install.
- **strategies/main.md** — Step-by-step Markdown supporting `IF/THEN` conditional logic and `@knowledge/` references.
- **tests/smoke.json** — Single task for quick validation. Must complete in < 60s.
- **tests/benchmark.json** — 10 tasks with rubric items using 0-5 scoring + weights.

### 4. Validate

```bash
node scripts/validate-all.mjs
```

All 20+ skill manifests must pass before submitting.

## Skill Quality Checklist

Before submitting a new or updated skill, ensure:

- [ ] `manifest.json` passes validation
- [ ] `SKILL.md` has proper YAML frontmatter and clear role definition
- [ ] All three knowledge files exist and contain meaningful content
- [ ] `strategies/main.md` has clear, actionable steps
- [ ] `smoke.json` contains at least 1 task
- [ ] `benchmark.json` contains 10 tasks (3 easy / 4 medium / 3 hard)
- [ ] If the skill has dependencies, they are declared in `manifest.json`
- [ ] `package.json` version follows semver

## Submitting Changes

### Branch Naming

- `feature/<skill-name>` — New skill
- `fix/<skill-name>-<issue>` — Bug fix
- `docs/<topic>` — Documentation only
- `refactor/<scope>` — Code refactoring

### Commit Messages

Write clear, descriptive commit messages in Chinese:

```
新增 google-search 技能的高级查询策略

- 添加布尔运算符支持
- 更新 benchmark 测试用例
```

### Pull Request Process

1. Ensure `node scripts/validate-all.mjs` passes
2. Ensure `pnpm typecheck` passes (if SDK changes are involved)
3. Fill in the PR template completely
4. Link related issues
5. Wait for at least one maintainer review

## Coding Standards

### SDK (TypeScript)

- Build with **tsup**
- Strict TypeScript — no `any` types
- Export all public types from `src/types.ts`

### Skills (Markdown + YAML)

- Knowledge files must include YAML frontmatter with `domain`, `topic`, `priority`, `ttl`
- Strategies must use numbered steps
- Benchmark rubric items use 0-5 scoring scale with weights summing to 1.0

### General

- Use English for code, error messages, and file names
- Use Chinese for commit messages, comments, and user-facing documentation

## Reporting Issues

- Use [GitHub Issues](../../issues) with the provided templates
- For **security vulnerabilities**, please see [SECURITY.md](SECURITY.md) — do not open a public issue

## Questions?

Feel free to open a [Discussion](../../discussions) or reach out to the maintainers.

---

Thank you for helping bots learn better!
