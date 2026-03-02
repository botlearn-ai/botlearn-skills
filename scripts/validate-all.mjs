#!/usr/bin/env node
/**
 * Phase 3 Task 23 — Validate all 20 Skill manifest.json files
 *
 * Uses the built validateManifest from dist/index.js (single source of truth).
 */

import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join, resolve } from "node:path";
import { validateManifest } from "../packages/botlearn/dist/index.js";

const SKILLS_DIR = resolve(import.meta.dirname, "..", "packages", "skills");

// ---- Required files per skill (not read, only existence-checked) ----

const REQUIRED_NON_READ_FILES = [
  "SKILL.md",
  "knowledge/domain.md",
  "knowledge/best-practices.md",
  "knowledge/anti-patterns.md",
  "strategies/main.md",
];

// ---- Smoke / Benchmark structure validation ----

function checkRubricWeights(taskId, rubric) {
  if (!Array.isArray(rubric)) return [];
  const weightSum = rubric.reduce((s, r) => s + (r.weight || 0), 0);
  if (Math.abs(weightSum - 1.0) > 0.05)
    return [`task ${taskId || "?"} rubric weights sum to ${weightSum.toFixed(2)}, expected ~1.0`];
  return [];
}

function validateSmokeTest(data) {
  const errors = [];
  if (!data.version) errors.push("missing version");
  if (typeof data.timeout !== "number") errors.push("missing or invalid timeout");
  if (!Array.isArray(data.tasks) || data.tasks.length === 0) errors.push("tasks must be a non-empty array");
  else {
    for (const t of data.tasks) {
      if (!t.id) errors.push(`task missing id`);
      if (!t.input) errors.push(`task ${t.id || "?"} missing input`);
      if (!Array.isArray(t.rubric) || t.rubric.length === 0) errors.push(`task ${t.id || "?"} missing rubric`);
      if (typeof t.passThreshold !== "number") errors.push(`task ${t.id || "?"} missing passThreshold`);
      errors.push(...checkRubricWeights(t.id, t.rubric));
    }
  }
  return errors;
}

function validateBenchmark(data) {
  const errors = [];
  if (!data.version) errors.push("missing version");
  if (!data.dimension) errors.push("missing dimension");
  if (!Array.isArray(data.tasks)) { errors.push("tasks must be an array"); return errors; }
  if (data.tasks.length < 10) errors.push(`expected 10 tasks, found ${data.tasks.length}`);
  const diffs = { easy: 0, medium: 0, hard: 0 };
  for (const t of data.tasks) {
    if (!t.id) errors.push(`task missing id`);
    if (!t.difficulty) errors.push(`task ${t.id || "?"} missing difficulty`);
    else diffs[t.difficulty] = (diffs[t.difficulty] || 0) + 1;
    if (!t.input) errors.push(`task ${t.id || "?"} missing input`);
    if (!Array.isArray(t.rubric) || t.rubric.length === 0) errors.push(`task ${t.id || "?"} missing rubric`);
    if (typeof t.expectedScoreWithout !== "number") errors.push(`task ${t.id || "?"} missing expectedScoreWithout`);
    if (typeof t.expectedScoreWith !== "number") errors.push(`task ${t.id || "?"} missing expectedScoreWith`);
    if (typeof t.expectedScoreWith === "number" && typeof t.expectedScoreWithout === "number" &&
        t.expectedScoreWith <= t.expectedScoreWithout) {
      errors.push(`task ${t.id || "?"} expectedScoreWith (${t.expectedScoreWith}) <= expectedScoreWithout (${t.expectedScoreWithout})`);
    }
    errors.push(...checkRubricWeights(t.id, t.rubric));
  }
  if (diffs.easy < 2) errors.push(`only ${diffs.easy} easy tasks (expected ~3)`);
  if (diffs.medium < 3) errors.push(`only ${diffs.medium} medium tasks (expected ~4)`);
  if (diffs.hard < 2) errors.push(`only ${diffs.hard} hard tasks (expected ~3)`);
  return errors;
}

// ---- Main ----

const skillDirs = readdirSync(SKILLS_DIR).sort();
const knownSkillNames = skillDirs.map((d) => `@botlearn/${d}`);

console.log(`\n🔍 Validating ${skillDirs.length} Skills\n`);
console.log("=".repeat(70));

let totalErrors = 0;
let passCount = 0;

for (const dir of skillDirs) {
  const base = join(SKILLS_DIR, dir);
  const errors = [];

  // Check non-read files exist
  for (const f of REQUIRED_NON_READ_FILES) {
    if (!existsSync(join(base, f))) errors.push(`MISSING FILE: ${f}`);
  }

  // Validate manifest.json
  try {
    const manifest = JSON.parse(readFileSync(join(base, "manifest.json"), "utf-8"));
    const result = validateManifest(manifest, knownSkillNames);
    for (const e of result.errors) errors.push(`manifest: [${e.field}] ${e.message}`);
  } catch (e) {
    errors.push(`manifest: PARSE ERROR — ${e.message}`);
  }

  // Validate smoke.json
  try {
    const smoke = JSON.parse(readFileSync(join(base, "tests", "smoke.json"), "utf-8"));
    const sErrors = validateSmokeTest(smoke);
    for (const e of sErrors) errors.push(`smoke: ${e}`);
  } catch (e) {
    errors.push(`smoke: PARSE ERROR — ${e.message}`);
  }

  // Validate benchmark.json
  try {
    const bench = JSON.parse(readFileSync(join(base, "tests", "benchmark.json"), "utf-8"));
    const bErrors = validateBenchmark(bench);
    for (const e of bErrors) errors.push(`benchmark: ${e}`);
  } catch (e) {
    errors.push(`benchmark: PARSE ERROR — ${e.message}`);
  }

  // Report
  if (errors.length === 0) {
    console.log(`✅ ${dir}`);
    passCount++;
  } else {
    console.log(`❌ ${dir} (${errors.length} error${errors.length > 1 ? "s" : ""})`);
    for (const e of errors) console.log(`   ⤷ ${e}`);
    totalErrors += errors.length;
  }
}

console.log("\n" + "=".repeat(70));
console.log(`\nResult: ${passCount}/${skillDirs.length} passed, ${totalErrors} total errors\n`);

process.exit(totalErrors > 0 ? 1 : 0);
