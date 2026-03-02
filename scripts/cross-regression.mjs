#!/usr/bin/env node
/**
 * Phase 3 Task 24 — Cross-regression testing
 *
 * Simulates topological install order and validates:
 * 1. All dependencies are resolvable before installation
 * 2. Smoke test structure is valid for each skill
 * 3. Benchmark test structure is valid for each skill
 * 4. No rubric weight anomalies across the full corpus
 */

import { readFileSync, readdirSync } from "node:fs";
import { join, resolve } from "node:path";

const SKILLS_DIR = resolve(import.meta.dirname, "..", "packages", "skills");

// ---- Load all manifests ----

const skillDirs = readdirSync(SKILLS_DIR).sort();
const manifests = new Map();

for (const dir of skillDirs) {
  const data = JSON.parse(
    readFileSync(join(SKILLS_DIR, dir, "manifest.json"), "utf-8")
  );
  manifests.set(data.name, { dir, data });
}

// ---- Topological sort ----

function topoSort(manifests) {
  const visited = new Set();
  const order = [];
  const visiting = new Set();

  function visit(name) {
    if (visited.has(name)) return;
    if (visiting.has(name)) throw new Error(`Circular dependency: ${name}`);
    visiting.add(name);
    const info = manifests.get(name);
    if (!info) throw new Error(`Unknown skill: ${name}`);
    const deps = info.data.dependencies || {};
    for (const depName of Object.keys(deps)) {
      visit(depName);
    }
    visiting.delete(name);
    visited.add(name);
    order.push(name);
  }

  for (const name of manifests.keys()) visit(name);
  return order;
}

// ---- Rubric weight check ----

function checkRubricWeights(taskId, rubric) {
  const ws = rubric.reduce((s, r) => s + r.weight, 0);
  if (Math.abs(ws - 1.0) > 0.05) {
    return `task ${taskId}: weight sum ${ws.toFixed(2)}`;
  }
  return null;
}

// ---- Simulation ----

console.log(`\n📦 Cross-Regression Test — Topological Install Simulation\n`);
console.log("=".repeat(70));

let installOrder;
let circularDetected = false;
try {
  installOrder = topoSort(manifests);
} catch (e) {
  circularDetected = true;
  console.error(`\n❌ FATAL: ${e.message}\n`);
  process.exit(1);
}

console.log(`\nInstall order (${installOrder.length} skills):\n`);
installOrder.forEach((name, i) => {
  const info = manifests.get(name);
  const deps = Object.keys(info.data.dependencies || {});
  const depStr = deps.length > 0 ? ` ← [${deps.map(d => d.replace("@botlearn/", "")).join(", ")}]` : "";
  console.log(`  ${String(i + 1).padStart(2)}. ${name}${depStr}`);
});

console.log("\n" + "=".repeat(70));
console.log("\n🔄 Simulating sequential install with validation...\n");

const installed = new Set();
let totalSmokeTasks = 0;
let totalBenchTasks = 0;
let errors = 0;

// Pre-load all smoke.json files once
const smokeCache = new Map();
for (const [skillName, info] of manifests) {
  try {
    const smoke = JSON.parse(readFileSync(join(SKILLS_DIR, info.dir, "tests", "smoke.json"), "utf-8"));
    smokeCache.set(skillName, smoke);
  } catch (e) {
    smokeCache.set(skillName, null);
  }
}

for (const skillName of installOrder) {
  const info = manifests.get(skillName);
  const base = join(SKILLS_DIR, info.dir);
  const shortName = skillName.replace("@botlearn/", "");
  const installErrors = [];

  // 1. Dependency check
  const deps = Object.keys(info.data.dependencies || {});
  for (const dep of deps) {
    if (!installed.has(dep)) {
      installErrors.push(`DEPENDENCY NOT INSTALLED: ${dep}`);
    }
  }

  // 2. Validate smoke test
  const smoke = smokeCache.get(skillName);
  if (smoke === null) {
    installErrors.push(`smoke.json: failed to parse`);
  } else if (smoke) {
    for (const task of smoke.tasks) {
      totalSmokeTasks++;
      const weightErr = checkRubricWeights(task.id, task.rubric);
      if (weightErr) installErrors.push(`smoke ${weightErr}`);
    }
  }

  // 3. Load & validate benchmark
  try {
    const bench = JSON.parse(readFileSync(join(base, "tests", "benchmark.json"), "utf-8"));
    for (const task of bench.tasks) {
      totalBenchTasks++;
      const weightErr = checkRubricWeights(task.id, task.rubric);
      if (weightErr) installErrors.push(`bench ${weightErr}`);
      if (task.expectedScoreWith <= task.expectedScoreWithout) {
        installErrors.push(`bench task ${task.id}: expectedScoreWith (${task.expectedScoreWith}) <= expectedScoreWithout (${task.expectedScoreWithout})`);
      }
    }
  } catch (e) {
    installErrors.push(`benchmark.json: ${e.message}`);
  }

  installed.add(skillName);

  const status = installErrors.length === 0 ? "✅" : "❌";
  const depsStr = deps.length > 0 ? ` (deps: ${deps.map(d => d.replace("@botlearn/", "")).join(", ")})` : "";
  console.log(`${status} Install #${String(installed.size).padStart(2)}: ${shortName}${depsStr}`);

  if (installErrors.length > 0) {
    for (const e of installErrors) console.log(`   ⤷ ${e}`);
    errors += installErrors.length;
  }
}

// ---- Summary ----

console.log("\n" + "=".repeat(70));
console.log("\n📊 Regression Matrix Summary:\n");
console.log(`  Total skills installed:     ${installed.size}`);
console.log(`  Total smoke test tasks:     ${totalSmokeTasks}`);
console.log(`  Total benchmark tasks:      ${totalBenchTasks}`);
console.log(`  Total corpus tasks:         ${totalSmokeTasks + totalBenchTasks}`);
console.log(`  Dependency graph errors:    ${errors > 0 ? errors : "0 (clean)"}`);
console.log(`  Circular dependencies:      ${circularDetected ? "DETECTED" : "None"}`);

console.log("\n" + "=".repeat(70));
if (errors === 0) {
  console.log("\n✅ All cross-regression checks passed!\n");
} else {
  console.log(`\n❌ ${errors} error(s) found — see details above.\n`);
}

process.exit(errors > 0 ? 1 : 0);
