---
strategy: botlearn-doctor
version: 0.1.2
modes: 2
---

# OpenClaw Doctor Strategy

Two operating modes: **Mode 1 — Full Health Check** (all 10 dimensions) and
**Mode 2 — Targeted Check + Fix** (single dimension on user request).

---

## ══════════════════════════════════════════════
## Step 0 — Language Detection (both modes)
## ══════════════════════════════════════════════

Inspect the user's message language and set `REPORT_LANG` before any output.

```
Dimension label map:
  en:    Platform | Version | Config | Logs | Precheck | Skills | Channels | Agent | Gateway | Tools
  zh:    平台     | 版本    | 配置   | 日志 | 预检     | Skills | Channels | Agent | Gateway | 工具
  ja:    プラットフォーム | バージョン | 設定 | ログ | 事前確認 | Skills | Channels | Agent | Gateway | ツール
  ko:    플랫폼 | 버전 | 설정 | 로그 | 사전확인 | Skills | Channels | Agent | Gateway | 도구
  other: use English

Message templates:
  en: "N issues need attention" | "All systems healthy" | "Confirm fixes? [Y/n]"
  zh: "需要处理 N 个问题"       | "运行良好"            | "确认执行修复？[Y/n]"
```

> Rule: All user-facing text (L0–L3 labels, summaries, recommendations, prompts) uses REPORT_LANG.
> Technical commands, JSON keys, script paths, and error codes always remain in English.

---

## ══════════════════════════════════════════════
## Mode 1 — Full Health Check
## ══════════════════════════════════════════════

Trigger: "health check" / "doctor" / "diagnose" / "体检" / no specific dimension named.

### Step 1 — Data Collection

#### 1.1 Parse Flags

- `--full`: expand L3 deep analysis for all flagged dimensions after L2
- `--history`: run `scripts/snapshot-manager.sh history` and return immediately
- `--compare <d1> <d2>`: run `scripts/snapshot-manager.sh compare <d1> <d2>` and return

#### 1.2 Run 8 Collection Scripts in Parallel

```bash
CHECKUP_DIR="data/checkups/$(date +%Y-%m-%d-%H%M%S)"
mkdir -p "$CHECKUP_DIR"

scripts/collect-env.sh      > "$CHECKUP_DIR/env.json"      &  # Dim 1+2: Platform + Version
scripts/collect-config.sh   > "$CHECKUP_DIR/config.json"   &  # Dim 3+8: Config + Agent
scripts/collect-logs.sh     > "$CHECKUP_DIR/logs.json"     &  # Dim 4:   Logs
scripts/collect-precheck.sh > "$CHECKUP_DIR/precheck.json" &  # Dim 5:   Precheck
scripts/collect-skills.sh   > "$CHECKUP_DIR/skills.json"   &  # Dim 6:   Skills
scripts/collect-channels.sh > "$CHECKUP_DIR/channels.json" &  # Dim 7:   Channels
scripts/collect-health.sh   > "$CHECKUP_DIR/health.json"   &  # Dim 9:   Gateway
scripts/collect-tools.sh    > "$CHECKUP_DIR/tools.json"    &  # Dim 10:  Tools
wait
```

If any single script fails → mark that dimension as `⚠️ data unavailable`, continue.
If all scripts fail → report collection failure, suggest checking `requirement.md`.

#### 1.3 Save Snapshot

```bash
scripts/snapshot-manager.sh save "$CHECKUP_DIR"
# Creates: data/checkups/latest -> $CHECKUP_DIR
```

---

### Step 2 — Analysis

#### 2.1 Score All 10 Dimensions

```bash
node -e "
  const fs = require('fs');
  const dir = process.argv[1];
  const data = {};
  for (const k of ['env','config','logs','skills','health','precheck','channels','tools']) {
    try { data[k] = JSON.parse(fs.readFileSync(dir+'/'+k+'.json','utf8')); }
    catch { data[k] = {}; }
  }
  console.log(JSON.stringify(data));
" "$CHECKUP_DIR" | scripts/score-calculator.sh > "$CHECKUP_DIR/analysis.json"
```

`analysis.json` structure:

```json
{
  "overall_status": "pass | warning | error",
  "summary": { "pass": 8, "warning": 1, "error": 1, "total": 10 },
  "dimensions": [
    {
      "id": 1,
      "key": "platform",
      "label_en": "Platform",
      "label_zh": "平台",
      "status": "pass | warning | error",
      "message": "Human-readable summary",
      "issues": [],
      "fix_ref": "PB-xxx"
    }
  ]
}
```

#### 2.2 Historical Comparison

If a previous checkup exists in `data/checkups/latest`:
- Load its `analysis.json` before updating the symlink
- Compare per-dimension status changes
- Flag improved (↑) and degraded (↓) dimensions in the report

---

### Step 3 — Report Output

#### 3.1 L0 — One-line Status (always shown)

```
🏥 OpenClaw Health: {pass}✅ {warn}⚠️ {error}❌ — {REPORT_LANG[action_msg]}
```

Examples:
```
🏥 OpenClaw Health: 8✅ 1⚠️ 1❌ — 2 issues need attention
🏥 OpenClaw Health: 10✅ — All systems healthy
```

#### 3.2 L1 — Dimension Grid (always shown)

