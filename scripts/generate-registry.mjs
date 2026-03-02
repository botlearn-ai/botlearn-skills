#!/usr/bin/env node
/**
 * generate-registry.mjs — Aggregate all manifest.json into a unified skills-registry.json.
 *
 * Outputs to:
 *   1. <root>/skills-registry.json                    (GitHub Raw URL access)
 *   2. <root>/packages/botlearn/registry/skills-registry.json  (npm package)
 *
 * Usage: node scripts/generate-registry.mjs
 */

import {
  readFileSync,
  writeFileSync,
  readdirSync,
  existsSync,
  mkdirSync,
} from "node:fs";
import { join, resolve } from "node:path";

const ROOT = resolve(import.meta.dirname, "..");
const SKILLS_DIR = join(ROOT, "skills");
const OUT_ROOT = join(ROOT, "skills-registry.json");
const OUT_PKG = join(ROOT, "packages", "botlearn", "registry", "skills-registry.json");

// ---- Collect manifests ----

const skillDirs = readdirSync(SKILLS_DIR)
  .filter((d) => existsSync(join(SKILLS_DIR, d, "manifest.json")))
  .sort();

const skills = [];
const categories = {};
const depGraph = {};

for (const dir of skillDirs) {
  const manifest = JSON.parse(
    readFileSync(join(SKILLS_DIR, dir, "manifest.json"), "utf-8")
  );

  const entry = {
    name: manifest.name,
    version: manifest.version,
    description: manifest.description,
    category: manifest.category,
    benchmarkDimension: manifest.benchmarkDimension,
    expectedImprovement: manifest.expectedImprovement,
    tags: manifest.tags || [],
    capabilities: manifest.capabilities || [],
    triggers: manifest.triggers || [],
    dependencies: manifest.dependencies || {},
    dependents: [], // filled below
    compatibility: manifest.compatibility,
    npm: `https://www.npmjs.com/package/${manifest.name}`,
  };

  skills.push(entry);

  // Categories
  const cat = manifest.category;
  if (!categories[cat]) categories[cat] = [];
  categories[cat].push(manifest.name);

  // Dependency graph
  depGraph[manifest.name] = Object.keys(manifest.dependencies || {});
}

// ---- Fill dependents ----

for (const skill of skills) {
  for (const depName of Object.keys(skill.dependencies)) {
    const dep = skills.find((s) => s.name === depName);
    if (dep && !dep.dependents.includes(skill.name)) {
      dep.dependents.push(skill.name);
    }
  }
}

// ---- Install groups ----

const installGroups = {
  "starter-pack": {
    description: "Essential skills for getting started — search, summarize, and translate",
    skills: ["@botlearn/google-search", "@botlearn/summarizer", "@botlearn/translator"],
  },
  "developer-pack": {
    description: "Full programming assistance — code generation, review, debug, refactor, and docs",
    skills: [
      "@botlearn/code-gen",
      "@botlearn/code-review",
      "@botlearn/debugger",
      "@botlearn/refactor",
      "@botlearn/doc-gen",
    ],
  },
  "content-pack": {
    description: "Content processing toolkit — summarize, translate, rewrite, and extract keywords",
    skills: [
      "@botlearn/summarizer",
      "@botlearn/translator",
      "@botlearn/rewriter",
      "@botlearn/keyword-extractor",
      "@botlearn/sentiment-analyzer",
    ],
  },
  "creative-pack": {
    description: "Creative writing suite — write, brainstorm, tell stories, and produce marketing copy",
    skills: [
      "@botlearn/writer",
      "@botlearn/brainstorm",
      "@botlearn/storyteller",
      "@botlearn/copywriter",
      "@botlearn/social-media",
    ],
  },
  "research-pack": {
    description: "Multi-source research — web, academic, RSS, Twitter, and Reddit",
    skills: [
      "@botlearn/google-search",
      "@botlearn/academic-search",
      "@botlearn/rss-manager",
      "@botlearn/twitter-intel",
      "@botlearn/reddit-tracker",
    ],
  },
};

// ---- Build registry ----

const registry = {
  version: "0.1.0",
  generatedAt: new Date().toISOString(),
  skills,
  categories,
  dependencyGraph: depGraph,
  installGroups,
};

// ---- Write output ----

const json = JSON.stringify(registry, null, 2) + "\n";

// Ensure output directories exist
mkdirSync(join(ROOT, "packages", "botlearn", "registry"), { recursive: true });

writeFileSync(OUT_ROOT, json);
writeFileSync(OUT_PKG, json);

console.log(`\n📦 Generated skills-registry.json`);
console.log(`   Skills: ${skills.length}`);
console.log(`   Categories: ${Object.keys(categories).length}`);
console.log(`   Install groups: ${Object.keys(installGroups).length}`);
console.log(`\n   → ${OUT_ROOT}`);
console.log(`   → ${OUT_PKG}\n`);
