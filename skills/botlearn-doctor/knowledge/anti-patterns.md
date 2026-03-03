---
domain: botlearn-doctor
topic: anti-patterns
priority: high
ttl: 30d
---

# Common Anti-Patterns

## Configuration

1. **Hardcoded paths** — Use `$OPENCLAW_HOME` instead of absolute paths
2. **Excessive timeouts** (>60s) — Hides performance issues; use 30s default
3. **Disabled logging** — Always keep at least `warn` level in production
4. **Excessive maxConcurrent** (>10) — Causes resource exhaustion; cap at 10 (agents.defaults.maxConcurrent)

## Skill Management

5. **Unused skills installed** — 0 sessions in >30 days → uninstall to save resources
6. **Ignoring dependencies** — Always use `clawhub install` for dependency resolution
7. **Mixed major versions** — One version per skill; uninstall duplicates
8. **Pinning all versions** — Use `^` ranges to receive patch/security updates

## Memory & Logging

9. **Infinite TTL documents** — Set appropriate TTL (30d default); avoid memory bloat
10. **Sensitive data in logs** — Redact tokens/keys before logging
11. **No log rotation** — Enable rotation (max 100MB/file, 10 files); prevent disk exhaustion
12. **Verbose production logs** — Debug level in production causes log bloat (>100MB/day)

## Security Anti-Patterns

13. **Plaintext credentials in config** — Store API keys, tokens, passwords as `${ENV_VAR}` references, never as literal strings in JSON configs
14. **World-readable sensitive files** — Config and key files must be 0600, not 0644; check `umask` settings
15. **Ignoring npm audit warnings** — Critical CVEs in dependencies enable known exploits; run `npm audit` monthly
16. **Gateway bind=lan without auth** — Exposes API to local network without authentication; use `loopback` bind or enable `token`/`password` auth
17. **Control UI on non-loopback** — `/openclaw` control UI accessible from network; disable `controlUI` or restrict bind
18. **No .gitignore for secrets** — `.env`, `*.key`, `*.pem`, credential files must be in `.gitignore`
19. **Secrets tracked in git** — Even after deletion from tree, secrets remain in git history; rotate exposed credentials
20. **No auth on tailnet bind** — If Gateway is accessible via tailnet, always enable token or password auth
21. **No credential rotation** — Static credentials increase exposure risk; rotate quarterly at minimum

## Red Flags (Investigate Immediately)

| Signal | Likely Cause |
|--------|--------------|
| Startup > 30s | Config or dependency issue |
| Memory > 80% | Leak or over-allocation |
| Error rate > 5% | Systemic failure |
| Disk < 10% | Capacity exhaustion |
| Repeated skill failures | Version incompatibility |
| Credentials in logs | Missing redaction filter |
| World-readable key files | Deployment script issue |
| OOM/SIGKILL in logs | Memory leak or insufficient heap |
| Error spike (>3× average) | External service outage or bad deploy |
| Tracked secrets in git | Immediate credential rotation needed |
