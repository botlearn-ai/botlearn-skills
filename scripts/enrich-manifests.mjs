#!/usr/bin/env node
/**
 * enrich-manifests.mjs — Batch-enrich manifest.json with tags, capabilities, and triggers.
 *
 * - triggers: extracted from SKILL.md YAML frontmatter
 * - tags / capabilities: generated from skill metadata + predefined mappings
 *
 * Usage: node scripts/enrich-manifests.mjs [--dry-run]
 */

import { readFileSync, writeFileSync, readdirSync, existsSync } from "node:fs";
import { join, resolve } from "node:path";

const SKILLS_DIR = resolve(import.meta.dirname, "..", "skills");
const DRY_RUN = process.argv.includes("--dry-run");

// ---- Predefined capabilities per skill ----

const CAPABILITIES_MAP = {
  "google-search": ["construct-search-query", "rank-results", "extract-snippets"],
  "academic-search": ["search-academic-papers", "analyze-citations", "screen-abstracts"],
  "rss-manager": ["discover-feeds", "aggregate-content", "filter-updates"],
  "twitter-intel": ["monitor-trends", "extract-thread-context", "sentiment-tracking"],
  "reddit-tracker": ["track-subreddits", "detect-trending-posts", "extract-discussions"],
  "summarizer": ["extract-key-points", "compress-content", "multi-doc-synthesis"],
  "translator": ["detect-language", "translate-text", "preserve-tone"],
  "rewriter": ["transform-style", "adapt-audience", "preserve-facts"],
  "keyword-extractor": ["extract-keywords", "identify-topics", "compute-relevance"],
  "sentiment-analyzer": ["detect-sentiment", "analyze-emotion", "score-polarity"],
  "code-gen": ["generate-code", "scaffold-project", "implement-algorithm"],
  "code-review": ["detect-issues", "suggest-improvements", "assess-quality"],
  "debugger": ["diagnose-bugs", "root-cause-analysis", "suggest-fixes"],
  "refactor": ["apply-patterns", "reduce-complexity", "verify-equivalence"],
  "doc-gen": ["generate-api-docs", "create-readme", "write-changelogs"],
  "writer": ["structure-article", "evidence-argumentation", "style-consistency"],
  "brainstorm": ["generate-ideas", "lateral-thinking", "concept-mapping"],
  "storyteller": ["craft-narrative", "develop-characters", "build-plot"],
  "copywriter": ["apply-persuasion-framework", "optimize-cta", "target-audience"],
  "social-media": ["adapt-platform-format", "optimize-hashtags", "schedule-timing"],
  "openclaw-autodidact": ["self-assess-capability", "discover-skills", "autonomous-learning"],
  "openclaw-doctor": ["diagnose-skill-issues", "repair-configuration", "health-check"],
  "openclaw-examiner": ["evaluate-performance", "generate-benchmarks", "score-capabilities"],
  "openclaw-graduate": ["compose-skill-chains", "orchestrate-workflows", "graduate-assessment"],
  "botlearn": ["validate-manifest", "type-check", "sdk-utilities"],
  "self-improving-agent-1.0.11": ["self-improve", "iterative-refinement", "performance-tracking"],
};

// ---- Tag generation ----

const CATEGORY_TAGS = {
  "information-retrieval": ["search", "retrieval", "information"],
  "content-processing": ["content", "processing", "nlp"],
  "programming-assistance": ["code", "programming", "development"],
  "creative-generation": ["creative", "generation", "writing"],
  "evaluation": ["evaluation", "assessment", "testing"],
  "learning": ["learning", "self-improvement", "autonomous"],
  "meta": ["meta", "sdk", "utilities"],
};

function generateTags(skillName, category, description) {
  const tags = new Set();

  // From skill name
  for (const part of skillName.split("-")) {
    if (part.length > 2) tags.add(part);
  }

  // From category
  for (const tag of CATEGORY_TAGS[category] || []) {
    tags.add(tag);
  }

  // Extract a few salient words from description
  const stopWords = new Set([
    "a", "an", "the", "and", "or", "for", "of", "to", "in", "on", "with",
    "is", "that", "this", "from", "by", "as", "at", "it", "its", "be",
    "openclaw", "agent", "botlearn",
  ]);
  const descWords = description
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, "")
    .split(/\s+/)
    .filter((w) => w.length > 3 && !stopWords.has(w));

  // Pick top keywords (first few unique ones not already in tags)
  let added = 0;
  for (const w of descWords) {
    if (!tags.has(w) && added < 3) {
      tags.add(w);
      added++;
    }
  }

  return [...tags].slice(0, 8);
}

// ---- Extract triggers from SKILL.md YAML frontmatter ----

function extractTriggers(skillDir) {
  const skillMd = join(skillDir, "SKILL.md");
  if (!existsSync(skillMd)) return [];

  const content = readFileSync(skillMd, "utf-8");
  const fmMatch = content.match(/^---\n([\s\S]*?)\n---/);
  if (!fmMatch) return [];

  const yaml = fmMatch[1];
  const triggers = [];
  let inTriggers = false;

  for (const line of yaml.split("\n")) {
    if (/^triggers:\s*$/.test(line)) {
      inTriggers = true;
      continue;
    }
    if (inTriggers) {
      const itemMatch = line.match(/^\s+-\s+"(.+)"$/);
      if (itemMatch) {
        triggers.push(itemMatch[1]);
      } else if (/^\S/.test(line)) {
        break; // next top-level key
      }
    }
  }

  return triggers;
}

// ---- Main ----

const skillDirs = readdirSync(SKILLS_DIR).filter((d) =>
  existsSync(join(SKILLS_DIR, d, "manifest.json"))
);

console.log(`\n📦 Enriching ${skillDirs.length} Skill manifests${DRY_RUN ? " (dry-run)" : ""}\n`);

let updated = 0;
let skipped = 0;

for (const dir of skillDirs.sort()) {
  const manifestPath = join(SKILLS_DIR, dir, "manifest.json");
  const manifest = JSON.parse(readFileSync(manifestPath, "utf-8"));

  const skillName = dir;
  const category = manifest.category || "meta";
  const description = manifest.description || "";

  // Generate enrichment data
  const tags = generateTags(skillName, category, description);
  const capabilities = CAPABILITIES_MAP[skillName] || [];
  const triggers = extractTriggers(join(SKILLS_DIR, dir));

  // Check if already enriched
  if (manifest.tags && manifest.capabilities && manifest.triggers) {
    console.log(`⏭️  ${dir} — already enriched`);
    skipped++;
    continue;
  }

  // Merge (preserve existing if present)
  manifest.tags = manifest.tags || tags;
  manifest.capabilities = manifest.capabilities || capabilities;
  manifest.triggers = manifest.triggers || triggers;

  if (DRY_RUN) {
    console.log(`🔍 ${dir}`);
    console.log(`   tags: [${manifest.tags.join(", ")}]`);
    console.log(`   capabilities: [${manifest.capabilities.join(", ")}]`);
    console.log(`   triggers: [${manifest.triggers.join(", ")}]`);
  } else {
    writeFileSync(manifestPath, JSON.stringify(manifest, null, 2) + "\n");
    console.log(`✅ ${dir} — enriched`);
  }
  updated++;
}

console.log(`\nDone: ${updated} updated, ${skipped} skipped\n`);
