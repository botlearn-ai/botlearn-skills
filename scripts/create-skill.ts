#!/usr/bin/env npx tsx
// ============================================================
// BotLearn Skill Scaffold Generator
// Usage: npx tsx scripts/create-skill.ts <skill-name> <category>
// Example: npx tsx scripts/create-skill.ts code-gen programming-assistance
// ============================================================

import { writeFileSync, mkdirSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import type { SkillCategory, BenchmarkDimension } from "../packages/botlearn/src/types.js";
import { VALID_CATEGORIES } from "../packages/botlearn/src/validator.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const CATEGORY_DIMENSIONS: Record<SkillCategory, BenchmarkDimension> = {
  "information-retrieval": "information-retrieval",
  "content-processing": "content-understanding",
  "programming-assistance": "code-generation",
  "creative-generation": "creative-generation",
};

const CATEGORY_LABELS: Record<SkillCategory, string> = {
  "information-retrieval": "Information Retrieval",
  "content-processing": "Content Processing",
  "programming-assistance": "Programming Assistance",
  "creative-generation": "Creative Generation",
};

function main() {
  const [skillName, category] = process.argv.slice(2);

  if (!skillName || !category) {
    console.error(
      "Usage: npx tsx scripts/create-skill.ts <skill-name> <category>"
    );
    console.error(`Categories: ${VALID_CATEGORIES.join(", ")}`);
    process.exit(1);
  }

  if (!/^[a-z][a-z0-9-]*$/.test(skillName)) {
    console.error(`Invalid skill name "${skillName}" — use kebab-case (e.g. code-gen)`);
    process.exit(1);
  }

  if (!VALID_CATEGORIES.includes(category as SkillCategory)) {
    console.error(`Invalid category "${category}"`);
    console.error(`Valid categories: ${VALID_CATEGORIES.join(", ")}`);
    process.exit(1);
  }

  const cat = category as SkillCategory;
  const skillDir = join(__dirname, "..", "packages", "skills", skillName);

  if (existsSync(skillDir)) {
    console.error(`Skill directory already exists: ${skillDir}`);
    process.exit(1);
  }

  // Create directory structure
  mkdirSync(join(skillDir, "knowledge"), { recursive: true });
  mkdirSync(join(skillDir, "strategies"), { recursive: true });
  mkdirSync(join(skillDir, "tests"), { recursive: true });

  // --- manifest.json ---
  const manifest = {
    name: `@botlearn/${skillName}`,
    version: "1.0.0",
    description: `TODO: Describe the ${skillName} skill`,
    category: cat,
    author: "BotLearn",
    benchmarkDimension: CATEGORY_DIMENSIONS[cat],
    expectedImprovement: 30,
    dependencies: {},
    compatibility: {
      openclaw: ">=0.5.0",
    },
    files: {
      skill: "SKILL.md",
      knowledge: [
        "knowledge/domain.md",
        "knowledge/best-practices.md",
        "knowledge/anti-patterns.md",
      ],
      strategies: ["strategies/main.md"],
      smokeTest: "tests/smoke.json",
      benchmark: "tests/benchmark.json",
    },
  };
  writeFileSync(
    join(skillDir, "manifest.json"),
    JSON.stringify(manifest, null, 2) + "\n"
  );

  // --- package.json ---
  const pkg = {
    name: `@botlearn/${skillName}`,
    version: "1.0.0",
    description: manifest.description,
    type: "module",
    main: "manifest.json",
    files: [
      "manifest.json",
      "SKILL.md",
      "knowledge/",
      "strategies/",
      "tests/",
    ],
    keywords: ["botlearn", "openclaw", "skill", cat],
    author: "BotLearn",
    license: "MIT",
  };
  writeFileSync(
    join(skillDir, "package.json"),
    JSON.stringify(pkg, null, 2) + "\n"
  );

  // --- SKILL.md ---
  const titleCase = skillName
    .split("-")
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(" ");
  const skillMd = `---
name: ${skillName}
role: ${titleCase} Specialist
version: 1.0.0
triggers:
  - "TODO: trigger phrase 1"
  - "TODO: trigger phrase 2"
---

# Role

You are a ${titleCase} Specialist. When activated, you perform ${CATEGORY_LABELS[cat].toLowerCase()} tasks with high quality.

# Capabilities

1. TODO: List capability 1
2. TODO: List capability 2
3. TODO: List capability 3

# Constraints

1. TODO: List constraint 1
2. TODO: List constraint 2

# Activation

WHEN the user requests ${skillName.replace(/-/g, " ")}:
1. Analyze the request
2. Execute strategies/main.md
3. Self-review using knowledge/best-practices.md
4. Output results
`;
  writeFileSync(join(skillDir, "SKILL.md"), skillMd);

  // --- knowledge files ---
  const knowledgeFiles: Array<{ file: string; topic: string; priority: string; title: string }> = [
    { file: "knowledge/domain.md", topic: "core-concepts", priority: "high", title: "Domain Knowledge" },
    { file: "knowledge/best-practices.md", topic: "best-practices", priority: "high", title: "Best Practices" },
    { file: "knowledge/anti-patterns.md", topic: "anti-patterns", priority: "medium", title: "Anti-Patterns" },
  ];
  for (const { file, topic, priority, title } of knowledgeFiles) {
    writeFileSync(join(skillDir, file), `---
domain: ${skillName}
topic: ${topic}
priority: ${priority}
ttl: 30d
---

# ${titleCase} — ${title}

TODO: Add ${topic.replace(/-/g, " ")} for this skill.
`);
  }

  // --- strategies/main.md ---
  const strategyMd = `---
strategy: ${skillName}
version: 1.0.0
steps: 4
---

# ${titleCase} Strategy

## Step 1: Input Analysis
- Parse the user's request
- IF requirements are ambiguous THEN ask clarifying questions
- Identify key parameters and constraints

## Step 2: Execution
- Apply domain knowledge from knowledge/domain.md
- Follow best practices from knowledge/best-practices.md
- Avoid anti-patterns from knowledge/anti-patterns.md

## Step 3: Quality Check
- Verify output meets acceptance criteria
- Check for common mistakes
- Assess confidence level

## Step 4: Output
- Present results in structured format
- Include confidence score (1-5)
- Note any caveats or limitations
`;
  writeFileSync(join(skillDir, "strategies/main.md"), strategyMd);

  // --- tests/smoke.json ---
  const smokeTest = {
    version: "1.0.0",
    timeout: 60,
    tasks: [
      {
        id: "smoke-01",
        description: `TODO: Describe the smoke test task for ${skillName}`,
        input: "TODO: Provide the test input",
        rubric: [
          {
            criterion: "Completeness",
            weight: 0.4,
            scoring: {
              "5": "All required elements present and well-formed",
              "3": "Most elements present, minor gaps",
              "1": "Significant elements missing",
              "0": "Output missing or unusable",
            },
          },
          {
            criterion: "Quality",
            weight: 0.4,
            scoring: {
              "5": "Excellent quality, exceeds expectations",
              "3": "Acceptable quality, meets basic expectations",
              "1": "Poor quality, barely usable",
              "0": "Unusable output",
            },
          },
          {
            criterion: "Accuracy",
            weight: 0.2,
            scoring: {
              "5": "Fully accurate, no errors",
              "3": "Mostly accurate, minor errors",
              "1": "Multiple inaccuracies",
              "0": "Fundamentally incorrect",
            },
          },
        ],
        passThreshold: 60,
      },
    ],
  };
  writeFileSync(
    join(skillDir, "tests/smoke.json"),
    JSON.stringify(smokeTest, null, 2) + "\n"
  );

  // --- tests/benchmark.json ---
  const benchmarkTest = {
    version: "1.0.0",
    dimension: CATEGORY_DIMENSIONS[cat],
    tasks: [
      { difficulty: "easy", prefix: "bench-easy" },
      { difficulty: "easy", prefix: "bench-easy" },
      { difficulty: "easy", prefix: "bench-easy" },
      { difficulty: "medium", prefix: "bench-med" },
      { difficulty: "medium", prefix: "bench-med" },
      { difficulty: "medium", prefix: "bench-med" },
      { difficulty: "medium", prefix: "bench-med" },
      { difficulty: "hard", prefix: "bench-hard" },
      { difficulty: "hard", prefix: "bench-hard" },
      { difficulty: "hard", prefix: "bench-hard" },
    ].map((t, i) => ({
      id: `${t.prefix}-${String(i + 1).padStart(2, "0")}`,
      difficulty: t.difficulty,
      description: `TODO: Describe benchmark task ${i + 1}`,
      input: "TODO: Provide test input",
      rubric: [
        {
          criterion: "Completeness",
          weight: 0.3,
          scoring: {
            "5": "All required elements present",
            "3": "Most elements present",
            "1": "Significant gaps",
            "0": "Unusable",
          },
        },
        {
          criterion: "Quality",
          weight: 0.4,
          scoring: {
            "5": "Excellent quality",
            "3": "Acceptable quality",
            "1": "Poor quality",
            "0": "Unusable",
          },
        },
        {
          criterion: "Accuracy",
          weight: 0.3,
          scoring: {
            "5": "Fully accurate",
            "3": "Mostly accurate",
            "1": "Multiple errors",
            "0": "Incorrect",
          },
        },
      ],
      expectedScoreWithout: 35,
      expectedScoreWith: 70,
    })),
  };
  writeFileSync(
    join(skillDir, "tests/benchmark.json"),
    JSON.stringify(benchmarkTest, null, 2) + "\n"
  );

  console.log(`✅ Created skill scaffold: packages/skills/${skillName}/`);
  console.log(`   ├── package.json`);
  console.log(`   ├── manifest.json`);
  console.log(`   ├── SKILL.md`);
  console.log(`   ├── knowledge/`);
  console.log(`   │   ├── domain.md`);
  console.log(`   │   ├── best-practices.md`);
  console.log(`   │   └── anti-patterns.md`);
  console.log(`   ├── strategies/`);
  console.log(`   │   └── main.md`);
  console.log(`   └── tests/`);
  console.log(`       ├── smoke.json`);
  console.log(`       └── benchmark.json`);
  console.log(`\nNext: Fill in TODO placeholders with skill-specific content.`);
}

main();