Labels use `REPORT_LANG`. Two rows, 5 dimensions each, columns aligned.

```
{dim[1]} ✅ | {dim[2]} ✅ | {dim[3]} ✅ | {dim[4]} ⚠️ | {dim[5]} ✅
{dim[6]} ✅ | {dim[7]} ✅ | {dim[8]} ✅  | {dim[9]} ❌  | {dim[10]} ✅
```

#### 3.3 L2 — Issue Table (only when ⚠️ or ❌ exist)

Column headers in REPORT_LANG. Issue descriptions in REPORT_LANG. Commands in English.

```
| # | Status | {Dimension} | {Issue}                         | {Fix Hint}       |
|---|--------|-------------|---------------------------------|------------------|
| 1 | ❌     | Gateway     | /openclaw endpoint returned 503 | openclaw start   |
| 2 | ⚠️     | Logs        | Error rate 3.2%                 | See PB-009       |
```

Reference `references/fix-playbooks.md` for each issue's fix hint.

#### 3.4 Fix Prompt

```
[REPORT_LANG: Run `clawhub doctor --fix` to auto-repair the issues above]
```

#### 3.5 L3 — Deep Analysis (only on `--full` or explicit user request)

For each ⚠️/❌ dimension, expand in REPORT_LANG:

1. **Findings** — raw data excerpt from collected JSON
2. **Root Cause** — why this happened
3. **Fix Steps** — from `references/fix-playbooks.md` matching `fix_ref`
4. **Rollback** — how to undo the fix
5. **Prevention** — how to avoid recurrence

---

## ══════════════════════════════════════════════
## Mode 2 — Targeted Check + Fix
## ══════════════════════════════════════════════

Trigger: user mentions a specific dimension or asks to fix a particular area.

Examples: "check gateway", "fix skills", "logs have errors", "config 有问题"

### Step 1 — Identify Target Dimension

Map user intent to dimension and script:

```
"gateway" / "port" / "endpoint"         → Dim 9  (Gateway)  → collect-health.sh
"skills" / "clawhub" / "packages"       → Dim 6  (Skills)   → collect-skills.sh
"config" / "configuration" / "json"     → Dim 3+8 (Config+Agent) → collect-config.sh
"logs" / "errors" / "log file"          → Dim 4  (Logs)     → collect-logs.sh
"tools" / "mcp" / "cli tools"           → Dim 10 (Tools)    → collect-tools.sh
"platform" / "memory" / "disk" / "cpu"  → Dim 1  (Platform) → collect-env.sh
"version" / "outdated" / "update"       → Dim 2  (Version)  → collect-env.sh
"precheck" / "self-check"               → Dim 5  (Precheck) → collect-precheck.sh
"channels" / "webhook" / "notify"       → Dim 7  (Channels) → collect-channels.sh
"agent" / "concurrent" / "timeout"      → Dim 8  (Agent)    → collect-config.sh
```

If intent is ambiguous or covers multiple dimensions → fall back to Mode 1 (full check).

### Step 2 — Collect + Analyze Target

```bash
CHECKUP_DIR="data/checkups/$(date +%Y-%m-%d-%H%M%S)-targeted"
mkdir -p "$CHECKUP_DIR"

# Run only the relevant script
scripts/{relevant_script}.sh > "$CHECKUP_DIR/{key}.json"

# Score only the target dimension
node scripts/score-calculator.sh --dimension <id> < "$CHECKUP_DIR/{key}.json" \
  > "$CHECKUP_DIR/analysis.json"
```

### Step 3 — Report + Fix Guidance

#### 3.1 Dimension Status (REPORT_LANG)

```
🏥 {dim_label}: ❌ — {issue description in REPORT_LANG}
```

#### 3.2 Fix Plan

Load matching fix steps from `references/fix-playbooks.md` using the dimension's `fix_ref`.

Present in REPORT_LANG with English commands:

```
[REPORT_LANG: Fix Plan] — {dim_label}

1. [Assess]
   $ {assessment_command}

2. [Fix]
   $ {fix_command}

3. [Verify]
   $ {verify_command}

4. [Rollback if needed]
   $ {rollback_command}
```

#### 3.3 Confirm Before Executing

Ask: `[REPORT_LANG: Confirm fixes? [Y/n]]`

If confirmed:
- Execute each step, display result
- After all fixes → re-run the collection script for that dimension
- Show before/after status comparison in REPORT_LANG

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Collection script fails | Mark dimension as ⚠️ "data unavailable", continue |
| JSON parse error | Treat as empty data, log warning, continue |
| Gateway unreachable | Dim 9 = ❌, proceed with remaining dimensions |
| No previous checkup | Skip trend comparison, note "first checkup" in REPORT_LANG |
| User declines fixes | Save report only, exit gracefully |
| Snapshot save fails | Warn (non-blocking), continue |

## Data Flow

```
Collection (8 scripts) → Save (data/checkups/) → Analysis (score-calculator.sh)
       ↓                         ↓                          ↓
  8 JSON files             latest symlink          analysis.json (10 dimensions)
                                                            ↓
                                                   L0 / L1 / L2 / L3 output
                                                            ↓
                                                   (optional) generate-report.sh
                                                            ↓
                                                   (optional) deliver-report.sh
```
