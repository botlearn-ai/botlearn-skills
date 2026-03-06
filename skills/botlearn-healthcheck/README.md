# @botlearn/botlearn-healthcheck

OpenClaw Autonomous Health Inspector — collects system data across 5 domains, produces traffic-light reports with scores and fix guidance, and walks the user through repairs.

## How It Works

The health check runs a 6-phase pipeline, fully autonomous:

```
Phase 0: Detect language + operating mode (full check or targeted domain)

Phase 1: Data Collection
    → Run 11 collection scripts in parallel
    → Read 10 config/state files directly
    → Store all data as DATA.* context keys
    → Any failure sets DATA.<key> = null, never aborts

Phase 2: Domain Analysis
    → Analyze 5 health domains (all in parallel for full check)
    → Each domain: base score 100, subtract per-check failures
    → Produce: status + score (0-100) + findings + fix hints

Phase 3: Report Generation
    → Save MD + HTML reports to $OPENCLAW_HOME/memory/health-reports/

Phase 4: Report Analysis
    → Present layered output: one-line status → domain grid → issues → deep analysis
    → Compare with historical reports for trend tracking

Phase 5: Fix Cycle
    → Show fix command + rollback → await user confirmation → execute → verify
    → Never modify system state without explicit confirmation

Phase 6: Fix Summary
    → Actions taken, score changes, remaining issues
```

## 5 Health Domains

| # | Domain | Score Thresholds | What It Checks |
|---|--------|-----------------|---------------|
| 1 | Hardware Resources | ≥80 / 60-79 / <60 | Memory, disk, CPU, Node.js version, cache pressure |
| 2 | Configuration Health | ≥75 / 55-74 / <55 | Config validation, gateway, agents, channels, tools, models, session, security posture |
| 3 | Security Risks | ≥85 / 65-84 / <65 | Credential exposure, file permissions, network bind, VCS secrets |
| 4 | Skills Completeness | ≥80 / 60-79 / <60 | Built-in tools, install capability, skill health, botlearn ecosystem |
| 5 | Autonomous Intelligence | ≥80 / 60-79 / <60 | Heartbeat, cron tasks, memory, doctor output, workspace identity |

## Use Cases

| Scenario | Mode | What Happens |
|----------|------|-------------|
| "health check" / "doctor" | Full Check | All 5 domains analyzed in parallel |
| "check security" / "fix skills" | Targeted | Only the named domain |
| Periodic heartbeat | Full Check | Scheduled automatic inspection |
| After config changes | Targeted | Verify specific domain after modification |

## Fix Cases Knowledge Base

Includes 19 real-world fix cases with proven solutions:

- **Hardware**: Memory pressure, disk critical, Node.js outdated, cache bloat
- **Configuration**: Validation failures, gateway unreachable, channel inactive, tools degraded, API rate limiting (429), model context window too small, fallbacks not configured, concurrency tuning, session optimization
- **Security**: Credentials exposed, files world-readable, LAN without auth
- **Skills**: Broken dependencies, no botlearn skills, missing SKILL.md
- **Autonomy**: Heartbeat stale, no cron tasks, memory bloat, identity missing, OOM/segfault

Each case includes: applicable version, symptom, root cause, diagnosis, fix steps, rollback, and prevention.

## Key Constraints

1. **Scripts First** — Use collection scripts for structured data; read files directly for raw content
2. **Evidence-Based** — Every finding cites the specific `DATA.<key>.<field>` and its actual value
3. **Privacy Guard** — Redact all API keys, tokens, and passwords before output
4. **Safety Gate** — Show fix plan and await confirmation before any system modification
5. **Language Rule** — All output in the user's native language; commands and field names in English

## Triggers

```
health check / diagnose / doctor / check system / system status
troubleshoot / what's wrong / fix my setup
check gateway / check skills / check config / check security / check autonomy / check hardware
体检 / 修复 / 诊断
```

## File Structure

```
botlearn-healthcheck/
├── SKILL.md                       # Entry point: 6-phase pipeline
├── setup.md                       # First-run prerequisites
├── data_collect.md                # Data collection protocol (20 data sources)
├── check_hardware.md              # Domain 1 scoring rules
├── check_config.md                # Domain 2 scoring rules
├── check_security.md              # Domain 3 scoring rules
├── check_skills.md                # Domain 4 scoring rules
├── check_autonomy.md              # Domain 5 scoring rules
├── fix_cases.md                   # 19 real-world fix cases with solutions
├── openclaw_knowledge.md          # Platform defaults, CLI commands, version info
├── flow_report.md                 # Phase 3: report generation
├── flow_analysis.md               # Phase 4: report analysis + trends
├── flow_fix.md                    # Phase 5: fix cycle protocol
├── flow_summary.md                # Phase 6: fix summary
└── scripts/
    ├── collect-status.sh          # Instance status collection
    ├── collect-env.sh             # OS/hardware metrics
    ├── collect-config.sh          # Config validation
    ├── collect-logs.sh            # Log analysis
    ├── collect-skills.sh          # Skills inventory
    ├── collect-health.sh          # Gateway health (fallback)
    ├── collect-precheck.sh        # openclaw doctor output
    ├── collect-channels.sh        # Channel status
    ├── collect-tools.sh           # Tool availability
    ├── collect-security.sh        # Security scan
    └── collect-workspace-audit.sh # Workspace audit
```

## Install

```bash
clawhub install @botlearn/botlearn-healthcheck --force
```

## Version

Current: 0.1.5

## License

MIT
