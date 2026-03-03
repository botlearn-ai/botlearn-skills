---
domain: openclaw-doctor
topic: best-practices
priority: high
ttl: 30d
---

# Health Check Best Practices

## 10 维度红绿灯判定标准

### 维度 1: 基础平台

| 指标 | ✅ pass | ⚠️ warning | ❌ error |
|------|---------|-----------|---------|
| Node.js | v20+ LTS | v18.x | < v18 |
| Memory available | > 30% | 15-30% | < 15% |
| Disk available | > 20% | 10-20% | < 10% |
| CPU load/core | < 0.7 | 0.7-0.9 | > 0.9 |

### 维度 2: OpenClaw 版本

| 指标 | ✅ pass | ⚠️ warning | ❌ error |
|------|---------|-----------|---------|
| openclaw CLI | Latest version | Older but usable | Not installed |
| clawhub CLI | Latest version | Older but usable | Neither CLI found |
| Node.js | v20+ LTS | v18.x | < v18 |

### 维度 3: 配置正确性

| 指标 | ✅ pass | ⚠️ warning | ❌ error |
|------|---------|-----------|---------|
| Config file | Exists | — | Missing |
| JSON validity | Valid | — | Parse failure |
| Required sections | All 5 present | Optional missing | gateway/agents missing |

### 维度 4: 日志告警

| 指标 | ✅ pass | ⚠️ warning | ❌ error |
|------|---------|-----------|---------|
| Error rate | < 1% | 1-10% | > 10% |
| OOM/segfault | None | — | Detected |
| Error spikes | None | Detected | — |
| Log size | < 500MB | — | > 500MB |

### 维度 5: 预检

| 指标 | ✅ pass | ⚠️ warning | ❌ error |
|------|---------|-----------|---------|
| openclaw doctor | All pass | Has warnings | Has errors |

### 维度 6: Skills 安装

| 指标 | ✅ pass | ⚠️ warning | ❌ error |
|------|---------|-----------|---------|
| Installed count | ≥ 3 | 1-2 | 0 |
| Dependencies | All intact | Has outdated | Broken deps |
| File integrity | Complete | Missing optional | Missing required |

### 维度 7: Channels 安装

| 指标 | ✅ pass | ⚠️ warning | ❌ error |
|------|---------|-----------|---------|
| Channel config | Valid + enabled | All disabled | Missing/corrupt |

### 维度 8: Agent 配置

| 指标 | ✅ pass | ⚠️ warning | ❌ error |
|------|---------|-----------|---------|
| maxConcurrent | 1-10 | 11-20 | > 20 |
| timeoutSeconds | 30-1800s | 1801-3600s | > 3600s |
| heartbeat | 5-120min | Outside range | — |

### 维度 9: Gateway 健康

| 指标 | ✅ pass | ⚠️ warning | ❌ error |
|------|---------|-----------|---------|
| Root endpoint | Reachable | — | Unreachable |
| /openclaw | Responsive | — | Not responsive |
| Endpoints | All healthy | Some unhealthy | — |
| Latency | < 500ms | > 500ms | — |

### 维度 10: 内置工具

| 指标 | ✅ pass | ⚠️ warning | ❌ error |
|------|---------|-----------|---------|
| Core CLI tools | All available | — | Missing |
| Core MCP tools | All available | — | Missing |
| Optional tools | All available | Some missing | — |

## Configuration Guidelines

| Setting | Recommended | Range |
|---------|-------------|-------|
| `agents.defaults.maxConcurrent` | Based on skill count | 1-10 |
| `agents.defaults.timeoutSeconds` | 600s | 30-1800s |
| `agents.heartbeat.intervalMinutes` | 30 | 5-120 |

### maxConcurrent by Workload

| Skills Installed | maxConcurrent |
|------------------|---------------|
| 1-5 | 2 |
| 6-10 | 3 |
| 11-20 | 5 |
| 21+ | 10 |

## Essential Skills

- **Core**: `google-search`, `summarizer`, `code-gen`
- **Dev workflow**: `code-review`, `debugger`, `refactor`, `doc-gen`
- **Content workflow**: `writer`, `brainstorm`, `translator`

## Maintenance Cadence

- **Daily**: Check error logs, disk space
- **Weekly**: Skill updates, session stats
- **Monthly**: Full diagnostic, config review
- **Quarterly**: Major upgrades, workspace cleanup

## Security Best Practices

- **Credentials**: Use env var references, never plaintext in config
- **File Permissions**: Config/key files `0600`, log files `0640`, scripts `0755`
- **Network**: Gateway `bind: "loopback"` for local use, enable auth for lan/tailnet
- **Dependencies**: Weekly `clawhub update --all`, monthly `npm audit`
- **Logs**: Enable rotation, never log credentials
