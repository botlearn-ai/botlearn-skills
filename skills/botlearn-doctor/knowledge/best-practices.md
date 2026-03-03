---
domain: botlearn-doctor
topic: best-practices
priority: high
ttl: 30d
---

# Health Check Best Practices

## 10-Dimension Traffic-Light Thresholds

### Dimension 1: Platform

| Metric | ✅ pass | ⚠️ warning | ❌ error |
|--------|---------|-----------|---------|
| Node.js | v20+ LTS | v18.x | < v18 |
| Memory available | > 30% | 15–30% | < 15% |
| Disk available | > 20% | 10–20% | < 10% |
| CPU load/core | < 0.7 | 0.7–0.9 | > 0.9 |

### Dimension 2: Version

| Metric | ✅ pass | ⚠️ warning | ❌ error |
|--------|---------|-----------|---------|
| openclaw CLI | Latest | Older but usable | Not installed |
| clawhub CLI | Latest | Older but usable | Neither CLI found |
| Node.js | v20+ LTS | v18.x | < v18 |

### Dimension 3: Config

| Metric | ✅ pass | ⚠️ warning | ❌ error |
|--------|---------|-----------|---------|
| Config file | Exists | — | Missing |
| JSON validity | Valid | — | Parse failure |
| Required sections | All 5 present | Optional missing | gateway/agents missing |

### Dimension 4: Logs

| Metric | ✅ pass | ⚠️ warning | ❌ error |
|--------|---------|-----------|---------|
| Error rate | < 1% | 1–10% | > 10% |
| OOM/segfault | None | — | Detected |
| Error spikes | None | Detected | — |
| Log size | < 500 MB | — | > 500 MB |

### Dimension 5: Precheck

| Metric | ✅ pass | ⚠️ warning | ❌ error |
|--------|---------|-----------|---------|
| openclaw doctor | All pass | Has warnings | Has errors |

### Dimension 6: Skills

| Metric | ✅ pass | ⚠️ warning | ❌ error |
|--------|---------|-----------|---------|
| Installed count | ≥ 3 | 1–2 | 0 |
| Dependencies | All intact | Has outdated | Broken deps |
| File integrity | Complete | Missing optional | Missing required |

### Dimension 7: Channels

| Metric | ✅ pass | ⚠️ warning | ❌ error |
|--------|---------|-----------|---------|
| Channel config | Valid + enabled | All disabled | Missing/corrupt |

### Dimension 8: Agent

| Metric | ✅ pass | ⚠️ warning | ❌ error |
|--------|---------|-----------|---------|
| maxConcurrent | 1–10 | 11–20 | > 20 |
| timeoutSeconds | 30–1800 s | 1801–3600 s | > 3600 s |
| heartbeat | 5–120 min | Outside range | — |

### Dimension 9: Gateway

| Metric | ✅ pass | ⚠️ warning | ❌ error |
|--------|---------|-----------|---------|
| Root endpoint | Reachable | — | Unreachable |
| /openclaw | Responsive | — | Not responsive |
| Latency | < 500 ms | > 500 ms | — |

### Dimension 10: Tools

| Metric | ✅ pass | ⚠️ warning | ❌ error |
|--------|---------|-----------|---------|
| Core CLI tools | All available | — | Missing |
| Core MCP tools | All available | — | Missing |
| Optional tools | All available | Some missing | — |

## Configuration Guidelines

| Setting | Recommended | Range |
|---------|-------------|-------|
| `agents.defaults.maxConcurrent` | Based on skill count | 1–10 |
| `agents.defaults.timeoutSeconds` | 600 s | 30–1800 s |
| `agents.heartbeat.intervalMinutes` | 30 | 5–120 |

### maxConcurrent by Workload

| Skills Installed | maxConcurrent |
|-----------------|---------------|
| 1–5 | 2 |
| 6–10 | 3 |
| 11–20 | 5 |
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
