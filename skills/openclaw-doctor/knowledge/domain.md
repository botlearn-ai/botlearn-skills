---
domain: openclaw-doctor
topic: openclaw-architecture
priority: high
ttl: 30d
---

# OpenClaw Architecture

## Core Components

```
┌─────────────── OpenClaw Agent ───────────────┐
│  Skills System ←→ Memory System ←→ Plugins   │
│         ↓              ↓              ↓       │
│              Execution Engine                 │
│                    ↓                          │
│      Gateway (WS+HTTP, port 18789)             │
└───────────────────────────────────────────────┘
       ↓                        ↓
   clawhub CLI              npm registry
```

- **Skills**: Installable capability packages (`@botlearn/*`), trigger-based activation
- **Memory**: Persistent knowledge store, injection via `POST /memory/inject`
- **Plugins**: External integrations (APIs, databases)
- **Execution Engine**: Orchestrates skills, handles concurrency and dependencies
- **Gateway**: WS+HTTP multiplex server (default port 18789)

## Gateway Endpoints

| Endpoint | Purpose | Description |
|----------|---------|-------------|
| `/` | Root | Connectivity check |
| `/openclaw` | Control UI | Web-based management interface |
| `/hooks` | Hooks API | External integration hooks |

## Gateway Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| `gateway.port` | 18789 | WS+HTTP multiplex port |
| `gateway.bind` | `loopback` | Bind mode: loopback / lan / tailnet |
| `gateway.mode` | `ws+http` | Protocol mode |
| `gateway.auth.type` | `none` | Auth: token / password / none |
| `gateway.controlUI` | `true` | Enable /openclaw web UI |
| `gateway.reload` | `hybrid` | Config reload: hybrid / hot / restart / off |

## Key Paths

| Variable | Default | Content |
|----------|---------|---------|
| `OPENCLAW_HOME` | `~/.openclaw` | Installation root |
| `openclaw.json` | Main config (JSON5) | Gateway, agents, messages, session, tools |
| `skills/` | Installed skill packages | `@botlearn/*` |
| `logs/` | Log files | `openclaw.log`, `error.log` |
| `data/sessions/` | Session records | Active/closed sessions |

## Doctor v4.0: 10-Dimension Health Model

```
10 维度红绿灯体检:
  ┌──────────────────────────────────────────────────────┐
  │ 1. 基础平台    collect-env.sh     → ✅/⚠️/❌        │
  │ 2. OpenClaw版本 collect-env.sh     → ✅/⚠️/❌        │
  │ 3. 配置正确性  collect-config.sh  → ✅/⚠️/❌        │
  │ 4. 日志告警    collect-logs.sh    → ✅/⚠️/❌        │
  │ 5. 预检       collect-precheck.sh → ✅/⚠️/❌        │
  │ 6. Skills安装  collect-skills.sh  → ✅/⚠️/❌        │
  │ 7. Channels   collect-channels.sh → ✅/⚠️/❌        │
  │ 8. Agent配置  collect-config.sh  → ✅/⚠️/❌        │
  │ 9. Gateway    collect-health.sh  → ✅/⚠️/❌        │
  │ 10. 内置工具   collect-tools.sh   → ✅/⚠️/❌        │
  └──────────────────────────────────────────────────────┘
                         ↓
  整体状态: 有❌→❌ | 无❌有⚠️→⚠️ | 全✅→✅
```

## 2 Core Functions

1. **智能体检** — 幂等、可反复执行，数据保存在 `data/checkups/` 按时间组织
2. **智能修复** — 基于体检结果的定向修复，引用 fix-playbooks.md

## Skill Installation Flow

```
clawhub install → dependency check → knowledge injection (POST /memory/inject)
  → strategy registration (POST /skills/register) → smoke test (POST /benchmark/run)
  → pass/rollback
```

## Security Architecture

- **Config Security**: Sensitive values should use env var references (`${VAR}`)
- **File Permissions**: Config and key files restricted to owner (0600)
- **Dependency Security**: `npm audit` for CVE detection
- **Network Security**: Gateway should use `bind: "loopback"` for local use
- **VCS Security**: `.gitignore` must cover `.env`, `*.key`, `*.pem`
