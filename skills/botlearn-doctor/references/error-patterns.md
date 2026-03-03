---
domain: botlearn-doctor
topic: error-patterns
priority: medium
ttl: 60d
---

# Error Pattern Library

## Network Errors

### ECONNREFUSED
- **Symptom**: `connect ECONNREFUSED 127.0.0.1:18789`
- **Root Cause**: Gateway service not running or port conflict
- **Diagnosis**: `curl -s localhost:18789/openclaw` → connection refused
- **Fix**:
  1. Check if Gateway process exists: `ps aux | grep openclaw`
  2. Check port conflict: `lsof -i :18789`
  3. Restart Gateway: `openclaw start`
- **Rollback**: N/A (safe operation)

### ETIMEDOUT
- **Symptom**: `connect ETIMEDOUT` on skill execution
- **Root Cause**: Timeout too short for operation, or downstream service slow
- **Diagnosis**: Check `agents.defaults.timeoutSeconds` in `~/.openclaw/openclaw.json`; review agent execution times
- **Fix**:
  1. IF timeout < 300s: Set `agents.defaults.timeoutSeconds: 600` in openclaw.json
  2. IF specific skill: Check skill's external dependencies
  3. IF network: Verify DNS and firewall rules
- **Rollback**: Restore previous `timeoutSeconds` value in openclaw.json

### ENOTFOUND
- **Symptom**: `getaddrinfo ENOTFOUND <hostname>`
- **Root Cause**: DNS resolution failure
- **Diagnosis**: `nslookup <hostname>`, check `/etc/resolv.conf`
- **Fix**: Verify DNS settings, check network connectivity
- **Rollback**: N/A

## Resource Errors

### EMFILE
- **Symptom**: `EMFILE: too many open files`
- **Root Cause**: File descriptor limit reached
- **Diagnosis**: `ulimit -n` (check current limit)
- **Fix**:
  1. Temporary: `ulimit -n 65536`
  2. Permanent (macOS): `sudo launchctl limit maxfiles 65536 200000`
  3. Permanent (Linux): Add `* soft nofile 65536` to `/etc/security/limits.conf`
- **Rollback**: Restore previous ulimit value

### ENOSPC
- **Symptom**: `ENOSPC: no space left on device`
- **Root Cause**: Disk full
- **Diagnosis**: `df -h /`
- **Fix**:
  1. Clean logs: `find $OPENCLAW_LOG_DIR -name '*.log.*' -mtime +30 -delete`
  2. Clean cache: `rm -rf $OPENCLAW_HOME/data/cache/*`
  3. Clean old reports: `find $OPENCLAW_HOME/reports -mtime +90 -delete`
- **Rollback**: Backups should be made before cleanup

### ENOMEM
- **Symptom**: `JavaScript heap out of memory`
- **Root Cause**: Node.js heap limit exceeded
- **Diagnosis**: Check `process.memoryUsage()`, review memory trends
- **Fix**:
  1. Increase heap: Set `NODE_OPTIONS=--max-old-space-size=4096`
  2. Investigate leak: Check for unclosed connections, large caches
  3. Reduce agent concurrency: Lower `agents.defaults.maxConcurrent` in openclaw.json
- **Rollback**: Remove NODE_OPTIONS, restore maxConcurrent

## Skill Errors

### SKILL_NOT_FOUND
- **Symptom**: `Skill @botlearn/<name> not found`
- **Root Cause**: Skill not installed or registry path misconfigured
- **Fix**: `clawhub install @botlearn/<name>`
- **Rollback**: `clawhub uninstall @botlearn/<name>`

### SKILL_TIMEOUT
- **Symptom**: `Execution exceeded timeout`
- **Root Cause**: Skill operation takes longer than configured timeout
- **Fix**:
  1. Check agent timeout: `agents.defaults.timeoutSeconds` in openclaw.json
  2. Increase if needed: Set `timeoutSeconds: 900` in openclaw.json
- **Rollback**: Restore previous timeoutSeconds value

### DEPENDENCY_CONFLICT (ERESOLVE)
- **Symptom**: `Cannot install due to conflicting dependencies`
- **Root Cause**: Two skills require incompatible versions of same dependency
- **Fix**:
  1. Identify conflicts: `clawhub list --check-deps`
  2. Update conflicting skills: `clawhub update @botlearn/<name>`
  3. Force resolution: `clawhub install --force @botlearn/<name>`
- **Rollback**: `clawhub uninstall @botlearn/<name>` and reinstall previous version

## Cascade Failure Patterns

### Pattern: Correlated Timestamps
- **Signal**: Multiple skills fail within seconds of each other
- **Root Cause**: Shared dependency (Gateway, external API, database) down
- **Diagnosis**: Check error timestamps for correlation; check shared services
- **Fix**: Restart shared service first, then re-test individual skills

### Pattern: Memory Growth
- **Signal**: Gradual memory increase over hours/days, eventual crash
- **Root Cause**: Memory leak (unclosed connections, accumulating cache)
- **Diagnosis**: Monitor memory usage over time, check per-skill memory
- **Fix**: Identify leaking skill, restart service, report to skill maintainer

### Pattern: Race Conditions
- **Signal**: Intermittent failures only under high concurrency
- **Root Cause**: Concurrent access to shared resource without locking
- **Diagnosis**: Reduce concurrency to 1, verify issue disappears
- **Fix**: Lower concurrency, report to skill maintainer

### Pattern: Config Drift
- **Signal**: Works on one machine but not another
- **Root Cause**: Environment-specific config not documented
- **Diagnosis**: Compare configs between environments
- **Fix**: Standardize config, use environment variables for differences
