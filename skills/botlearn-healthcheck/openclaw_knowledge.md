# OpenClaw Platform Knowledge

> Reference this file during Phase 2 (Domain Analysis), Phase 4 (Report Analysis), and Phase 5 (Fix Cycle).
> Provides platform defaults, version info, and common CLI commands for accurate diagnosis and repair.

---

## Platform Defaults

| Item | Value |
|------|-------|
| Gateway default address | `http://127.0.0.1:18789` |
| Latest stable version | `2026.3.2` |
| Config file | `$OPENCLAW_HOME/openclaw.json` |
| Log directory | `$OPENCLAW_HOME/logs/` |
| Workspace directory | `$OPENCLAW_HOME/workspace/` |
| Skills directory | `$OPENCLAW_HOME/skills/` |
| Memory directory | `$OPENCLAW_HOME/memory/` |
| Cron directory | `$OPENCLAW_HOME/cron/` |
| Identity directory | `$OPENCLAW_HOME/identity/` |

---

## Common CLI Commands

### Status & Diagnostics

```bash
# Full system status with deep inspection
openclaw status --deep

# Gateway & service health check (structured JSON output)
openclaw health --json

# View recent logs
openclaw logs

# Read-only deep diagnostic (no modifications)
openclaw doctor --deep --non-interactive

# Repair mode: auto-fix issues, suppress workspace suggestions
openclaw doctor --repair --fix --no-workspace-suggestions
```

### Configuration

```bash
# Validate config syntax and structure
openclaw config validate

# Set a config value
openclaw config set <key> <value>

# Example: set gateway bind address
openclaw config set gateway.bind "127.0.0.1"
```

### Service Management

```bash
# Start the agent
openclaw start

# Stop the agent
openclaw stop

# Restart (stop + start)
openclaw restart
```

### Skills Management

```bash
# List installed skills with status
openclaw skills list --status

# Check a specific skill's health
openclaw skills check <skill-name>

# Install a skill via clawhub
clawhub install @scope/skill-name --force
```

### Workspace & Identity

```bash
# Check workspace file status
openclaw workspace status

# Initialize workspace identity files
openclaw workspace init --file <agent|user|soul|tool|identity>
```

### Session Configuration

```bash
# Session config is set in openclaw.json under the "session" key.
# Key fields:

# dmScope — how DMs are grouped:
#   main: all DMs share the main session
#   per-peer: isolate by sender id across channels
#   per-channel-peer: isolate per channel + sender (recommended for multi-user)
#   per-account-channel-peer: isolate per account + channel + sender (recommended for multi-account)

# reset — primary reset policy:
#   mode: "daily" resets at atHour local time; "idle" resets after idleMinutes
#   When both configured, whichever expires first wins

# resetByType — per-type overrides (direct, group, thread)

# parentForkMaxTokens — max parent-session totalTokens when forking thread session (default 100000)
#   If parent totalTokens exceeds this, starts a fresh thread session instead

# maintenance — session-store cleanup:
#   mode: "warn" (logs only) or "enforce" (applies cleanup)
#   pruneAfter: age cutoff for stale entries (default 30d)
#   maxEntries: max entries in sessions.json (default 500)
#   rotateBytes: rotate sessions.json when exceeding this size (default 10mb)
#   maxDiskBytes: optional sessions-directory disk budget
#   highWaterBytes: target after budget cleanup (default 80% of maxDiskBytes)

# threadBindings — thread-bound session features:
#   enabled: master switch
#   idleHours: inactivity auto-unfocus (0 disables)
#   maxAgeHours: hard max age (0 disables)
```

### Rate Limit & Model Config

```bash
# Set request throttle (interval in ms, max requests per interval)
openclaw config set models.rateLimit.interval 1000
openclaw config set models.rateLimit.maxRequests 10

# Check for recent 429 errors
openclaw logs | grep -i "429\|rate.limit" | tail -10
```

Multi-key rotation requires editing `openclaw.json` directly — set `models.providers.<provider>.apiKeys` array and `rotateKeys: true`.

### Cache Management

```bash
# View cache statistics
openclaw cache stats

# Clear specific caches
openclaw cache clear --history
openclaw cache clear --index

# Clear all caches
openclaw cache clear --all

# Set cache limits (recommended)
openclaw config set cache.maxHistory 100
openclaw config set cache.maxIndexSize 1
```

### Cron Tasks

```bash
# List scheduled tasks
openclaw cron list

# Reload cron definitions after changes
openclaw cron reload
```

### Channel Management

```bash
# Quick probe all channel connectivity status
openclaw channels status --probe

# Reconnect a channel
openclaw channel reconnect <channel-name>
```

---

## Version History & Breaking Changes

| Version | Date | Key Changes |
|---------|------|-------------|
| 2026.3.2 | 2026-03-02 | Latest stable. `tools` config required: `profile: "full"`, `sessions.visibility: "all"`. Without this, underlying tools degrade to minimal mode (see `fix_cases.md` Case 2.4). |

---

## Diagnostic Cheat Sheet

Use these commands in sequence for a rapid health assessment:

```bash
# Step 1: Quick status overview
openclaw status --deep

# Step 2: Gateway & service health (structured JSON)
openclaw health --json

# Step 3: Read-only deep diagnostic
openclaw doctor --deep --non-interactive

# Step 4: Check logs for recent errors
openclaw logs

# Step 5: Validate config
openclaw config validate

# Step 6: If issues found, auto-repair
openclaw doctor --repair --fix --no-workspace-suggestions
```

---

## Gateway Health Check

The gateway listens at `http://127.0.0.1:18789` by default.

```bash
# Preferred: use built-in health command (structured JSON output)
openclaw health --json

# Check which process holds the gateway port
lsof -i :18789
```

Always use `openclaw health --json` instead of directly calling the HTTP API.
The JSON output includes gateway reachability, endpoint latency, and service status in a structured format.
