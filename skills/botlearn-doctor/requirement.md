---
name: botlearn-doctor
type: requirement
version: 3.0.0
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
| Node.js | >= 18.0.0 | `node --version` | Script execution (score-calculator, report generation) |
| curl | any | `curl --version` | Gateway health probing, webhook delivery |
| bash | >= 4.0 | `bash --version` | Data collection scripts |

## Optional Dependencies

| Dependency | Check Command | Purpose |
|------------|---------------|---------|
| jq | `jq --version` | Enhanced JSON processing (fallback: Node.js) |
| sendmail | `which sendmail` | Email report delivery |
| git | `git --version` | VCS security audit (`.gitignore`, tracked secrets) |

## OpenClaw Platform

| Dependency | Minimum Version | Check Command | Purpose |
|------------|----------------|---------------|---------|
| OpenClaw Agent | >= 0.5.0 | `openclaw --version` | Target platform |
| clawhub CLI | >= 0.3.0 | `clawhub --version` | Skills management queries |
| OpenClaw Gateway | v2026.3.1+ | `curl localhost:18789/openclaw` | Gateway status probing |

**Note**: `clawhub` or `openclaw` CLI — at least one must be available (`anyBins` requirement).

## Environment Variables

| Variable | Required | Default | Purpose |
|----------|----------|---------|---------|
| `OPENCLAW_HOME` | No | `~/.openclaw` | OpenClaw installation root |
| `OPENCLAW_CONFIG_PATH` | No | `$OPENCLAW_HOME/openclaw.json` | Config file path (JSON5) |
| `OPENCLAW_STATE_DIR` | No | `$OPENCLAW_HOME/state` | State directory |
| `OPENCLAW_LOG_DIR` | No | `$OPENCLAW_HOME/logs` | Log directory |
| `OPENCLAW_SKILLS_DIR` | No | `$OPENCLAW_HOME/skills` | Skills directory |

## Filesystem Permissions

- **Read** access to `$OPENCLAW_HOME/` (config, logs, skills directories)
- **Execute** access for `scripts/*.sh` (13 scripts)
- **Write** access to `~/.openclaw/reports/` (for saving reports and snapshots)
- **Write** access to `~/.openclaw/config/` (for channel configuration)

### Security-Specific Permissions

- `collect-security.sh` requires **read** access to config and log files for credential scanning
- `collect-security.sh` does NOT output actual credential values — only type + location
- `snapshot-manager.sh` creates directories with mode `0700` and files with mode `0600`
- Channel config file (`doctor-channels.json`) should be mode `0600` (contains webhook URLs)

## Network

- Local access to OpenClaw Gateway (default `localhost:18789`) for status probing
- No external network access required for core diagnostics
- **Optional**: Outbound HTTPS for webhook delivery (Slack, DingTalk, Feishu, Discord)
- **Optional**: SMTP access for email delivery

## Pre-Installation Checklist

The agent should verify before installing:

```
✅ Node.js >= 18 installed
✅ curl available
✅ bash >= 4.0 available
✅ clawhub or openclaw CLI installed
✅ OPENCLAW_HOME directory exists (or can be created)
✅ Read access to OpenClaw config/logs directories
✅ Write access to ~/.openclaw/reports/ (for snapshots)
```

Optional checks:
```
ℹ️ jq installed (enhanced JSON processing)
ℹ️ sendmail available (email delivery)
ℹ️ git available (VCS security audit)
```

IF any required check fails, report the specific missing requirement and suggest installation steps.
