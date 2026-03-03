---
strategy: openclaw-doctor
version: 4.0.0
functions: 2
---

# OpenClaw Doctor Strategy — 2 Core Functions

v4.0 聚焦 2 个核心功能：**智能体检**（幂等、可反复执行）和**智能修复**（基于体检结果的定向修复）。
评分模型从加权百分制改为红绿灯状态模型（✅ pass / ⚠️ warning / ❌ error）。

---

## ═══════════════════════════════════════════
## 功能 1：智能体检（clawhub doctor / clawhub doctor --full）
## ═══════════════════════════════════════════

### Step 1: 数据采集

#### 1.1 解析意图

Parse user intent to determine function:

- IF user says "体检" / "health check" / "doctor" / "diagnose" / "check" → **智能体检**
- IF user says "修复" / "fix" / "repair" / "--fix" → **智能修复**（跳转功能 2）
- IF user says "--history" → run `scripts/snapshot-manager.sh history` and return
- IF user says "--compare" → run `scripts/snapshot-manager.sh compare` and return

Additional flags:
- `--full`: 展开 L3 深度分析
- `--format md|html|all`: 报告格式
- `--channel terminal|browser|slack|...`: 投递渠道
- `--open`: 强制在浏览器打开 HTML

#### 1.2 并行执行 8 个采集脚本

```
scripts/collect-env.sh         → env.json         # 维度 1+2: 平台 + 版本
scripts/collect-config.sh      → config.json       # 维度 3+8: 配置 + Agent
scripts/collect-logs.sh        → logs.json         # 维度 4: 日志（含异常检测）
scripts/collect-precheck.sh    → precheck.json     # 维度 5: 预检 (NEW)
scripts/collect-skills.sh      → skills.json       # 维度 6: Skills
scripts/collect-channels.sh    → channels.json     # 维度 7: Channels (NEW)
scripts/collect-health.sh      → health.json       # 维度 9: Gateway
scripts/collect-tools.sh       → tools.json        # 维度 10: 工具 (NEW)
```

IF any script fails → mark that dimension as status "warning" with message "data unavailable", continue.
IF all scripts fail → report collection failure, suggest checking `requirement.md`.

#### 1.3 保存采集数据

```bash
# Create timestamped directory
CHECKUP_DIR=data/checkups/$(date +%Y-%m-%d-%H%M%S)
mkdir -p "$CHECKUP_DIR"

# Save all raw collection data
cp /tmp/doctor-*.json "$CHECKUP_DIR/"

# Save via snapshot-manager
scripts/snapshot-manager.sh save "$CHECKUP_DIR"
```

#### 1.4 创建 latest 软链接

`snapshot-manager.sh save` 自动创建 `data/checkups/latest` → 当前体检目录。

---

### Step 2: 数据分析

#### 2.1 10 维度红绿灯评估

Merge all 8 JSON files and pipe to `scripts/score-calculator.sh`:

```bash
node -e "
  const fs = require('fs');
  const dir = process.argv[1];
  const data = {};
  const mapping = { env:'env', config:'config', logs:'logs', skills:'skills',
                    health:'health', precheck:'precheck', channels:'channels', tools:'tools' };
  for (const [key, file] of Object.entries(mapping)) {
    try { data[key] = JSON.parse(fs.readFileSync(dir+'/'+file+'.json','utf8')); }
    catch { data[key] = {}; }
  }
  console.log(JSON.stringify(data));
" "$CHECKUP_DIR" | scripts/score-calculator.sh > "$CHECKUP_DIR/analysis.json"
```

Output: `analysis.json` containing:
- `overall_status`: pass / warning / error
- `summary`: { pass_count, warning_count, error_count, total: 10 }
- `dimensions[]`: 10 items, each with { id, label, label_en, status, message, issues[] }

#### 2.2 历史对比

IF previous checkup exists (data/checkups/latest points to older directory):
- Load previous analysis.json
- Compare per-dimension status changes
- Flag improved and degraded dimensions

---

### Step 3: 总结建议

#### 3.1 L0 — 一行状态（默认输出）

```
🏥 OpenClaw 体检: 8✅ 1⚠️ 1❌ — 需要处理 2 个问题
```

Format: `🏥 OpenClaw 体检: {pass}✅ {warn}⚠️ {error}❌ — {action_msg}`

#### 3.2 L1 — 维度网格（紧接 L0 后自动展示）

```
 平台 ✅ | 版本 ✅ | 配置 ✅ | 日志 ⚠️ | 预检 ✅
Skills ✅ | Channels ✅ | Agent ✅ | Gateway ❌ | 工具 ✅
```

Two rows, 5 dimensions each, aligned for visual scanning.

