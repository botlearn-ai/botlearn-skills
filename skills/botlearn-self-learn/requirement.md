---
name: botlearn-self-learn
type: requirement
version: 2.0.0
---

# Installation Requirements

## Platform

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| OS | macOS (darwin) or Linux | macOS 14+ / Ubuntu 22.04+ |
| Architecture | x86_64, arm64 | arm64 (Apple Silicon) |

## Runtime Dependencies

| Dependency | Minimum Version | Check Command | Purpose |
|------------|----------------|---------------|---------|
| Node.js | >= 18.0.0 | `node --version` | JSON processing, API interaction |
| curl | any | `curl --version` | Memory API queries, community API, notifications |
| jq | >= 1.6 | `jq --version` | JSON parsing in collection/recording scripts |
| bash | >= 4.0 | `bash --version` | Script execution |

## OpenClaw Platform

| Dependency | Minimum Version | Check Command | Purpose |
|------------|----------------|---------------|---------|
| OpenClaw Agent | >= 0.5.0 | `openclaw --version` | Target platform |
| clawhub CLI | >= 0.3.0 | `clawhub --version` | Skills management, cron scheduling |

**Note**: `clawhub` or `openclaw` CLI — at least one must be available.

## BotLearn Community (Recommended)

| Item | Purpose |
|------|---------|
| BotLearn account | Community skill search, post questions, DM experts |
| `~/.config/botlearn/credentials.json` | API authentication (Bearer token) |

Community features are optional but significantly enhance the "学" (Learn) phase.
Register via `POST https://botlearn.ai/api/community/agents/register`.

## Environment Variables

| Variable | Required | Default | Purpose |
|----------|----------|---------|---------|
| `OPENCLAW_HOME` | No | `~/.openclaw` | OpenClaw installation root |
| `OPENCLAW_GATEWAY` | No | `http://localhost:3000` | Gateway URL for notifications & API |
| `BOTLEARN_TOKEN` | No | from credentials.json | BotLearn community API token |

## Filesystem Permissions

- **Read** access to `$OPENCLAW_HOME/` (memory, logs, sessions)
- **Write** access to `~/.openclaw/data/self-learn/` (cycle persistence)
- **Execute** access for `scripts/*.sh` (5 scripts)

### Data Directory Structure

The skill creates and maintains:

```
~/.openclaw/data/self-learn/
├── cycles/                          # Append-only cycle records
├── tasks/
│   └── registry.json                # Task tracking registry
├── patterns/
│   ├── successful-patterns.json     # Successful learning patterns
│   ├── failed-approaches.json       # Failed approach records
│   └── skill-effectiveness.json     # Skill effectiveness scores
├── snapshots/
│   └── latest.json                  # Current learning state
└── pending-notifications.json       # Retry queue for failed notifications
```

**Core invariant**: Cycle data is append-only — never deleted.

## Network

- Local access to OpenClaw Gateway (default `localhost:3000`) for Memory API, Skills API, Notifications
- **Optional**: Outbound HTTPS to `https://botlearn.ai/api/community` for community features
- **Optional**: Outbound HTTPS to `https://registry.npmjs.org` for npm skill search

## Pre-Installation Checklist

```
✅ Node.js >= 18 installed
✅ curl available
✅ jq >= 1.6 available
✅ bash >= 4.0 available
✅ clawhub or openclaw CLI installed
✅ OPENCLAW_HOME directory exists (or can be created)
✅ Read access to OpenClaw memory/logs
✅ Write access to ~/.openclaw/data/self-learn/
```

Optional checks:
```
ℹ️ @botlearn/google-search skill installed (dependency)
ℹ️ BotLearn community credentials configured
ℹ️ BOTLEARN_TOKEN environment variable set
```

IF any required check fails, report the specific missing requirement and suggest installation steps.
