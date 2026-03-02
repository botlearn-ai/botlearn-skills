#!/usr/bin/env node
/**
 * BotLearn 半自动发布脚本
 *
 * 用法:
 *   node scripts/publish.mjs                                      # 发布到默认 npm registry
 *   node scripts/publish.mjs --dry-run                            # 模拟发布
 *   node scripts/publish.mjs --registry https://npm.skills.ai     # 发布到 skills.ai
 *   node scripts/publish.mjs --version 0.2.0                      # 升版后发布
 *   node scripts/publish.mjs --tag beta                           # 以 beta 标签发布
 *   node scripts/publish.mjs --clawhub                            # 同时执行 clawhub publish
 *   node scripts/publish.mjs --skip-validation                    # 跳过验证步骤
 */

import { execSync } from "node:child_process";
import { existsSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { parseArgs } from "node:util";

// ---- 参数解析 ----

const { values: args } = parseArgs({
  options: {
    "dry-run": { type: "boolean", default: false },
    registry: { type: "string" },
    version: { type: "string" },
    tag: { type: "string" },
    "skip-validation": { type: "boolean", default: false },
    clawhub: { type: "boolean", default: false },
    help: { type: "boolean", default: false },
  },
  strict: true,
});

if (args.help) {
  console.log(`
BotLearn 发布脚本

用法:
  node scripts/publish.mjs [options]

选项:
  --dry-run            模拟发布，不实际推送
  --registry <url>     指定 npm registry URL
  --version <ver>      统一升版后发布（如 0.2.0）
  --tag <tag>          npm dist-tag（如 beta, next）
  --skip-validation    跳过 validate-all 和 cross-regression
  --clawhub            同时执行 clawhub publish
  --help               显示帮助
`);
  process.exit(0);
}

// ---- 常量 ----

const ROOT = resolve(import.meta.dirname, "..");
const SDK_DIR = join(ROOT, "packages", "botlearn");
const SKILLS_DIR = join(ROOT, "packages", "skills");

// ---- 工具函数 ----

function exec(cmd, opts = {}) {
  return execSync(cmd, { encoding: "utf-8", cwd: ROOT, ...opts });
}

function readJSON(p) {
  return JSON.parse(readFileSync(p, "utf-8"));
}

function writeJSON(p, data) {
  writeFileSync(p, JSON.stringify(data, null, 2) + "\n", "utf-8");
}

// ---- Step 1: 预检查 ----

function preflight() {
  console.log("\n=== Step 1: 预检查 ===\n");

  // git 工作区
  const gitStatus = exec("git status --porcelain").trim();
  if (gitStatus) {
    console.warn("  ⚠️  工作区有未提交的更改:");
    for (const line of gitStatus.split("\n").slice(0, 10)) {
      console.warn(`     ${line}`);
    }
    console.log();
  }

  // npm 登录
  const registryFlag = args.registry ? `--registry ${args.registry}` : "";
  try {
    const user = exec(`npm whoami ${registryFlag}`).trim();
    console.log(`  ✅ npm 已登录: ${user}`);
  } catch {
    console.error(
      `  ❌ 未登录到 npm registry${args.registry ? ` (${args.registry})` : ""}`
    );
    console.error("     请先执行: npm login" + (args.registry ? ` --registry ${args.registry}` : ""));
    process.exit(1);
  }

  // LICENSE 文件
  if (!existsSync(join(ROOT, "LICENSE"))) {
    console.error("  ❌ 根目录缺少 LICENSE 文件");
    process.exit(1);
  }
  console.log("  ✅ LICENSE 文件存在");

  // SDK dist
  if (!existsSync(join(SDK_DIR, "dist", "index.js"))) {
    console.warn("  ⚠️  SDK 尚未构建（dist/ 不存在），将在 Step 3 构建");
  } else {
    console.log("  ✅ SDK dist/ 已存在");
  }

  // Skill README 检查
  const dirs = readdirSync(SKILLS_DIR).sort();
  const missingReadme = dirs.filter(
    (d) => !existsSync(join(SKILLS_DIR, d, "README.md"))
  );
  if (missingReadme.length > 0) {
    console.warn(`  ⚠️  ${missingReadme.length} 个 Skill 缺少 README.md:`);
    console.warn(`     ${missingReadme.join(", ")}`);
    console.warn("     运行: node scripts/generate-readmes.mjs");
  } else {
    console.log("  ✅ 所有 Skill 均有 README.md");
  }
}

// ---- Step 2: 验证 ----

function validate() {
  if (args["skip-validation"]) {
    console.log("\n=== Step 2: 验证（已跳过） ===\n");
    return;
  }
  console.log("\n=== Step 2: 验证 ===\n");

  console.log("  运行 validate-all...");
  exec("node scripts/validate-all.mjs", { stdio: "inherit" });

  console.log("  运行 cross-regression...");
  exec("node scripts/cross-regression.mjs", { stdio: "inherit" });

  console.log("  ✅ 全部验证通过\n");
}

// ---- Step 3: 构建 SDK ----

function buildSDK() {
  console.log("\n=== Step 3: 构建 SDK ===\n");
  exec("pnpm build", { cwd: SDK_DIR, stdio: "inherit" });
  console.log("\n  ✅ SDK 构建完成");
}

// ---- Step 4: 版本更新 ----

function updateVersions(newVersion) {
  console.log(`\n=== Step 4: 版本更新 → ${newVersion} ===\n`);

  // SDK
  const sdkPkg = readJSON(join(SDK_DIR, "package.json"));
  if (sdkPkg.version !== newVersion) {
    console.log(`  botlearn: ${sdkPkg.version} → ${newVersion}`);
    sdkPkg.version = newVersion;
    writeJSON(join(SDK_DIR, "package.json"), sdkPkg);
  }

  // Skill 包
  const dirs = readdirSync(SKILLS_DIR).sort();
  for (const dir of dirs) {
    const pkgPath = join(SKILLS_DIR, dir, "package.json");
    const pkg = readJSON(pkgPath);
    if (pkg.version !== newVersion) {
      console.log(`  ${pkg.name}: ${pkg.version} → ${newVersion}`);
      pkg.version = newVersion;
      writeJSON(pkgPath, pkg);
    }

    // manifest.json 同步
    const manifestPath = join(SKILLS_DIR, dir, "manifest.json");
    const manifest = readJSON(manifestPath);
    if (manifest.version !== newVersion) {
      manifest.version = newVersion;
      writeJSON(manifestPath, manifest);
    }
  }

  console.log("\n  ✅ 版本更新完成");
}

// ---- Step 5: 拓扑排序 ----

function buildPublishOrder() {
  console.log("\n=== Step 5: 计算发布顺序 ===\n");

  const dirs = readdirSync(SKILLS_DIR).sort();
  const packages = new Map();

  for (const dir of dirs) {
    const pkg = readJSON(join(SKILLS_DIR, dir, "package.json"));
    const deps = Object.keys(pkg.dependencies || {}).filter((d) =>
      d.startsWith("@botlearn/")
    );
    packages.set(pkg.name, { dir, deps });
  }

  // 拓扑排序
  const visited = new Set();
  const visiting = new Set();
  const order = [];

  function visit(name) {
    if (visited.has(name)) return;
    if (visiting.has(name)) throw new Error(`Circular dependency: ${name}`);
    visiting.add(name);
    const info = packages.get(name);
    if (!info) throw new Error(`Unknown package: ${name}`);
    for (const dep of info.deps) visit(dep);
    visiting.delete(name);
    visited.add(name);
    order.push({ name, dir: info.dir, deps: info.deps });
  }

  for (const name of packages.keys()) visit(name);

  // 打印分层
  const noDeps = order.filter((p) => p.deps.length === 0);
  const hasDeps = order.filter((p) => p.deps.length > 0);

  console.log("  Layer 0: botlearn (SDK)");
  console.log(
    `  Layer 1: ${noDeps.map((p) => p.name.replace("@botlearn/", "")).join(", ")}`
  );
  if (hasDeps.length > 0) {
    console.log(
      `  Layer 2: ${hasDeps.map((p) => p.name.replace("@botlearn/", "")).join(", ")}`
    );
  }

  return order;
}

// ---- Step 6: 发布 ----

function publish(order) {
  const flags = [];
  if (args.registry) flags.push(`--registry ${args.registry}`);
  if (args.tag) flags.push(`--tag ${args.tag}`);
  if (args["dry-run"]) flags.push("--dry-run");
  flags.push("--access public");
  flags.push("--no-git-checks");
  const commonFlags = flags.join(" ");

  const mode = args["dry-run"] ? "[DRY-RUN]" : "[PUBLISH]";
  console.log(`\n=== Step 6: 发布 (${mode}) ===\n`);

  // 6a. SDK
  console.log(`  ${mode} botlearn (SDK)...`);
  try {
    exec(`pnpm publish ${commonFlags}`, { cwd: SDK_DIR, stdio: "inherit" });
    console.log(`  ✅ botlearn\n`);
  } catch (e) {
    if (String(e).includes("previously published") || String(e).includes("already exists")) {
      console.log(`  ⏭️  botlearn — 版本已存在，跳过\n`);
    } else {
      throw e;
    }
  }

  // 6b. Skill 包（拓扑序）
  for (const { name, dir } of order) {
    const pkgDir = join(SKILLS_DIR, dir);
    console.log(`  ${mode} ${name}...`);
    try {
      exec(`pnpm publish ${commonFlags}`, { cwd: pkgDir, stdio: "inherit" });
      console.log(`  ✅ ${name}\n`);
    } catch (e) {
      if (String(e).includes("previously published") || String(e).includes("already exists")) {
        console.log(`  ⏭️  ${name} — 版本已存在，跳过\n`);
      } else {
        console.error(`  ❌ ${name} 发布失败`);
        throw e;
      }
    }
  }
}

// ---- Step 7: clawhub publish ----

function clawhubPublish(order) {
  if (!args.clawhub) return;

  console.log("\n=== Step 7: clawhub publish ===\n");

  // 检查 clawhub CLI
  try {
    exec("clawhub --version");
  } catch {
    console.error("  ❌ clawhub CLI 未安装，跳过 clawhub 发布");
    return;
  }

  const dryRunFlag = args["dry-run"] ? "--dry-run" : "";

  for (const { name, dir } of order) {
    const pkgDir = join(SKILLS_DIR, dir);
    console.log(`  clawhub publish ${name}...`);
    try {
      exec(`clawhub publish ${dryRunFlag}`, { cwd: pkgDir, stdio: "inherit" });
      console.log(`  ✅ ${name}\n`);
    } catch (e) {
      console.error(`  ⚠️  ${name} clawhub 发布失败: ${String(e).split("\n")[0]}\n`);
    }
  }
}

// ---- Main ----

function main() {
  console.log("\n🚀 BotLearn 发布流程\n");
  console.log(`  模式:     ${args["dry-run"] ? "DRY-RUN（模拟）" : "正式发布"}`);
  if (args.registry) console.log(`  Registry: ${args.registry}`);
  if (args.version) console.log(`  版本:     ${args.version}`);
  if (args.tag) console.log(`  Tag:      ${args.tag}`);
  if (args.clawhub) console.log(`  Clawhub:  启用`);

  preflight();
  validate();
  buildSDK();

  if (args.version) {
    updateVersions(args.version);
  }

  const order = buildPublishOrder();
  publish(order);
  clawhubPublish(order);

  console.log("\n" + "=".repeat(50));
  console.log("✅ 发布流程完成!");
  console.log("=".repeat(50) + "\n");
}

main();
