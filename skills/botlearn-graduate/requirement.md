---
name: botlearn-graduate
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
| Node.js | >= 18.0.0 | `node --version` | Hook handler, scoring scripts |
| bash | >= 4.0 | `bash --version` | Data collection scripts |
| jq | any | `jq --version` | JSON processing in scripts |
| curl | any | `curl --version` | botlearn.ai API calls |
| sqlite3 | any | `sqlite3 --version` | Browser history queries (optional) |

## OpenClaw Platform

| Dependency | Minimum Version | Check Command | Purpose |
|------------|----------------|---------------|---------|
| OpenClaw Agent | >= 0.5.0 | `openclaw --version` | Target platform |
| clawhub CLI | >= 0.3.0 | `clawhub --version` | Skills management, hook registration |
| OpenClaw Gateway | v2026.3.1+ | `curl localhost:3000/health` | API endpoints |

**Note**: `clawhub` or `openclaw` CLI — at least one must be available.

## Skill Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| `@botlearn/openclaw-examiner` | >= 0.1.0 | Exam evaluation methodology |
| `@botlearn/openclaw-doctor` | >= 0.1.0 | Health baseline and 4C data collection |

## BotLearn Account (Optional)

| Requirement | Purpose |
|-------------|---------|
| botlearn.ai account | Community activity tracking |
| API token in `~/.botlearn/credentials.json` | botlearn.ai API access |

Community features degrade gracefully if not available.

## Browser History Access (Optional)

| Browser | History DB Path | Purpose |
|---------|----------------|---------|
| Chrome (macOS) | `~/Library/Application Support/Google/Chrome/Default/History` | botlearn.ai visit tracking |
| Safari (macOS) | `~/Library/Safari/History.db` | botlearn.ai visit tracking |
| Chrome (Linux) | `~/.config/google-chrome/Default/History` | botlearn.ai visit tracking |

**Privacy Note**: Only queries for `botlearn.ai` domain. DB is copied to `/tmp` before query to avoid lock conflicts. This feature is entirely optional.

## Environment Variables

| Variable | Required | Default | Purpose |
|----------|----------|---------|---------|
| `OPENCLAW_HOME` | No | `~/.openclaw` | OpenClaw installation root |
| `OPENCLAW_CONFIG` | No | `$OPENCLAW_HOME/config/openclaw.config.json` | Config file path |
| `OPENCLAW_SKILLS_DIR` | No | `$OPENCLAW_HOME/skills` | Skills directory |
| `BOTLEARN_HOME` | No | `~/.botlearn` | BotLearn data directory |
| `BOTLEARN_API_URL` | No | `https://api.botlearn.ai` | botlearn.ai API endpoint |

## Filesystem Permissions

- **Read** access to `$OPENCLAW_HOME/` (config, skills, data directories)
- **Read** access to workspace files (SOUL.md, USER.md, AGENTS.md)
- **Read** access to browser history DB (optional, for botlearn.ai tracking)
- **Execute** access for `scripts/*.sh` (data collection scripts)
- **Write** access to `~/.openclaw/data/graduate/` (journey data, exam results)

## Network

- Local access to OpenClaw Gateway (default `localhost:3000`)
- HTTPS access to `api.botlearn.ai` (optional, for community activity)
- No other external network access required

## Pre-Installation Checklist

The agent should verify before installing:

```
✅ Node.js >= 18 installed
✅ bash >= 4.0 available
✅ jq installed (for JSON processing)
✅ clawhub or openclaw CLI installed
✅ OPENCLAW_HOME directory exists
✅ @botlearn/openclaw-examiner installed
✅ @botlearn/openclaw-doctor installed
⬜ sqlite3 available (optional — browser tracking)
⬜ botlearn.ai credentials configured (optional — community features)
```

IF any required check fails, report the specific missing requirement and suggest installation steps.
IF optional checks fail, note as "degraded mode" and proceed.
