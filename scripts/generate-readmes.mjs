#!/usr/bin/env node
/**
 * 从 package.json 和 manifest.json 自动生成每个 Skill 的 README.md
 */

import { readFileSync, readdirSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";

const SKILLS_DIR = resolve(import.meta.dirname, "..", "packages", "skills");
const dirs = readdirSync(SKILLS_DIR).sort();

let generated = 0;

for (const dir of dirs) {
  const base = join(SKILLS_DIR, dir);
  const pkg = JSON.parse(readFileSync(join(base, "package.json"), "utf-8"));
  const manifest = JSON.parse(readFileSync(join(base, "manifest.json"), "utf-8"));

  const deps = Object.keys(pkg.dependencies || {}).filter((d) =>
    d.startsWith("@botlearn/")
  );
  const depsStr =
    deps.length > 0
      ? deps.map((d) => `\`${d}\``).join(", ")
      : "None";

  const categoryMap = {
    "information-retrieval": "Information Retrieval",
    "content-understanding": "Content Understanding",
    "code-generation": "Code Generation",
    "creative-generation": "Creative Generation",
  };
  const category =
    categoryMap[manifest.category] || manifest.category || "—";

  const readme = `# ${pkg.name}

> ${pkg.description}

## Installation

\`\`\`bash
# via npm
npm install ${pkg.name}

# via clawhub
clawhub install ${pkg.name}
\`\`\`

## Category

${category}

## Dependencies

${depsStr}

## Files

| File | Description |
|------|-------------|
| \`manifest.json\` | Skill metadata and configuration |
| \`SKILL.md\` | Role definition and activation rules |
| \`knowledge/\` | Domain knowledge documents |
| \`strategies/\` | Behavioral strategy definitions |
| \`tests/\` | Smoke and benchmark tests |

## License

MIT
`;

  writeFileSync(join(base, "README.md"), readme, "utf-8");
  console.log(`✅ ${pkg.name}/README.md`);
  generated++;
}

console.log(`\n共生成 ${generated} 个 README.md`);
