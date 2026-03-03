# @botlearn/openclaw-doctor v4.0.0

> OpenClaw 智能体检与修复 — 10 维度红绿灯诊断，渐进披露报告，定向修复。

## Installation

```bash
# via clawhub (recommended)
clawhub install @botlearn/openclaw-doctor

# via npm
npm install @botlearn/openclaw-doctor
```

See `requirement.md` for prerequisites and `setup.md` for detailed installation steps.

## Category

Programming Assistance (Diagnostic & Troubleshooting)

## Requirements

- **OS**: macOS (darwin) or Linux
- **Node.js**: >= 18.0.0 (v20+ recommended)
- **CLI**: `clawhub` or `openclaw` (at least one)
- **Tools**: `curl`, `bash >= 4.0`
- **Optional**: `jq` (enhanced JSON processing), `sendmail` (email delivery)

## Architecture

```
8 采集脚本 (parallel)  →  score-calculator.sh  →  渐进披露报告
        ↓                        ↓                     ↓
   8 JSON files          10 维度红绿灯分析        L0 → L1 → L2 → L3
   (data/checkups/)       (analysis.json)          ↓
                                              generate-report.sh
                                                   ↓
                                              deliver-report.sh
```

## What's New in v4.0

- **10 维度体检** — 从 6 维扩展到 10 维（新增：预检、Channels、Agent 配置、内置工具）
- **红绿灯模型** — 每个维度独立判定 ✅/⚠️/❌，替代加权百分制
- **2 核心功能** — 智能体检（幂等）+ 智能修复（定向）
- **渐进披露** — L0 一行状态 → L1 维度网格 → L2 问题清单 → L3 深度分析
- **数据本地化** — 体检数据保存在 `data/checkups/` 目录，按时间组织
- **日志合并** — collect-logs.sh 合并了异常检测逻辑（原 collect-log-anomalies.sh）

## 2 Core Functions

### 功能 1：智能体检（幂等）

```bash
clawhub doctor              # 标准体检 (L0+L1+L2)
clawhub doctor --full       # 深度体检 (L0+L1+L2+L3)
clawhub doctor --history    # 查看历史体检记录
clawhub doctor --compare <date1> <date2>  # 对比体检
```

3 个子步骤：
1. **数据采集** — 并行执行 8 个采集脚本，保存到 `data/checkups/YYYY-MM-DD-HHmmss/`
2. **数据分析** — 10 维度红绿灯评估，生成 `analysis.json`
3. **总结建议** — 渐进披露报告

### 功能 2：智能修复

```bash
clawhub doctor --fix        # 基于最近体检的定向修复
```

3 个子步骤：
1. **问题定位** — 从最近体检中提取 ⚠️/❌ 维度
2. **修复方案** — 匹配 fix-playbooks.md 生成修复步骤
3. **执行验证** — 执行修复命令，重新采集验证

## 10 Dimensions

| # | 维度 | 采集脚本 | 判定 |
|---|------|---------|------|
| 1 | 基础平台 | collect-env.sh | OS、内存、磁盘、CPU |
| 2 | OpenClaw 版本 | collect-env.sh | openclaw/clawhub/Node 版本 |
| 3 | 配置正确性 | collect-config.sh | openclaw.json 完整性 |
| 4 | 日志告警 | collect-logs.sh | 错误率、异常模式 |
| 5 | 预检 | collect-precheck.sh | openclaw doctor 内置检查 |
| 6 | Skills 安装 | collect-skills.sh | 数量、依赖、完整性 |
| 7 | Channels 安装 | collect-channels.sh | 渠道注册与配置 |
| 8 | Agent 配置 | collect-config.sh | maxConcurrent、timeout 合理性 |
| 9 | Gateway 健康 | collect-health.sh | 端点可达性与延迟 |
| 10 | 内置工具 | collect-tools.sh | MCP + CLI 工具可用性 |

## Scoring Model

```
v3.0: 加权百分制 → ENV×0.15 + CONF×0.15 + SKILL×0.20 + RT×0.20 + WS×0.10 + SEC×0.20 = 0-100
v4.0: 红绿灯 → 每个维度 ✅ pass / ⚠️ warning / ❌ error → 汇总

有 ❌ → 整体 ❌ | 无 ❌ 有 ⚠️ → 整体 ⚠️ | 全 ✅ → 整体 ✅
```

## Report Output

### L0 — 一行状态
```
🏥 OpenClaw 体检: 8✅ 1⚠️ 1❌ — 需要处理 2 个问题
```

### L1 — 维度网格
```
 平台 ✅ | 版本 ✅ | 配置 ✅ | 日志 ⚠️ | 预检 ✅
Skills ✅ | Channels ✅ | Agent ✅ | Gateway ❌ | 工具 ✅
```

### L2 — 问题清单
```markdown
| # | 状态 | 维度     | 问题                              | 修复命令                    |
|---|------|---------|----------------------------------|---------------------------|
| 1 | ❌   | Gateway | /openclaw 端点返回 503            | openclaw start             |
| 2 | ⚠️   | 日志    | 错误率 3.2%                       | 查看 PB-009                |
```

### L3 — 深度分析
对单个维度展开：检测结果 → 根因分析 → 修复步骤 → 回滚方案。

## Data Storage

```
data/checkups/
  2026-03-03-110530/
    env.json, config.json, logs.json, skills.json,
    health.json, precheck.json, channels.json, tools.json,
    analysis.json
  latest -> 2026-03-03-110530/
```

## Files

| Path | Description |
|------|-------------|
| `SKILL.md` | 角色定义、触发词、10 维度、2 功能 |
| `requirement.md` | 安装前置要求 |
| `setup.md` | 安装与初始化步骤 |
| `scripts/` | 15 个脚本（8 采集 + 2 保留采集 + 5 工具） |
| `knowledge/` | 领域知识（4 文件） |
| `references/` | 按需参考文档（7 文件） |
| `assets/` | 配置、Schema、模板（5 文件） |
| `strategies/main.md` | 2 功能流程策略 |
| `data/checkups/` | 体检数据存储 |
| `tests/` | Smoke test + 10-task benchmark |

## Dependencies

None (standalone skill).

## Compatibility

- OpenClaw >= 0.5.0
- Gateway WS+HTTP on port 18789

## License

MIT
