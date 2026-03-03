---
name: botlearn-reminder
type: requirement
version: 0.1.0
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
| Node.js | >= 18.0.0 | `node --version` | JSON state management in scripts |
| curl | any | `curl --version` | Fetching quickstart pages |
| bash | >= 4.0 | `bash --version` | Running collection scripts |

## Optional Dependencies

| Dependency | Check Command | Purpose |
|------------|---------------|---------|
| jq | `jq --version` | Enhanced JSON inspection (fallback: Node.js) |

## OpenClaw Platform

| Dependency | Minimum Version | Check Command | Purpose |
|------------|----------------|---------------|---------|
| OpenClaw Agent | >= 0.5.0 | `openclaw --version` | Target platform |
| clawhub CLI | >= 0.3.0 | `clawhub --version` | Skill installation |

**Note**: Heartbeat integration requires OpenClaw's periodic task system.

## Environment Variables

| Variable | Required | Default | Purpose |
|----------|----------|---------|---------|
| `OPENCLAW_HOME` | No | `~/.openclaw` | OpenClaw installation root; memory files stored here |

## Filesystem Permissions

- **Read/Write** access to `$OPENCLAW_HOME/memory/` — stores `botlearn-tips.json`
- **Execute** access for `scripts/*.sh` (3 scripts)
- **Read** access to `references/day-content-guide.md` (fallback content)

## Network

- Outbound HTTPS access to `https://botlearn.ai` for fetching quickstart pages
- If network is unavailable, the skill falls back to `references/day-content-guide.md`

## Pre-Installation Checklist

```
✅ Node.js >= 18 installed
✅ curl available
✅ bash >= 4.0 available
✅ clawhub or openclaw CLI installed
✅ OPENCLAW_HOME directory exists (or can be created)
✅ Write access to $OPENCLAW_HOME/memory/
✅ Outbound HTTPS to botlearn.ai (or accept fallback content mode)
```

Optional:
```
ℹ️ jq installed (enhanced JSON inspection)
ℹ️ Agent WebFetch capability (preferred over curl for page fetching)
```

IF any required check fails → report the specific missing dependency. The skill can operate in offline mode using `references/day-content-guide.md` if network is unavailable.
