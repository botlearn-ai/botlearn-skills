---
domain: openclaw-doctor
topic: scoring-model
priority: medium
ttl: 60d
---

# Health Scoring Model v4.0

## Overview

v4.0 使用红绿灯状态模型替代 v3.0 的加权百分制。

```
v3.0: 加权百分制 — ENV×0.15 + CONF×0.15 + SKILL×0.20 + RT×0.20 + WS×0.10 + SEC×0.20 → 0-100 分
v4.0: 红绿灯状态 — 每个维度独立判定 ✅ pass / ⚠️ warning / ❌ error → 汇总统计
```

## Why Traffic Light?

1. **消除精确度错觉** — 72 分和 74 分无实质区别，红绿灯更直观
2. **一眼识别** — 立即看到哪些正常、哪些需关注、哪些必须处理
3. **避免高分掩盖问题** — 百分制下安全维度 0 分但总分仍有 60+，红绿灯中一个 ❌ 即整体 ❌

## 10 Dimensions

| # | 维度 | 英文标识 | 数据来源 | 分析角度 |
|---|------|---------|---------|---------|
| 1 | 基础平台 | Platform | collect-env.sh | OS、内存、磁盘、CPU |
| 2 | OpenClaw 版本 | Version | collect-env.sh | CLI 版本、Node 版本 |
| 3 | 配置正确性 | Config | collect-config.sh | 文件存在、JSON 合法、sections 完整 |
| 4 | 日志告警 | Logs | collect-logs.sh | 错误率、异常模式（spike/OOM/stack trace） |
| 5 | 预检 | Precheck | collect-precheck.sh | openclaw doctor 内置检查输出 |
| 6 | Skills 安装 | Skills | collect-skills.sh | 安装数量、依赖完整性、过期检查 |
| 7 | Channels 安装 | Channels | collect-channels.sh | 渠道注册、启用状态、配置有效性 |
| 8 | Agent 配置 | Agent | collect-config.sh | maxConcurrent、timeout、heartbeat 合理性 |
| 9 | Gateway 健康 | Gateway | collect-health.sh | /、/openclaw、/hooks 端点状态与延迟 |
| 10 | 内置工具 | Tools | collect-tools.sh | MCP tools + CLI tools 可用性 |

**注意**：维度 3 和 8 都来自 collect-config.sh，但分析角度不同（文件完整性 vs 参数合理性）。
维度 1 和 2 都来自 collect-env.sh，但分析不同方面（硬件 vs 软件版本）。

## Overall Status Rule

```
有 ❌ → 整体状态 ❌
无 ❌ 但有 ⚠️ → 整体状态 ⚠️
全部 ✅ → 整体状态 ✅
```

## Per-Dimension Judgment Logic

### ✅ pass
- 满足推荐配置
- 无需任何操作

### ⚠️ warning
- 满足最低配置或有非关键性问题
- 建议改善但不影响正常运行

### ❌ error
- 低于最低要求或有关键问题
- 需要立即处理

## Recheck Intervals

| Status | Recheck |
|--------|---------|
| ✅ pass | 30 days |
| ⚠️ warning | 7 days |
| ❌ error | 1 hour |

## Progressive Disclosure (4 Layers)

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
仅展示 ⚠️ 和 ❌ 的维度，附带修复建议。

### L3 — 深度分析
对单个维度展开详细分析，引用 references/ 下的参考文档。

## Data Storage

体检数据保存在 skill 内部 `data/checkups/` 目录：

```
data/checkups/
  YYYY-MM-DD-HHmmss/
    env.json, config.json, logs.json, skills.json,
    health.json, precheck.json, channels.json, tools.json,
    analysis.json
  latest -> YYYY-MM-DD-HHmmss/
```

默认保留 90 天。

## Migration from v3.0

| v3.0 | v4.0 |
|------|------|
| 6 维度 | 10 维度 |
| 加权百分制 (0-100) | 红绿灯 (✅/⚠️/❌) |
| 8 采集脚本 | 8 采集脚本（3 新 + logs 合并 anomalies） |
| ~/.openclaw/reports/snapshots/ | data/checkups/ |
| 5 阶段管道 | 2 功能（体检 + 修复） |