#### 3.3 L2 — 问题清单 + 修复建议

ONLY shown when ⚠️ or ❌ dimensions exist:

```markdown
| # | 状态 | 维度     | 问题                              | 修复命令                    |
|---|------|---------|----------------------------------|---------------------------|
| 1 | ❌   | Gateway | /openclaw 端点返回 503            | openclaw start             |
| 2 | ⚠️   | 日志    | 错误率 3.2%，检测到 2 次错误尖峰    | 查看 fix-playbooks.md PB-009 |
```

For each issue, reference `references/fix-playbooks.md` for fix commands.

#### 3.4 提示修复

```
💡 运行 `clawhub doctor --fix` 可自动修复上述问题
```

#### 3.5 L3 — 深度分析

IF `--full` flag or user asks "详细" / "detail":
- For each ⚠️/❌ dimension, expand:
  1. **检测结果**: Raw data excerpt
  2. **根因分析**: Why this happened
  3. **修复步骤**: From `references/fix-playbooks.md`
  4. **回滚方案**: How to undo
  5. **预防措施**: How to avoid recurrence

#### 3.6 可选输出

- IF `--format md|html|all` → run `scripts/generate-report.sh`
- IF `--channel` → run `scripts/deliver-report.sh`
- IF macOS + no --channel specified → auto-open HTML if generated

---

## ═══════════════════════════════════════════
## 功能 2：智能修复（clawhub doctor --fix）
## ═══════════════════════════════════════════

### Step 1: 问题定位

#### 1.1 读取最近体检结果

```bash
# Read latest analysis
LATEST=$(readlink data/checkups/latest 2>/dev/null || ls -d data/checkups/2* | sort | tail -1)
ANALYSIS="data/checkups/$LATEST/analysis.json"
```

#### 1.2 提取问题维度

From `analysis.json`, extract all dimensions where status is ⚠️ or ❌:
- List each dimension's issues with severity and fix_ref

#### 1.3 无数据处理

IF no analysis.json found → automatically run 智能体检 first, then continue.

---

### Step 2: 修复方案

#### 2.1 按影响排序

Sort issues: ❌ error first, then ⚠️ warning.
Within same severity, sort by dimension ID (lower = more fundamental).

#### 2.2 匹配修复步骤

For each issue with `fix_ref`:
- Load corresponding section from `references/fix-playbooks.md`
- Extract: Assess → Backup → Fix → Verify → Rollback steps

For issues without fix_ref:
- Generate contextual fix suggestion based on issue details
- Reference `references/error-patterns.md` or `references/security-checks.md`

#### 2.3 展示修复计划

```markdown
## 修复计划

| # | 维度 | 问题 | 修复操作 | 影响 |
|---|------|------|---------|------|
| 1 | Gateway | 端口不可达 | openclaw start | 恢复 Gateway 服务 |
| 2 | 日志 | 错误率过高 | 清理 + 轮转日志 | 降低错误率 |

确认执行修复? [Y/n]
```

---

### Step 3: 执行验证

#### 3.1 执行修复

IF user confirms:
1. For each fix step:
   a. Display: "正在修复: {issue description}"
   b. Execute fix command
   c. Capture result (success/failure)
   d. IF failure → log error, suggest manual fix, continue to next

#### 3.2 重新采集验证

After fixes applied:
- Re-run ONLY the affected collection scripts (not all 8)
- Re-calculate score for affected dimensions only
- Compare before/after status

#### 3.3 输出修复摘要

```markdown
## 修复结果

| # | 维度 | 修复前 | 修复后 | 状态 |
|---|------|-------|-------|------|
| 1 | Gateway | ❌ | ✅ | 已修复 |
| 2 | 日志 | ⚠️ | ⚠️ | 部分改善 |

🏥 修复后体检: 9✅ 1⚠️ 0❌
```

---

## Error Handling

- Script execution fails → mark dimension as "warning" with "data unavailable", continue
- JSON parse fails → treat as empty data, log warning
- Gateway unreachable → Gateway dimension = ❌, proceed with other dimensions
- No previous checkup for comparison → skip trend, note "首次体检"
- User declines fixes → save report only
- Checkup save fails → warn but continue (non-blocking)
- Channel delivery fails → log error, continue to next channel

## Data Flow Summary

```
采集 (8 scripts)  →  保存 (data/checkups/)  →  分析 (score-calculator.sh)
     ↓                      ↓                          ↓
  8 JSON files         latest symlink           analysis.json (10 维度)
                                                       ↓
                                              L0/L1/L2/L3 报告输出
                                                       ↓
                                              generate-report.sh (可选)
                                                       ↓
                                              deliver-report.sh (可选)
```
