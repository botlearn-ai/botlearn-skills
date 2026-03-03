---
domain: botlearn-doctor
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
│      Gateway (WS+HTTP, port 18789)            │
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

| Endpoint | Purpose |
|----------|---------|
| `/` | Root — connectivity check |
| `/openclaw` | Control UI — web-based management interface |
| `/hooks` | Hooks API — external integration hooks |

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
| `openclaw.json` | `$OPENCLAW_HOME/openclaw.json` | Main config (JSON5) |
| `skills/` | `$OPENCLAW_HOME/skills/` | Installed skill packages (`@botlearn/*`) |
| `logs/` | `$OPENCLAW_HOME/logs/` | Log files: `openclaw.log`, `error.log` |
| `data/sessions/` | `$OPENCLAW_HOME/data/sessions/` | Active/closed session records |

## Doctor: 10-Dimension Health Model

```
10-Dimension Traffic-Light Health Check:
  ┌──────────────────────────────────────────────────────┐
  │  1. Platform    collect-env.sh      → ✅/⚠️/❌       │
  │  2. Version     collect-env.sh      → ✅/⚠️/❌       │
  │  3. Config      collect-config.sh   → ✅/⚠️/❌       │
  │  4. Logs        collect-logs.sh     → ✅/⚠️/❌       │
  │  5. Precheck    collect-precheck.sh → ✅/⚠️/❌       │
  │  6. Skills      collect-skills.sh   → ✅/⚠️/❌       │
  │  7. Channels    collect-channels.sh → ✅/⚠️/❌       │
  │  8. Agent       collect-config.sh   → ✅/⚠️/❌       │
  │  9. Gateway     collect-health.sh   → ✅/⚠️/❌       │
  │ 10. Tools       collect-tools.sh    → ✅/⚠️/❌       │
  └──────────────────────────────────────────────────────┘
                          ↓
  Overall: any ❌ → ❌ | no ❌ + any ⚠️ → ⚠️ | all ✅ → ✅
```

## Two Operating Modes

1. **Full Health Check** — idempotent, repeatable; data saved in `data/checkups/` by timestamp
2. **Targeted Check + Fix** — single dimension on user request; references fix-playbooks.md

## Skill Installation Flow

```
clawhub install → dependency check → knowledge injection (POST /memory/inject)
  → strategy registration (POST /skills/register) → smoke test (POST /benchmark/run)
  → pass / rollback
```

## Security Architecture

- **Config Security**: Sensitive values use env var references (`${VAR}`), never plaintext
- **File Permissions**: Config and key files restricted to owner (`0600`)
- **Dependency Security**: `npm audit` for CVE detection
- **Network Security**: Gateway should use `bind: "loopback"` for local-only use
- **VCS Security**: `.gitignore` must cover `.env`, `*.key`, `*.pem`, credential files
